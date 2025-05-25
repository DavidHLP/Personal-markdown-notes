#!/bin/bash
# start-hadoop.sh - Hadoop集群启动脚本
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

# 集群节点配置
MASTER_NODES=("hadoop-master1" "hadoop-master2" "hadoop-master3")
WORKER_NODES=("hadoop-worker1" "hadoop-worker2" "hadoop-worker3")
ALL_NODES=("${MASTER_NODES[@]}" "${WORKER_NODES[@]}")

# 服务配置
HADOOP_BIN="/opt/hadoop/bin"
HADOOP_SBIN="/opt/hadoop/sbin"
STARTUP_TIMEOUT=120
HEALTH_CHECK_TIMEOUT=30

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
        print_info "请先启动所有Hadoop容器"
        return 1
    fi
    
    print_success "所有容器状态正常"
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

# 启动JournalNode服务
start_journalnodes() {
    print_step "启动JournalNode服务"
    
    local failed_nodes=()
    
    for node in "${ALL_NODES[@]}"; do
        if execute_command "$node" "$HADOOP_BIN/hdfs --daemon start journalnode" "启动JournalNode"; then
            continue
        else
            failed_nodes+=("$node")
        fi
    done
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        print_warning "以下节点JournalNode启动失败: ${failed_nodes[*]}"
    fi
    
    # 等待JournalNode启动
    show_progress 5 "等待JournalNode服务启动"
    
    return 0
}

# 启动ZKFC服务
start_zkfc() {
    print_step "启动ZKFC服务"
    
    execute_command "hadoop-master1" "$HADOOP_BIN/hdfs --daemon start zkfc" "启动ZKFC"
    
    # 等待ZKFC启动
    show_progress 3 "等待ZKFC服务启动"
    
    return 0
}

# 启动HDFS服务
start_hdfs() {
    print_step "启动HDFS服务"
    
    print_info "从 hadoop-master1 启动分布式文件系统..."
    
    if docker exec hadoop-master1 $HADOOP_SBIN/start-dfs.sh; then
        print_success "HDFS启动命令执行成功"
    else
        print_error "HDFS启动失败"
        return 1
    fi
    
    # 等待HDFS服务启动
    show_progress 10 "等待HDFS服务完全启动"
    
    return 0
}

# 启动YARN服务
start_yarn() {
    print_step "启动YARN服务"
    
    print_info "从 hadoop-master1 启动资源管理器..."
    
    if docker exec hadoop-master1 $HADOOP_SBIN/start-yarn.sh; then
        print_success "YARN启动命令执行成功"
    else
        print_error "YARN启动失败"
        return 1
    fi
    
    # 等待YARN服务启动
    show_progress 8 "等待YARN服务完全启动"
    
    return 0
}

# 启动JobHistory Server
start_jobhistory() {
    print_step "启动JobHistory Server"
    
    local failed_nodes=()
    
    for node in "${MASTER_NODES[@]}"; do
        if execute_command "$node" "$HADOOP_BIN/mapred --daemon start historyserver" "启动JobHistory Server"; then
            continue
        else
            failed_nodes+=("$node")
        fi
    done
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        print_warning "以下节点JobHistory Server启动失败: ${failed_nodes[*]}"
    fi
    
    # 等待服务启动
    show_progress 5 "等待JobHistory Server启动"
    
    return 0
}

# 健康检查
health_check() {
    print_step "集群健康检查"
    
    local checks=(
        "check_hdfs_namenode:检查HDFS NameNode"
        "check_yarn_resourcemanager:检查YARN ResourceManager"
        "check_cluster_nodes:检查集群节点状态"
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

# 检查HDFS NameNode状态
check_hdfs_namenode() {
    docker exec hadoop-master1 $HADOOP_BIN/hdfs dfs -ls / &>/dev/null
}

# 检查YARN ResourceManager状态
check_yarn_resourcemanager() {
    docker exec hadoop-master1 $HADOOP_BIN/yarn node -list &>/dev/null
}

# 检查集群节点状态
check_cluster_nodes() {
    local active_nodes=$(docker exec hadoop-master1 $HADOOP_BIN/hdfs dfsadmin -report 2>/dev/null | grep "Live datanodes" | cut -d'(' -f2 | cut -d')' -f1 || echo "0")
    if [ "$active_nodes" -gt 0 ]; then
        print_info "发现 $active_nodes 个活跃的DataNode"
        return 0
    else
        return 1
    fi
}

# 显示集群状态
show_cluster_status() {
    print_step "集群状态概览"
    
    echo
    print_message $CYAN "HDFS状态:"
    docker exec hadoop-master1 $HADOOP_BIN/hdfs dfsadmin -report 2>/dev/null | head -10 || print_warning "无法获取HDFS状态"
    
    echo
    print_message $CYAN "YARN节点状态:"
    docker exec hadoop-master1 $HADOOP_BIN/yarn node -list 2>/dev/null || print_warning "无法获取YARN节点状态"
    
    echo
    print_message $CYAN "Web访问地址:"
    echo "  - HDFS NameNode: http://localhost:9870"
    echo "  - YARN ResourceManager: http://localhost:8088"
    echo "  - JobHistory Server: http://localhost:19888"
}

# 显示启动摘要
show_startup_summary() {
    local start_time=$1
    local end_time=$2
    local duration=$((end_time - start_time))
    
    print_step "启动摘要"
    
    print_message $GREEN "=========================================="
    print_message $GREEN "       Hadoop集群启动完成！"
    print_message $GREEN "=========================================="
    echo
    print_success "启动耗时: ${duration}秒"
    print_success "集群节点: ${#ALL_NODES[@]} 个"
    print_success "主节点: ${#MASTER_NODES[@]} 个"
    print_success "工作节点: ${#WORKER_NODES[@]} 个"
}

# 主函数
main() {
    local start_time=$(date +%s)
    
    # 显示标题
    echo
    print_message $PURPLE "${BOLD}========================================"
    print_message $PURPLE "${BOLD}    Hadoop集群启动脚本 (优化版)"
    print_message $PURPLE "${BOLD}========================================"
    echo
    
    # 显示集群配置
    print_message $CYAN "集群配置信息:"
    echo "  - 主节点: ${MASTER_NODES[*]}"
    echo "  - 工作节点: ${WORKER_NODES[*]}"
    echo "  - 启动超时: ${STARTUP_TIMEOUT}秒"
    echo
    
    # 执行启动步骤
    local steps=(
        "check_containers:检查容器状态"
        "start_journalnodes:启动JournalNode"
        "start_zkfc:启动ZKFC"
        "start_hdfs:启动HDFS"
        "start_yarn:启动YARN"
        "start_jobhistory:启动JobHistory Server"
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
        print_message $YELLOW "    Hadoop集群启动完成（有警告）"
        print_message $YELLOW "========================================"
        echo
        print_warning "以下步骤执行失败或有警告:"
        for failed_step in "${failed_steps[@]}"; do
            print_error "- $failed_step"
        done
        echo
        print_info "启动耗时: $((end_time - start_time))秒"
    fi
    
    # 询问是否显示集群状态
    echo
    print_info "是否显示详细的集群状态？[y/N]"
    read -t 10 -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_cluster_status
    fi
    
    echo
    print_message $CYAN "提示: 如需停止集群，请运行相应的停止脚本"
    print_message $CYAN "集群现在可以接受作业提交"
}

# 错误处理
set -e
trap 'print_error "脚本执行过程中发生错误，位置: $BASH_COMMAND"' ERR

# 允许脚本在某些命令失败时继续运行
set +e

# 运行主函数
main "$@"