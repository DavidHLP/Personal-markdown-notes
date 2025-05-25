#!/bin/bash
# hbase-init.sh - HBase 初始化脚本
# 优化版本：提供更好的用户体验

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
CONTAINER_NAME="hadoop-master1"
HDFS_HBASE_DIR="/hbase"
HADOOP_BIN="/opt/hadoop/bin/hdfs"

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

# 检查Docker容器是否运行
check_container() {
    print_info "检查Docker容器状态..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装或不在PATH中"
        return 1
    fi
    
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_error "容器 '$CONTAINER_NAME' 未运行"
        print_info "请先启动Hadoop集群容器"
        return 1
    fi
    
    print_success "容器 '$CONTAINER_NAME' 正在运行"
    return 0
}

# 检查HDFS服务状态
check_hdfs_status() {
    print_info "检查HDFS服务状态..."
    
    if ! docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -ls / &>/dev/null; then
        print_error "HDFS服务未正常运行"
        print_info "请确保Hadoop集群已正确启动"
        return 1
    fi
    
    print_success "HDFS服务正常"
    return 0
}

# 检查目录是否存在
check_directory_exists() {
    local dir_path=$1
    docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -test -d "$dir_path" 2>/dev/null
}

# 创建HDFS目录
create_hdfs_directory() {
    print_info "创建HDFS目录: $HDFS_HBASE_DIR"
    
    if check_directory_exists "$HDFS_HBASE_DIR"; then
        print_warning "目录 '$HDFS_HBASE_DIR' 已存在"
        return 0
    fi
    
    if docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -mkdir -p "$HDFS_HBASE_DIR"; then
        print_success "目录创建成功: $HDFS_HBASE_DIR"
        return 0
    else
        print_error "目录创建失败: $HDFS_HBASE_DIR"
        return 1
    fi
}

# 设置目录权限
set_directory_permissions() {
    print_info "设置目录权限: $HDFS_HBASE_DIR (755)"
    
    if docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -chmod 755 "$HDFS_HBASE_DIR"; then
        print_success "权限设置成功"
        return 0
    else
        print_error "权限设置失败"
        return 1
    fi
}

# 验证目录权限
verify_permissions() {
    print_info "验证目录权限..."
    
    local permissions=$(docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -ls / 2>/dev/null | grep "hbase" | awk '{print $1}')
    
    if [[ $permissions =~ drwxr-xr-x ]]; then
        print_success "权限验证通过: $permissions"
        return 0
    else
        print_warning "权限可能不正确: $permissions"
        return 1
    fi
}

# 显示目录信息
show_directory_info() {
    print_info "显示HBase目录信息:"
    echo
    print_message $CYAN "目录详情:"
    docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -ls -d "$HDFS_HBASE_DIR" 2>/dev/null || {
        print_error "无法获取目录信息"
        return 1
    }
    echo
}

# 显示HDFS概览
show_hdfs_overview() {
    print_info "HDFS文件系统概览:"
    echo
    print_message $CYAN "根目录内容:"
    docker exec "$CONTAINER_NAME" "$HADOOP_BIN" dfs -ls / 2>/dev/null || {
        print_error "无法获取HDFS信息"
        return 1
    }
    echo
}

# 主函数
main() {
    # 显示标题
    echo
    print_message $PURPLE "========================================"
    print_message $PURPLE "    HBase HDFS 初始化脚本 (优化版)"
    print_message $PURPLE "========================================"
    echo
    
    # 显示配置信息
    print_message $CYAN "配置信息:"
    echo "  - 容器名称: $CONTAINER_NAME"
    echo "  - HBase目录: $HDFS_HBASE_DIR"
    echo "  - Hadoop二进制: $HADOOP_BIN"
    echo
    
    # 执行检查和初始化步骤
    local steps=(
        "check_container:检查Docker容器"
        "check_hdfs_status:检查HDFS状态"
        "create_hdfs_directory:创建HBase目录"
        "set_directory_permissions:设置目录权限"
        "verify_permissions:验证权限设置"
        "show_directory_info:显示目录信息"
    )
    
    local total_steps=${#steps[@]}
    local current_step=0
    local failed_steps=()
    
    for step_info in "${steps[@]}"; do
        current_step=$((current_step + 1))
        local func_name="${step_info%%:*}"
        local description="${step_info##*:}"
        
        print_message $BLUE "[$current_step/$total_steps] $description"
        
        if ! $func_name; then
            failed_steps+=("$description")
            print_error "步骤失败: $description"
            
            # 对于关键步骤失败，询问是否继续
            if [[ "$func_name" == "check_container" || "$func_name" == "check_hdfs_status" ]]; then
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
    
    # 显示最终结果
    if [ ${#failed_steps[@]} -eq 0 ]; then
        print_message $GREEN "========================================"
        print_message $GREEN "       HBase 初始化成功完成！"
        print_message $GREEN "========================================"
        echo
        print_success "所有步骤均已成功执行"
    else
        print_message $YELLOW "========================================"
        print_message $YELLOW "    HBase 初始化完成（有警告）"
        print_message $YELLOW "========================================"
        echo
        print_warning "以下步骤执行失败或有警告:"
        for failed_step in "${failed_steps[@]}"; do
            print_error "- $failed_step"
        done
    fi
    
    echo
    print_info "可选操作: 显示HDFS概览？[y/N]"
    read -t 5 -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_hdfs_overview
    fi
    
    echo
    print_message $CYAN "提示: HBase现在可以使用HDFS目录 '$HDFS_HBASE_DIR'"
    print_message $CYAN "下一步: 启动HBase服务"
}

# 错误处理
set -e
trap 'print_error "脚本执行过程中发生错误，位置: $BASH_COMMAND"' ERR

# 允许脚本在某些命令失败时继续运行
set +e

# 运行主函数
main "$@"