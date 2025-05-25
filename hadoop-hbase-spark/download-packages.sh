#!/bin/bash
# download-packages.sh - 大数据软件包下载脚本
# 优化版本：提供更好的用户体验

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 全局变量
DOWNLOAD_DIR="$HOME/opt/docker-data/hadoop-hbase-spark"
TOTAL_STEPS=4
CURRENT_STEP=0

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印步骤进度
print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_message $BLUE "[$CURRENT_STEP/$TOTAL_STEPS] $1"
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

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "未找到 $1 命令，请先安装"
        exit 1
    fi
}

# 下载文件（带进度条和重试机制）
download_file() {
    local url=$1
    local filename=$2
    local description=$3
    
    if [ -f "$filename" ]; then
        print_warning "$description 文件已存在，跳过下载"
        return 0
    fi
    
    print_message $YELLOW "正在下载 $description..."
    
    # 尝试下载，最多重试3次
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        if wget --progress=bar:force:noscroll --timeout=30 --tries=3 "$url" -O "$filename"; then
            print_success "$description 下载完成"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "下载失败，正在重试 ($retry_count/$max_retries)..."
                sleep 2
            fi
        fi
    done
    
    print_error "$description 下载失败，已重试 $max_retries 次"
    return 1
}

# 解压文件
extract_file() {
    local filename=$1
    local target_dir=$2
    local description=$3
    
    if [ -d "$target_dir" ]; then
        print_warning "$description 目录已存在，跳过解压"
        return 0
    fi
    
    print_message $YELLOW "正在解压 $description..."
    
    case "$filename" in
        *.tar.gz|*.tgz)
            if tar -xzf "$filename"; then
                print_success "$description 解压完成"
                return 0
            fi
            ;;
        *.tar.bz2)
            if tar -xjf "$filename"; then
                print_success "$description 解压完成"
                return 0
            fi
            ;;
        *)
            print_error "不支持的文件格式: $filename"
            return 1
            ;;
    esac
    
    print_error "$description 解压失败"
    return 1
}

# 清理下载的压缩包
cleanup_archives() {
    print_message $YELLOW "是否要删除下载的压缩包以节省空间？[y/N]"
    read -t 10 -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $YELLOW "正在清理压缩包..."
        rm -f *.tar.gz *.tgz *.tar.bz2 2>/dev/null
        print_success "压缩包清理完成"
    else
        print_message $BLUE "保留压缩包"
    fi
}

# 显示磁盘空间
show_disk_usage() {
    print_message $PURPLE "当前目录磁盘使用情况："
    du -sh "$DOWNLOAD_DIR" 2>/dev/null || echo "无法获取磁盘使用情况"
}

# 主函数
main() {
    # 显示标题
    echo
    print_message $PURPLE "=========================================="
    print_message $PURPLE "   大数据软件包下载脚本 (优化版)"
    print_message $PURPLE "=========================================="
    echo

    # 检查必需的命令
    print_message $BLUE "检查系统环境..."
    check_command "wget"
    check_command "tar"
    print_success "系统环境检查通过"
    echo

    # 创建下载目录
    print_message $BLUE "创建下载目录: $DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR" || {
        print_error "无法进入目录 $DOWNLOAD_DIR"
        exit 1
    }
    print_success "目录创建成功"
    echo

    # 下载和解压 Hadoop
    print_step "处理 Hadoop 3.4.0"
    if download_file "https://archive.apache.org/dist/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz" \
                     "hadoop-3.4.0.tar.gz" "Hadoop 3.4.0"; then
        extract_file "hadoop-3.4.0.tar.gz" "hadoop" "Hadoop"
        [ -d "hadoop-3.4.0" ] && mv hadoop-3.4.0 hadoop
    else
        print_error "Hadoop 下载失败，跳过"
    fi
    echo

    # 下载和解压 HBase
    print_step "处理 HBase 2.5.10"
    if download_file "https://archive.apache.org/dist/hbase/2.5.10/hbase-2.5.10-hadoop3-bin.tar.gz" \
                     "hbase-2.5.10-hadoop3-bin.tar.gz" "HBase 2.5.10"; then
        extract_file "hbase-2.5.10-hadoop3-bin.tar.gz" "hbase" "HBase"
        [ -d "hbase-2.5.10-hadoop3" ] && mv hbase-2.5.10-hadoop3 hbase
    else
        print_error "HBase 下载失败，跳过"
    fi
    echo

    # 下载和解压 Spark
    print_step "处理 Spark 3.4.1"
    if download_file "https://archive.apache.org/dist/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz" \
                     "spark-3.4.1-bin-hadoop3.tgz" "Spark 3.4.1"; then
        extract_file "spark-3.4.1-bin-hadoop3.tgz" "spark" "Spark"
        [ -d "spark-3.4.1-bin-hadoop3" ] && mv spark-3.4.1-bin-hadoop3 spark
    else
        print_error "Spark 下载失败，跳过"
    fi
    echo

    # 下载 Miniconda
    print_step "处理 Miniconda"
    download_file "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" \
                  "Miniconda3-latest-Linux-x86_64.sh" "Miniconda"
    # 设置 Miniconda 安装脚本权限
    [ -f "Miniconda3-latest-Linux-x86_64.sh" ] && chmod +x Miniconda3-latest-Linux-x86_64.sh
    echo

    # 设置目录权限
    print_message $BLUE "设置目录权限..."
    chmod -R 755 "$DOWNLOAD_DIR"
    print_success "权限设置完成"
    echo

    # 显示磁盘使用情况
    show_disk_usage
    echo

    # 清理压缩包
    cleanup_archives
    echo

    # 显示完成信息
    print_message $GREEN "=========================================="
    print_message $GREEN "         所有软件包处理完成！"
    print_message $GREEN "=========================================="
    echo
    print_message $BLUE "下载目录: $DOWNLOAD_DIR"
    print_message $BLUE "已安装的软件："
    [ -d "hadoop" ] && print_success "Hadoop 3.4.0"
    [ -d "hbase" ] && print_success "HBase 2.5.10"
    [ -d "spark" ] && print_success "Spark 3.4.1"
    [ -f "Miniconda3-latest-Linux-x86_64.sh" ] && print_success "Miniconda (安装脚本)"
    echo
    print_message $YELLOW "提示: Miniconda 需要手动运行安装脚本："
    print_message $YELLOW "bash $DOWNLOAD_DIR/Miniconda3-latest-Linux-x86_64.sh"
}

# 错误处理
set -e
trap 'print_error "脚本执行过程中发生错误，位置: $BASH_COMMAND"' ERR

# 运行主函数
main "$@"