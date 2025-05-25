#!/bin/bash
# start-hbase.sh - HBase集群启动脚本
# 优化版本：提供更好的用户体验

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 配置变量
MASTER_CONTAINER="hadoop-master1"
HBASE_BIN="/opt/hbase/bin"
HADOOP_BIN="/opt/hadoop/bin"
HBASE_DIR="/hbase"
STARTUP_TIMEOUT=120
HEALTH_CHECK_RETRIES=5

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印成功消息
print_success() {
    print_message $GREEN "✓ $1"
}

# 打印警告消息
print_warning() {
    print_message $YELLOW "⚠ $1"
}

# 打印错误消息
print_error() {
    print_message $RED "✗ $1"
}

# 打印信息消息
print_info() {
    print_message $BLUE "ℹ $1"
}

# 打印步骤标题
print_step() {
    print_message $PURPLE "${BOLD}=== $1 ===${NC}"
}

# 显示启动动画
show_progress() {
    local duration=$1
    local description=$2
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    local i=0
    
    while [ $i -lt $duration ]; do
        for (( j=0; j<${#chars}; j++ )); do
            printf "\r${BLUE}${chars:$j:1} $description... ${CYAN}(%ds)${NC}" $((duration - i))
            sleep $delay
            i=$((i + 1))
            if [ $i -ge $duration ]; then
                break
            fi
        done
    done
    printf "\r${GREEN}✓ $description 完成${NC}\n"
}

# 检查Docker容器状态
check_container() {
    print_step "检查Docker容器状态"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装或不在PATH中"
        return 1
    fi
    
    if ! docker ps | grep -q "$MASTER_CONTAINER"; then
        print_error "容器 '$MASTER_CONTAINER' 未运行"
        print_info "请先启动Hadoop集群容器"
        return 1
    fi
    
    print_success "容器 '$MASTER_CONTAINER' 正在运行"
    return 0
}

# 检查Hadoop集群状态
check_hadoop_cluster() {
    print_step "检查Hadoop集群状态"
    
    # 检查HDFS是否可访问
    print_info "检查HDFS服务..."
    if ! docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfs -ls / &>/dev/null; then
        print_error "HDFS服务不可用"
        print_info "请先启动Hadoop集群"
        return 1
    fi
    print_success "HDFS服务正常"
    
    # 检查HDFS安全模式
    print_info "检查HDFS安全模式..."
    local safemode_status=$(docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfsadmin -safemode get 2>/dev/null)
    
    if echo "$safemode_status" | grep -q "ON"; then
        print_warning "HDFS处于安全模式，等待退出..."
        show_progress 10 "等待HDFS退出安全模式"
        
        # 尝试等待安全模式自动退出
        if docker exec "$MASTER_CONTAINER" timeout 60 "$HADOOP_BIN/hdfs" dfsadmin -safemode wait; then
            print_success "HDFS已退出安全模式"
        else
            print_warning "HDFS安全模式等待超时，尝试强制退出"
            docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfsadmin -safemode leave
        fi
    else
        print_success "HDFS不在安全模式"
    fi
    
    return 0
}

# 检查HBase目录
check_hbase_directory() {
    print_step "检查HBase HDFS目录"
    
    if docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfs -test -d "$HBASE_DIR" 2>/dev/null; then
        print_success "HBase目录 '$HBASE_DIR' 存在"
        
        # 显示目录权限
        local permissions=$(docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfs -ls / 2>/dev/null | grep "hbase" | awk '{print $1}')
        if [[ -n "$permissions" ]]; then
            print_info "目录权限: $permissions"
        fi
    else
        print_warning "HBase目录 '$HBASE_DIR' 不存在"
        print_info "建议先运行 hbase-init.sh 初始化HBase目录"
        
        print_message $YELLOW "是否自动创建HBase目录？[y/N]"
        read -t 10 -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "正在创建HBase目录..."
            if docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfs -mkdir -p "$HBASE_DIR" && \
               docker exec "$MASTER_CONTAINER" "$HADOOP_BIN/hdfs" dfs -chmod 755 "$HBASE_DIR"; then
                print_success "HBase目录创建成功"
            else
                print_error "HBase目录创建失败"
                return 1
            fi
        fi
    fi
    
    return 0
}

# 启动HBase集群
start_hbase_cluster() {
    print_step "启动HBase集群"
    
    print_info "正在启动HBase服务..."
    
    if docker exec "$MASTER_CONTAINER" "$HBASE_BIN/start-hbase.sh"; then
        print_success "HBase启动命令执行成功"
    else
        print_error "HBase启动失败"
        return 1
    fi
    
    # 等待HBase服务启动
    show_progress 30 "等待HBase服务完全启动"
    
    return 0
}

# 健康检查
health_check() {
    print_step "HBase服务健康检查"
    
    local retry_count=0
    local max_retries=$HEALTH_CHECK_RETRIES
    
    while [ $retry_count -lt $max_retries ]; do
        print_info "健康检查 ($((retry_count + 1))/$max_retries)..."
        
        # 检查HBase状态
        if check_hbase_status; then
            print_success "HBase服务健康检查通过"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "健康检查失败，等待重试..."
                sleep 10
            fi
        fi
    done
    
    print_error "HBase服务健康检查失败，已重试 $max_retries 次"
    return 1
}

# 检查HBase状态
check_hbase_status() {
    # 尝试连接HBase shell并获取状态
    local status_output
    if status_output=$(docker exec "$MASTER_CONTAINER" bash -c "echo 'status' | $HBASE_BIN/hbase shell 2>/dev/null | tail -10"); then
        if echo "$status_output" | grep -q "servers"; then
            return 0
        fi
    fi
    return 1
}

# 显示HBase详细状态
show_hbase_status() {
    print_step "HBase集群状态详情"
    
    echo
    print_message $CYAN "HBase集群状态:"
    docker exec "$MASTER_CONTAINER" bash -c "echo 'status \"detailed\"' | $HBASE_BIN/hbase shell 2>/dev/null" || print_warning "无法获取详细状态"
    
    echo
    print_message $CYAN "HBase版本信息:"
    docker exec "$MASTER_CONTAINER" bash -c "echo 'version' | $HBASE_BIN/hbase shell 2>/dev/null" || print_warning "无法获取版本信息"
}

# 显示连接信息
show_connection_info() {
    print_step "连接信息"
    
    echo
    print_message $CYAN "HBase Web访问地址:"
    echo "  - HBase Master: http://hadoop-master1:16010"
    echo "  - HBase Region Server: http://hadoop-master2:16030"
    
    echo
    print_message $CYAN "HBase Shell连接命令:"
    echo "  docker exec -it $MASTER_CONTAINER $HBASE_BIN/hbase shell"
    
    echo
    print_message $CYAN "HBase配置信息:"
    echo "  - ZooKeeper端口: 2181"
    echo "  - Master端口: 16000"
    echo "  - Region Server端口: 16020"
}

# 测试HBase基本功能
test_hbase_functionality() {
    print_info "测试HBase基本功能..."
    
    local test_table="test_table_$(date +%s)"
    local test_commands="
create '$test_table', 'cf'
put '$test_table', 'row1', 'cf:col1', 'value1'
get '$test_table', 'row1'
scan '$test_table'
disable '$test_table'
drop '$test_table'
"
    
    if docker exec "$MASTER_CONTAINER" bash -c "echo \"$test_commands\" | $HBASE_BIN/hbase shell 2>/dev/null" >/dev/null; then
        print_success "HBase基本功能测试通过"
        return 0
    else
        print_warning "HBase基本功能测试失败"
        return 1
    fi
}

# 显示启动摘要
show_startup_summary() {
    local start_time=$1
    local end_time=$2
    local duration=$((end_time - start_time))
    
    print_step "启动摘要"
    
    print_message $GREEN "=========================================="
    print_message $GREEN "       HBase集群启动完成！"
    print_message $GREEN "=========================================="
    echo
    print_success "启动耗时: ${duration}秒"
    print_success "主容器: $MASTER_CONTAINER"
    print_success "HBase目录: $HBASE_DIR"
}

# 主函数
main() {
    local start_time=$(date +%s)
    
    # 显示标题
    echo
    print_message $PURPLE "${BOLD}========================================"
    print_message $PURPLE "${BOLD}    HBase集群启动脚本 (优化版)"
    print_message $PURPLE "${BOLD}========================================"
    echo
    
    # 显示配置信息
    print_message $CYAN "配置信息:"
    echo "  - 主容器: $MASTER_CONTAINER"
    echo "  - HBase目录: $HBASE_DIR"
    echo "  - 启动超时: ${STARTUP_TIMEOUT}秒"
    echo "  - 健康检查重试: ${HEALTH_CHECK_RETRIES}次"
    echo
    
    # 执行启动步骤
    local steps=(
        "check_container:检查容器状态"
        "check_hadoop_cluster:检查Hadoop集群"
        "check_hbase_directory:检查HBase目录"
        "start_hbase_cluster:启动HBase集群"
        "health_check:健康检查"
    )
    
    local total_steps=${#steps[@]}
    local current_step=0
    local failed_steps=()
    
    for step_info in "${steps[@]}"; do
        current_step=$((current_step + 1))
        local func_name="${step_info%%:*}"
        local description="${step_info##*:}"
        
        print_message $BLUE "[$current_step/$total_steps] $description"
        echo
        
        if ! $func_name; then
            failed_steps+=("$description")
            print_error "步骤失败: $description"
            
            # 对于关键步骤失败，询问是否继续
            if [[ "$func_name" == "check_container" || "$func_name" == "check_hadoop_cluster" ]]; then
                print_message $YELLOW "关键步骤失败，是否继续？[y/N]"
                read -t 10 -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_error "用户选择退出"
                    exit 1
                fi
            fi
        fi
        echo
    done
    
    local end_time=$(date +%s)
    
    # 显示启动结果
    if [ ${#failed_steps[@]} -eq 0 ]; then
        show_startup_summary $start_time $end_time
    else
        print_message $YELLOW "========================================"
        print_message $YELLOW "    HBase集群启动完成（有警告）"
        print_message $YELLOW "========================================"
        echo
        print_warning "以下步骤执行失败或有警告:"
        for failed_step in "${failed_steps[@]}"; do
            print_error "- $failed_step"
        done
        echo
        print_info "启动耗时: $((end_time - start_time))秒"
    fi
    
    # 显示连接信息
    show_connection_info
    
    # 询问可选操作
    echo
    print_info "可选操作:"
    print_message $YELLOW "1. 显示详细状态 [1]"
    print_message $YELLOW "2. 测试基本功能 [2]"
    print_message $YELLOW "3. 跳过 [任意键]"
    read -t 10 -n 1 -r
    echo
    
    case $REPLY in
        1)
            show_hbase_status
            ;;
        2)
            test_hbase_functionality
            ;;
        *)
            print_info "跳过可选操作"
            ;;
    esac
    
    echo
    print_message $CYAN "提示: HBase集群现在可以接受连接和表操作"
    print_message $CYAN "使用 'docker exec -it $MASTER_CONTAINER $HBASE_BIN/hbase shell' 连接到HBase Shell"
}

# 错误处理
set -e
trap 'print_error "脚本执行过程中发生错误，位置: $BASH_COMMAND"' ERR

# 允许脚本在某些命令失败时继续运行
set +e

# 运行主函数
main "$@"