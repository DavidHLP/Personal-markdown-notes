#!/bin/bash

#######################################################################
# Hadoop 集群高可用(HA)初始化脚本
# 
# 功能说明：
# 1. 配置SSH免密登录
# 2. 启动JournalNode服务 
# 3. 格式化NameNode并配置Standby
# 4. 初始化ZooKeeper故障切换控制器
# 5. 启动Hadoop分布式文件系统和YARN
#
# 使用方法：bash hadoop-init.sh
# 作者：DavidHLP
# 版本：1.0
#######################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志文件配置
LOG_DIR="$(pwd)"
LOG_FILE="${LOG_DIR}/hadoop-init-$(date '+%Y%m%d_%H%M%S').log"

# 初始化日志文件
init_log() {
    echo "=====================================" > "$LOG_FILE"
    echo "Hadoop 集群初始化日志" >> "$LOG_FILE"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "日志文件: $LOG_FILE" >> "$LOG_FILE"
    echo "=====================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# 日志函数 - 同时输出到终端和文件
log_info() {
    local msg="[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${BLUE}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_step() {
    local step_msg="步骤 $1: $2"
    echo -e "\n${PURPLE}========================================${NC}"
    echo -e "${PURPLE}${step_msg}${NC}"
    echo -e "${PURPLE}========================================${NC}"
    
    echo "" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "$step_msg" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
}

# 检查容器状态
check_container() {
    if docker ps --format "table {{.Names}}" | grep -q "$1"; then
        return 0
    else
        return 1
    fi
}

# 执行命令并记录输出到日志
exec_and_log() {
    local cmd="$1"
    local description="$2"
    
    if [ -n "$description" ]; then
        log_info "执行: $description"
        echo "[COMMAND] $description" >> "$LOG_FILE"
    fi
    
    echo "[CMD] $cmd" >> "$LOG_FILE"
    
    # 执行命令并捕获输出
    local output
    output=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    # 记录输出到日志文件
    if [ -n "$output" ]; then
        echo "[OUTPUT] $output" >> "$LOG_FILE"
    fi
    
    echo "[EXIT_CODE] $exit_code" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    return $exit_code
}

echo -e "${CYAN}"
echo "  _   _           _                   _____       _ _   "
echo " | | | |         | |                 |_   _|     (_) |  "
echo " | |_| | __ _  __| | ___   ___  _ __   | |  _ __  _| |_ "
echo " |  _  |/ _\` |/ _\` |/ _ \ / _ \| '_ \  | | | '_ \| | __|"
echo " | | | | (_| | (_| | (_) | (_) | |_) |_| |_| | | | | |_ "
echo " |_| |_|\__,_|\__,_|\___/ \___/| .__/|_____|_| |_|_|\__|"
echo "                              | |                      "
echo "                              |_|                      "
echo -e "${NC}"
echo -e "${CYAN}Hadoop 高可用集群初始化脚本启动...${NC}\n"

# 初始化日志文件
init_log
log_info "Hadoop 高可用集群初始化脚本启动..."
log_info "日志文件位置: $LOG_FILE"

# 启动Docker容器
log_step "0" "启动Hadoop集群容器"
log_info "使用docker-compose启动所有容器..."
exec_and_log "docker-compose -f hadoop-compose.yml up -d" "启动Docker容器"
if [ $? -eq 0 ]; then
    log_success "容器启动命令执行成功"
    log_info "等待容器完全启动..."
    sleep 10
else
    log_error "容器启动失败，请检查docker-compose.yml文件"
    exit 1
fi

# 检查必要的容器是否运行
log_step "1" "检查Docker容器状态"
containers=("hadoop-master1" "hadoop-master2" "hadoop-master3" "hadoop-worker1" "hadoop-worker2" "hadoop-worker3")
for container in "${containers[@]}"; do
    if check_container "$container"; then
        log_success "容器 $container 正在运行"
    else
        log_error "容器 $container 未运行，启动可能失败"
        exit 1
    fi
done

# SSH 配置检查
log_step "2" "检查SSH免密登录配置"
log_info "配置master1到其他节点的SSH连接..."
docker exec hadoop-master1 ssh -o StrictHostKeyChecking=no hadoop-master2 exit
if [ $? -eq 0 ]; then
    log_success "master1 -> master2 SSH连接成功"
else
    log_warning "master1 -> master2 SSH连接失败"
fi

docker exec hadoop-master1 ssh -o StrictHostKeyChecking=no hadoop-master3 exit
if [ $? -eq 0 ]; then
    log_success "master1 -> master3 SSH连接成功"
else
    log_warning "master1 -> master3 SSH连接失败"
fi

log_info "配置master2到其他节点的SSH连接..."
docker exec hadoop-master2 ssh -o StrictHostKeyChecking=no hadoop-master1 exit
docker exec hadoop-master2 ssh -o StrictHostKeyChecking=no hadoop-master3 exit

log_info "配置master3到其他节点的SSH连接..."
docker exec hadoop-master3 ssh -o StrictHostKeyChecking=no hadoop-master1 exit
docker exec hadoop-master3 ssh -o StrictHostKeyChecking=no hadoop-master2 exit

log_success "SSH免密登录配置完成"

# 启动 journalnode
log_step "3" "启动JournalNode服务"
log_info "在Master节点启动JournalNode..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start journalnode

log_info "在Worker节点启动JournalNode（可选）..."
# 可以不启动 worker 节点上的 journalnode
docker exec hadoop-worker1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker3 /opt/hadoop/bin/hdfs --daemon start journalnode

log_success "JournalNode服务启动完成"
sleep 3

# 初始化 NameNode
log_step "4" "初始化主NameNode"
log_info "格式化master1上的NameNode..."
docker exec hadoop-master1 bash /opt/hadoop/bin/hdfs namenode -format -force
if [ $? -eq 0 ]; then
    log_success "NameNode格式化成功"
else
    log_error "NameNode格式化失败"
    exit 1
fi

log_info "启动master1上的NameNode..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start namenode
sleep 5

# Bootstrap Standby
log_step "5" "配置备用NameNode"
log_info "配置master2作为Standby NameNode..."
docker exec -it hadoop-master2 bash /opt/hadoop/bin/hdfs namenode -bootstrapStandby -force
if [ $? -eq 0 ]; then
    log_success "master2 Standby NameNode配置成功"
else
    log_error "master2 Standby NameNode配置失败"
fi

docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start namenode

log_info "配置master3作为Standby NameNode..."
docker exec -it hadoop-master3 bash /opt/hadoop/bin/hdfs namenode -bootstrapStandby -force
if [ $? -eq 0 ]; then
    log_success "master3 Standby NameNode配置成功"
else
    log_error "master3 Standby NameNode配置失败"
fi

docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start namenode

log_success "备用NameNode配置完成"
sleep 3

# 停止 DFS
log_step "6" "停止DFS服务准备重新配置"
log_info "停止分布式文件系统..."
docker exec hadoop-master1 /opt/hadoop/sbin/stop-dfs.sh
sleep 5

# Zookeeper 数据重新格式化（如果需要）
log_step "7" "初始化ZooKeeper故障切换控制器"
log_info "格式化ZooKeeper中的HA状态信息..."
docker exec -it hadoop-master1 bash /opt/hadoop/bin/hdfs zkfc -formatZK -force
if [ $? -eq 0 ]; then
    log_success "ZooKeeper格式化成功"
else
    log_error "ZooKeeper格式化失败"
fi

# 启动 zkfc 和 DFS/YARN
log_step "8" "启动Hadoop服务"
log_info "启动ZooKeeper故障切换控制器..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start zkfc

log_info "启动分布式文件系统..."
docker exec hadoop-master1 /opt/hadoop/sbin/start-dfs.sh
sleep 5

log_info "启动YARN资源管理器..."
docker exec hadoop-master1 /opt/hadoop/sbin/start-yarn.sh
sleep 5

log_success "Hadoop服务启动完成"

log_step "9" "验证服务状态"
log_info "检查NameNode状态..."
exec_and_log "docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1" "检查NameNode nn1状态"
exec_and_log "docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn2" "检查NameNode nn2状态"
exec_and_log "docker exec hadoop-master1 /opt/hadoop/bin/hdfs dfsadmin -report" "检查HDFS集群状态"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Hadoop HA集群初始化完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}访问信息：${NC}"
echo -e "  • NameNode Web UI: http://hadoop-master1:9870"
echo -e "  • ResourceManager Web UI: http://hadoop-master1:8088"
echo -e "  • DataNode Web UI: http://hadoop-worker1:9864"
echo -e "${YELLOW}常用命令：${NC}"
echo -e "  • 检查集群状态: docker exec hadoop-master1 /opt/hadoop/bin/hdfs dfsadmin -report"
echo -e "  • 检查HA状态: docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1"
echo -e "${YELLOW}如需停止服务，请运行以下命令：${NC}"

# 记录完成日志
log_success "Hadoop 高可用集群初始化脚本执行完成！"
log_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
log_info "日志已保存到: $LOG_FILE"
echo "" >> "$LOG_FILE"
echo "=====================================" >> "$LOG_FILE"
echo "脚本执行完成" >> "$LOG_FILE"
echo "结束时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "=====================================" >> "$LOG_FILE"

# 停止服务的命令（注释掉，供用户参考）
# docker exec hadoop-master1 /opt/hadoop/sbin/stop-yarn.sh
# docker exec hadoop-master1 /opt/hadoop/sbin/stop-dfs.sh
# docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon stop zkfc