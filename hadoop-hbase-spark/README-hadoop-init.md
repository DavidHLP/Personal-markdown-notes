# Hadoop HA集群初始化脚本使用指南

## 📋 脚本概述

`hadoop-init.sh` 是一个用于初始化Hadoop高可用(HA)集群的自动化脚本。该脚本提供了友好的用户界面，包括彩色日志输出、进度提示和状态检查。

## 🚀 功能特性

- ✅ **彩色日志输出** - 不同级别的日志使用不同颜色显示
- ✅ **进度跟踪** - 清晰的步骤划分和进度提示
- ✅ **状态检查** - 自动检查容器状态和命令执行结果
- ✅ **错误处理** - 详细的错误信息和失败时的退出机制
- ✅ **时间戳** - 每个操作都有准确的时间记录
- ✅ **ASCII艺术** - 友好的启动界面

## 🛠️ 使用方法

### 前提条件

确保满足以下条件：
- Docker和Docker Compose已安装并正常运行
- 当前目录下存在 `hadoop-compose.yml` 文件
- 具有执行Docker命令的权限

**注意**：脚本会自动启动以下容器，无需手动启动：
- `hadoop-master1`
- `hadoop-master2` 
- `hadoop-master3`
- `hadoop-worker1`
- `hadoop-worker2`
- `hadoop-worker3`

### 运行脚本

```bash
# 进入脚本目录
cd hadoop-hbase-spark

# 执行初始化脚本
./hadoop-init.sh
```

## 📊 脚本执行步骤

| 步骤 | 描述 | 操作内容 |
|------|------|----------|
| 0 | 启动Hadoop集群容器 | 使用docker-compose启动所有容器 |
| 1 | 检查Docker容器状态 | 验证所有必需容器是否运行 |
| 2 | 检查SSH免密登录配置 | 配置集群节点间的SSH连接 |
| 3 | 启动JournalNode服务 | 在所有节点启动JournalNode |
| 4 | 初始化主NameNode | 格式化并启动主NameNode |
| 5 | 配置备用NameNode | 设置Standby NameNode |
| 6 | 停止DFS服务 | 为重新配置做准备 |
| 7 | 初始化ZooKeeper故障切换控制器 | 格式化ZK中的HA状态信息 |
| 8 | 启动Hadoop服务 | 启动ZKFC、DFS和YARN |
| 9 | 验证服务状态 | 检查NameNode HA状态 |

## 🎨 日志级别说明

- 🔵 **[INFO]** - 一般信息提示 (蓝色)
- ✅ **[SUCCESS]** - 操作成功 (绿色)
- ⚠️ **[WARNING]** - 警告信息 (黄色)
- ❌ **[ERROR]** - 错误信息 (红色)

## 🌐 访问地址

脚本完成后，可以通过以下地址访问Hadoop Web界面：

- **NameNode Web UI**: http://localhost:9870
- **ResourceManager Web UI**: http://localhost:8088  
- **DataNode Web UI**: http://localhost:9864

## 🔧 常用管理命令

```bash
# 检查集群状态
docker exec hadoop-master1 /opt/hadoop/bin/hdfs dfsadmin -report

# 检查NameNode HA状态
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn2

# 手动切换NameNode
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -transitionToActive nn2

# 检查YARN节点状态  
docker exec hadoop-master1 /opt/hadoop/bin/yarn node -list
```

## 🛑 停止服务

如需停止Hadoop服务，请依次运行：

```bash
docker exec hadoop-master1 /opt/hadoop/sbin/stop-yarn.sh
docker exec hadoop-master1 /opt/hadoop/sbin/stop-dfs.sh  
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon stop zkfc
```

## ⚠️ 注意事项

1. 确保在运行脚本前所有Docker容器都已启动
2. 脚本会自动格式化NameNode，这会清除现有数据
3. 如果出现错误，请检查容器日志进行排查
4. 建议在测试环境中先验证脚本功能

## 🐛 故障排除

### 常见问题

1. **容器未运行错误**
   - 检查Docker容器状态：`docker ps`
   - 启动相关容器后重新运行脚本

2. **SSH连接失败**
   - 检查容器间网络连通性
   - 验证SSH密钥配置

3. **NameNode格式化失败**
   - 检查磁盘空间
   - 查看容器日志：`docker logs hadoop-master1`

4. **ZooKeeper连接问题**
   - 确认ZooKeeper服务正常运行
   - 检查网络配置

---

**作者**: DavidHLP  
**版本**: 1.0  
**更新日期**: $(date '+%Y-%m-%d') 