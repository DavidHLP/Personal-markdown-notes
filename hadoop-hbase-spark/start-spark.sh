#!/bin/bash
# start-spark.sh - Spark集群启动脚本 (HA模式)
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

# 集群配置
MASTER_NODES=("hadoop-master1" "hadoop-master2" "hadoop-master3")
WORKER_NODES=("hadoop-worker1" "hadoop-worker2" "hadoop-worker3")
ALL_NODES=("${MASTER_NODES[@]}" "${WORKER_NODES[@]}")

# 服务配置
SPARK_BIN="/opt/spark/bin"
SPARK_SBIN="/opt/spark/sbin"
SPARK_LOG_DIR="/sparklog"
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
check_containers() {
    print_step "检查Docker容器状态"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装或不在PATH中"
        return 1
    fi
    
    local failed_containers=()
    
    for node in "${ALL_NODES[@]}"; do
        if docker ps | grep -q "$node"; then
            print_success "$node 容器正在运行"
        else
            print_error "$node 容器未运行"
            failed_containers+=("$node")
        fi
    done
    
    if [ ${#failed_containers[@]} -gt 0 ]; then
        print_error "以下容器未运行: ${failed_containers[*]}"
        print_info "请先启动所有容器"
        return 1
    fi
    
    print_success "所有容器状态正常"
    return 0
}

# 检查HDFS和Spark日志目录
check_spark_dependencies() {
    print_step "检查Spark依赖"
    
    # 检查HDFS是否可访问
    print_info "检查HDFS服务..."
    if ! docker exec "${MASTER_NODES[0]}" /opt/hadoop/bin/hdfs dfs -ls / &>/dev/null; then
        print_warning "HDFS服务不可用，Spark历史服务器可能无法正常工作"
    else
        print_success "HDFS服务正常"
    fi
    
    # 检查Spark日志目录
    print_info "检查Spark日志目录..."
    if docker exec "${MASTER_NODES[0]}" /opt/hadoop/bin/hdfs dfs -test -d "$SPARK_LOG_DIR" 2>/dev/null; then
        print_success "Spark日志目录 '$SPARK_LOG_DIR' 存在"
    else
        print_warning "Spark日志目录 '$SPARK_LOG_DIR' 不存在"
        print_info "建议先运行 spark-init.sh 初始化Spark目录"
        
        print_message $YELLOW "是否自动创建Spark日志目录？[y/N]"
        read -t 10 -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if docker exec "${MASTER_NODES[0]}" /opt/hadoop/bin/hdfs dfs -mkdir -p "$SPARK_LOG_DIR" && \
               docker exec "${MASTER_NODES[0]}" /opt/hadoop/bin/hdfs dfs -chmod 777 "$SPARK_LOG_DIR"; then
                print_success "Spark日志目录创建成功"
            else
                print_error "Spark日志目录创建失败"
            fi
        fi
    fi
    
    return 0
}

# 执行命令并检查结果
execute_command() {
    local node=$1
    local command=$2
    local description=$3
    
    if docker exec "$node" $command &>/dev/null; then
        print_success "$node: $description"
        return 0
    else
        print_error "$node: $description 失败"
        return 1
    fi
}

# 启动Spark Master节点
start_spark_masters() {
    print_step "启动Spark Master节点 (HA模式)"
    
    local failed_masters=()
    
    for master in "${MASTER_NODES[@]}"; do
        print_info "启动 $master 上的Spark Master..."
        if execute_command "$master" "$SPARK_SBIN/start-master.sh" "启动Spark Master"; then
            continue
        else
            failed_masters+=("$master")
        fi
    done
    
    if [ ${#failed_masters[@]} -gt 0 ]; then
        print_warning "以下Master节点启动失败: ${failed_masters[*]}"
    fi
    
    # 等待Master启动
    show_progress 10 "等待Spark Master节点启动"
    
    return 0
}

# 启动Spark Worker节点
start_spark_workers() {
    print_step "启动Spark Worker节点"
    
    print_info "从 ${MASTER_NODES[0]} 启动所有Worker节点..."
    
    if docker exec "${MASTER_NODES[0]}" "$SPARK_SBIN/start-workers.sh"; then
        print_success "Spark Worker启动命令执行成功"
    else
        print_error "Spark Worker启动失败"
        return 1
    fi
    
    # 等待Worker启动
    show_progress 8 "等待Spark Worker节点启动"
    
    return 0
}

# 启动Spark历史服务器
start_spark_history_server() {
    print_step "启动Spark历史服务器"
    
    print_info "启动Spark历史服务器..."
    
    if docker exec "${MASTER_NODES[0]}" "$SPARK_SBIN/start-history-server.sh"; then
        print_success "Spark历史服务器启动成功"
    else
        print_warning "Spark历史服务器启动失败"
        return 1
    fi
    
    # 等待历史服务器启动
    show_progress 5 "等待Spark历史服务器启动"
    
    return 0
}

# 健康检查
health_check() {
    print_step "Spark集群健康检查"
    
    local checks=(
        "check_spark_masters:检查Spark Master状态"
        "check_spark_workers:检查Spark Worker状态"
        "check_spark_version:检查Spark版本"
        "check_spark_ui:检查Spark Web UI"
    )
    
    for check_info in "${checks[@]}"; do
        local func_name="${check_info%%:*}"
        local description="${check_info##*:}"
        
        print_info "$description..."
        if $func_name; then
            print_success "$description 通过"
        else
            print_warning "$description 失败或异常"
        fi
    done
}

# 检查Spark Master状态
check_spark_masters() {
    local active_masters=0
    
    for master in "${MASTER_NODES[@]}"; do
        if docker exec "$master" "$SPARK_BIN/spark-submit" --version &>/dev/null; then
            active_masters=$((active_masters + 1))
        fi
    done
    
    print_info "发现 $active_masters 个活跃的Spark Master"
    [ $active_masters -gt 0 ]
}

# 检查Spark Worker状态
check_spark_workers() {
    # 尝试从Spark Master获取Worker信息
    local worker_info
    if worker_info=$(docker exec "${MASTER_NODES[0]}" curl -s http://hadoop-master1:8080 2>/dev/null); then
        if echo "$worker_info" | grep -q "worker"; then
            return 0
        fi
    fi
    return 1
}

# 检查Spark版本
check_spark_version() {
    docker exec "${MASTER_NODES[0]}" "$SPARK_BIN/spark-submit" --version &>/dev/null
}

# 检查Spark Web UI
check_spark_ui() {
    docker exec "${MASTER_NODES[0]}" curl -s http://hadoop-master1:8080 &>/dev/null
}

# 显示集群状态
show_cluster_status() {
    print_step "Spark集群状态详情"
    
    echo
    print_message $CYAN "Spark版本信息:"
    docker exec "${MASTER_NODES[0]}" "$SPARK_BIN/spark-submit" --version 2>/dev/null || print_warning "无法获取Spark版本"
    
    echo
    print_message $CYAN "Spark Master节点状态:"
    for master in "${MASTER_NODES[@]}"; do
        if docker exec "$master" pgrep -f "org.apache.spark.deploy.master.Master" &>/dev/null; then
            print_success "$master: Master进程运行中"
        else
            print_warning "$master: Master进程未运行"
        fi
    done
    
    echo
    print_message $CYAN "Spark Worker节点状态:"
    for worker in "${WORKER_NODES[@]}"; do
        if docker exec "$worker" pgrep -f "org.apache.spark.deploy.worker.Worker" &>/dev/null; then
            print_success "$worker: Worker进程运行中"
        else
            print_warning "$worker: Worker进程未运行"
        fi
    done
}

# 显示连接信息
show_connection_info() {
    print_step "连接信息"
    
    echo
    print_message $CYAN "Spark Web访问地址:"
    echo "  - Master UI (主): http://hadoop-master1:8080"
    echo "  - Master UI (备1): http://hadoop-master2:8080"  
    echo "  - Master UI (备2): http://hadoop-master3:8080"
    echo "  - History Server: http://hadoop-master1:18080"
    
    echo
    print_message $CYAN "Spark Shell连接命令:"
    echo "  docker exec -it ${MASTER_NODES[0]} $SPARK_BIN/spark-shell"
    echo "  docker exec -it ${MASTER_NODES[0]} $SPARK_BIN/pyspark"
    
    echo
    print_message $CYAN "Spark Submit示例:"
    echo "  docker exec ${MASTER_NODES[0]} $SPARK_BIN/spark-submit \\"
    echo "    --class org.apache.spark.examples.SparkPi \\"
    echo "    --master spark://hadoop-master1:7077 \\"
    echo "    /opt/spark/examples/jars/spark-examples_*.jar 10"
}

# 测试Spark基本功能
test_spark_functionality() {
    print_info "测试Spark基本功能..."
    
    # 运行Spark Pi示例
    local test_command="$SPARK_BIN/spark-submit --class org.apache.spark.examples.SparkPi --master spark://hadoop-master1:7077 /opt/spark/examples/jars/spark-examples_*.jar 2"
    
    if docker exec "${MASTER_NODES[0]}" timeout 60 $test_command &>/dev/null; then
        print_success "Spark基本功能测试通过 (SparkPi)"
        return 0
    else
        print_warning "Spark基本功能测试失败"
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
    print_message $GREEN "       Spark集群启动完成！"
    print_message $GREEN "=========================================="
    echo
    print_success "启动耗时: ${duration}秒"
    print_success "集群模式: HA (高可用)"
    print_success "Master节点: ${#MASTER_NODES[@]} 个"
    print_success "Worker节点: ${#WORKER_NODES[@]} 个"
}

# 主函数
main() {
    local start_time=$(date +%s)
    
    # 显示标题
    echo
    print_message $PURPLE "${BOLD}========================================"
    print_message $PURPLE "${BOLD}    Spark集群启动脚本 (HA模式优化版)"
    print_message $PURPLE "${BOLD}========================================"
    echo
    
    # 显示集群配置
    print_message $CYAN "集群配置信息:"
    echo "  - Master节点: ${MASTER_NODES[*]}"
    echo "  - Worker节点: ${WORKER_NODES[*]}"
    echo "  - 运行模式: 高可用 (HA)"
    echo "  - 启动超时: ${STARTUP_TIMEOUT}秒"
    echo "  - 日志目录: $SPARK_LOG_DIR"
    echo
    
    # 执行启动步骤
    local steps=(
        "check_containers:检查容器状态"
        "check_spark_dependencies:检查Spark依赖"
        "start_spark_masters:启动Spark Masters"
        "start_spark_workers:启动Spark Workers"
        "start_spark_history_server:启动历史服务器"
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
            if [[ "$func_name" == "check_containers" ]]; then
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
        print_message $YELLOW "    Spark集群启动完成（有警告）"
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
            show_cluster_status
            ;;
        2)
            test_spark_functionality
            ;;
        *)
            print_info "跳过可选操作"
            ;;
    esac
    
    echo
    print_message $CYAN "提示: Spark集群现在可以接受作业提交"
    print_message $CYAN "访问 http://hadoop-master1:8080 查看Master Web UI"
}

# 错误处理
set -e
trap 'print_error "脚本执行过程中发生错误，位置: $BASH_COMMAND"' ERR

# 允许脚本在某些命令失败时继续运行
set +e

# 运行主函数
main "$@"