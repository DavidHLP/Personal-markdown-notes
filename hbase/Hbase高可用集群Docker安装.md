# 配置基于 Hadoop 和 HBase 的分布式系统

## 架构概述

本文档介绍如何使用Docker配置基于Hadoop和HBase的高可用分布式系统。高可用（HA）架构通过消除单点故障，确保系统的稳定性和连续可用性。

### 高可用架构关键组件

1. **ZooKeeper集群**：
   - 作为分布式协调服务，管理集群状态和领导者选举
   - 存储元数据信息，监控节点健康状态
   - 为Hadoop和HBase提供自动故障转移功能

2. **HDFS HA组件**：
   - **NameNode**：管理文件系统命名空间和客户端访问，HA模式下有Active和Standby角色
   - **JournalNode**：用于共享编辑日志，确保Standby NameNode与Active NameNode保持同步
   - **ZKFC (ZooKeeper Failover Controller)**：监控NameNode状态，管理自动故障转移
   - **DataNode**：存储实际数据块，向所有NameNode注册并报告块信息

3. **YARN HA组件**：
   - **ResourceManager**：管理集群资源分配，HA模式下具有主备角色
   - **NodeManager**：在每个工作节点上运行，管理容器和资源使用

4. **HBase HA组件**：
   - **HMaster**：管理RegionServer和元数据操作，HA模式下有主备角色
   - **RegionServer**：处理数据读写请求，管理数据分区(Region)

### 故障转移机制

1. **HDFS自动故障转移**：
   - ZKFC持续监控NameNode健康状态
   - 当Active NameNode故障时，通过ZooKeeper协调选举新的Active NameNode
   - 隔离(Fencing)机制防止脑裂情况发生

2. **HBase故障转移**：
   - 当主HMaster故障时，备用HMaster自动接管
   - RegionServer故障时，其管理的Region会重新分配给健康的RegionServer

### 配置文件详解

配置Hadoop和HBase高可用集群需要正确设置多个配置文件。以下是每个关键配置文件的作用及核心参数解释：

#### Hadoop配置文件

1. **hadoop-env.sh**
   - 环境变量配置文件，设置Hadoop运行时的系统环境
   - 定义Java路径、用户身份和内存分配等参数
   - 确保各组件以正确的用户身份运行，避免权限问题

2. **core-site.xml**
   - Hadoop核心配置文件，定义基础参数
   - 设置默认文件系统、I/O设置和安全参数
   - 配置ZooKeeper连接信息，为高可用提供协调服务

3. **hdfs-site.xml**
   - HDFS服务配置，包含NameNode、DataNode和高可用设置
   - 定义数据存储路径、复制因子和节点通信参数
   - 配置HA相关参数，包括自动故障转移和数据同步机制

4. **yarn-site.xml**
   - YARN资源管理器配置
   - 设置ResourceManager高可用参数
   - 定义资源分配策略和任务调度器

5. **mapred-site.xml**
   - MapReduce执行引擎配置
   - 设置作业历史服务器参数
   - 定义Map和Reduce任务的内存和CPU分配

#### HBase配置文件

1. **hbase-env.sh**
   - HBase环境变量配置
   - 设置Java路径和内存参数
   - 配置ZooKeeper管理策略

2. **hbase-site.xml**
   - HBase核心配置文件
   - 定义根目录、分布式模式和ZooKeeper连接
   - 设置Master故障转移参数

3. **regionservers**
   - 定义RegionServer节点列表
   - 指定哪些服务器将运行RegionServer角色

4. **backup-masters**
   - 配置备用Master节点
   - 在主Master故障时提供自动故障转移

#### 配置核心要点

- **高可用配置关键点**：正确设置ZooKeeper地址、JournalNode共享存储和ZKFC故障转移控制器
- **性能优化参数**：调整内存分配、缓冲区大小和线程池配置
- **安全配置考虑**：权限设置、代理用户配置和网络安全策略

## 资源配置

-   3 个 Hadoop Master 节点
-   3 个 Hadoop Worker 节点
-   3 个 ZooKeeper 节点

## 配置ZooKeeper

### pull官方的ZooKeeper镜像

```bash
docker pull zookeeper
```

### 写docker-compose.yml

```yml
version: '3.1'
 
services:
  zoo1:
    image: zookeeper:3.7.1-temurin
    container_name: zoo1
    restart: always
    hostname: zoo1
    ports:
      - 2181:2181
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181
    networks:
      zookeeper-cluster:
        ipv4_address: 10.10.1.10
 
  zoo2:
    image: zookeeper:3.7.1-temurin
    container_name: zoo2
    restart: always
    hostname: zoo2
    ports:
      - 2182:2181
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181
    networks:
      zookeeper-cluster:
        ipv4_address: 10.10.1.11
 
  zoo3:
    image: zookeeper:3.7.1-temurin
    container_name: zoo3
    restart: always
    hostname: zoo3
    ports:
      - 2183:2181
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181
    networks:
      zookeeper-cluster:
        ipv4_address: 10.10.1.12
 
networks:
  zookeeper-cluster:
    name: zookeeper-cluster
    ipam:
      config:
        - subnet: "10.10.1.0/24"
```

### 运行Dockerfile

```bash
docker-compose up -d
```

## 构建镜像david/hbase:2.5.10

### 准备Dockerfile

Dockerfile 本身只配置了基础系统环境和 JDK。

```bash
# 指定路径下创建文件Dockerfile
touch /路径/Dockerfile
```

### Dockerfile文件内容

#### Dockerfile for HBase and Hadoop Setup (ARM64 架构)

```dockerfile
FROM ubuntu:22.04

# 环境变量设置
ENV HADOOP_HOME /opt/hadoop
ENV HBASE_HOME /opt/hbase
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-arm64

# 以 root 用户执行
USER root

# 更新并安装依赖包
RUN apt-get update && \
    apt-get install -y sudo openjdk-8-jdk openssh-server openssh-client && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys && \
    mkdir -p /data/hdfs && \
    mkdir -p /data/hdfs/journal/node/local/data

# 启动 SSH 服务
RUN service ssh start

# 暴露端口
EXPOSE 9870 9868 9864 9866 8088 8020 16000 16010 16020 22

# 容器启动时启动 SSH
CMD ["/usr/sbin/sshd", "-D"]
```

#### Dockerfile for HBase and Hadoop Setup (AMD64 架构)

```dockerfile
FROM ubuntu:22.04

# 环境变量设置
ENV HADOOP_HOME /opt/hadoop
ENV HBASE_HOME /opt/hbase
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# 以 root 用户执行
USER root

# 更新并安装依赖包
RUN apt-get update && \
    apt-get install -y sudo openjdk-8-jdk openssh-server openssh-client && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys && \
    mkdir -p /data/hdfs && \
    mkdir -p /data/hdfs/journal/node/local/data

# 启动 SSH 服务
RUN service ssh start

# 暴露端口
EXPOSE 9870 9868 9864 9866 8088 8020 16000 16010 16020 22

# 容器启动时启动 SSH
CMD ["/usr/sbin/sshd", "-D"]
```

### 启动Dockerfile

```bahs
docker build -t david/hbase:2.5.10
```

## 安装 Hadoop 和 HBase

Dockerfile 本身只配置了基础系统环境和 JDK。接下来需要手动下载和安装 Hadoop 和 HBase。

### 下载和安装 Hadoop

1.  访问 [Hadoop 下载页面](https://hadoop.apache.org/releases.html) 并选择适合你的版本。<iframe src="https://hadoop.apache.org/releases.html" width="100%" height="600px"></iframe>
2.  可以使用2024年9月6号已经验证hadoop可用性的下载：

```bash
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

### 下载和安装 HBase

1.  访问 [HBase 下载页面](https://hbase.apache.org/downloads.html) 并选择适合的版本。<iframe src="https://hbase.apache.org/downloads.html" width="100%" height="600px"></iframe>
2.  可以使用2024年9月6号已经验证hbase可用性的下载：

```bash
wget https://dlcdn.apache.org/hbase/2.5.10/hbase-2.5.10-hadoop3-bin.tar.gz
```

### 使用docker-compose.yml去创建容器

**配置解释**:

-   Hadoop 和 HBase 文件被绑定到 `/opt/docker-data`, 如何自定义的路径请修改所以的`source`:后面的参数。
-   端口根据每个节点的功能映射。
-   zookeeper-cluster 用于多节点间的网络通信。

### 使用docker-compose.yml去创建容器

**配置解释**:

-   **数据挂载**：Hadoop和HBase文件被绑定到`/opt/docker-data`目录，如需自定义路径请修改所有的`source:`参数。确保宿主机目录有适当的读写权限。
  
-   **端口映射**：每个节点根据其功能映射不同端口，主要包括：
    - NameNode Web界面: 9870
    - DataNode Web界面: 9864
    - ResourceManager Web界面: 8088
    - NodeManager Web界面: 8042
    - HDFS服务端口: 8020
    - HBase Master Web界面: 16010
    - HBase RegionServer Web界面: 16030
    - ZooKeeper客户端端口: 2181, 2182, 2183
  
-   **网络配置**：
    - 使用预先创建的`zookeeper-cluster`网络进行集群内通信
    - 为每个容器分配固定IP地址，确保网络稳定性和主机名解析一致性
    - Master节点IP范围: 10.10.1.20-22
    - Worker节点IP范围: 10.10.1.23-25
    - ZooKeeper节点IP范围: 10.10.1.10-12
  
-   **容器互联**：
    - 所有容器加入同一网络，通过主机名可直接通信
    - 确保在`/etc/hosts`中添加对应的主机名映射，便于服务发现

```yml
version: '3'
 
services: 
  hadoop-master1: 
    image: david/hbase:2.5.10
    container_name: hadoop-master1
    hostname: hadoop-master1
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - | 
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "8020:8020"
      - "8042:8042"
      - "9870:9870"
      - "8088:8088"
      - "8032:8032"
      - "10020:10020"
      - "16000:16000"
      - "16010:16010"
    networks: 
      zookeeper-cluster:
        ipv4_address: 10.10.1.20
  hadoop-master2: 
    image: david/hbase:2.5.10
    container_name: hadoop-master2
    hostname: hadoop-master2
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - | 
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "28020:8020"
      - "18042:8042"
      - "29870:9870"
      - "28088:8088"
      - "28032:8032"
      - "20020:10020"
    networks:
      zookeeper-cluster:
        ipv4_address: 10.10.1.21
  hadoop-master3: 
    image: david/hbase:2.5.10
    container_name: hadoop-master3
    hostname: hadoop-master3
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - | 
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "38020:8020"
      - "28042:8042"
      - "39870:9870"
      - "38088:8088"
      - "38032:8032"
      - "30020:10020"
    networks: 
      zookeeper-cluster:
        ipv4_address: 10.10.1.22
  hadoop-worker1: 
    image: david/hbase:2.5.10
    container_name: hadoop-worker1
    hostname: hadoop-worker1
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - | 
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "9867:9867"
      - "38042:8042"
      - "9866:9866"
      - "9865:9865"
      - "9864:9864"
    networks: 
      zookeeper-cluster:
        ipv4_address: 10.10.1.23
  hadoop-worker2: 
    image: david/hbase:2.5.10
    container_name: hadoop-worker2
    hostname: hadoop-worker2
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - |
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "29867:9867"
      - "48042:8042"
      - "29866:9866"
      - "29865:9865"
      - "29864:9864"
    networks: 
      zookeeper-cluster:
        ipv4_address: 10.10.1.24
  hadoop-worker3: 
    image: david/hbase:2.5.10
    container_name: hadoop-worker3
    hostname: hadoop-worker3
    stdin_open: true
    tty: true
    command: 
      - sh 
      - -c 
      - | 
        /usr/sbin/sshd -D 
    volumes:
      - type: bind
        source: /opt/docker-data/hadoop-3.4.0
        target: /opt/hadoop
      - type: bind
        source: /opt/docker-data/hbase-2.5.10-hadoop3
        target: /opt/hbase
    ports: 
      - "39867:9867"
      - "58042:8042"
      - "39866:9866"
      - "39865:9865"
      - "39864:9864"
    networks: 
      zookeeper-cluster:
        ipv4_address: 10.10.1.25
 
networks:
  zookeeper-cluster:
    external: true
```

**注意事项**

-   存储权限：确保 `source`：后面的路径有足够的读写权限，如有必要，可以执行 `chmod +777`。
-   ZooKeeper：如果需要更多的 ZooKeeper 节点，可以增加 zookeeper 服务并指定不同的 ipv4\_address。

### 启动docker-compose.yml文件

```bash
# 在存在docker-compose.yml目录下
docker-compose up -d
```

### **修改配置文件**

这些配置文件用于设置 Hadoop 和 HBase 环境。在 Docker 容器内的 /opt/hadoop 和 /opt/hbase 是共享路径，因此只需要在本地路径下的配置文件中进行修改。

#### 配置文件作用详解

1. **hadoop-env.sh**: 设置Hadoop运行环境变量
   - `JAVA_HOME`: 指定Java安装路径
   - `HDFS_NAMENODE_USER`等: 定义各组件运行用户
   - 这些变量确保Hadoop服务以正确的用户身份启动

2. **core-site.xml**: Hadoop核心配置
   - `fs.defaultFS`: 定义HDFS默认文件系统URI，使用"hdfs://mycluster"启用高可用
   - `ha.zookeeper.quorum`: 指定ZooKeeper服务器列表，用于高可用协调
   - `hadoop.proxyuser.*`: 配置代理用户权限，允许特定用户代理访问

3. **hdfs-site.xml**: HDFS相关配置
   - `dfs.nameservices`和`dfs.ha.namenodes.*`: 定义高可用命名服务和NameNode标识
   - `dfs.namenode.rpc-address.*`: 配置各NameNode的RPC地址
   - `dfs.namenode.shared.edits.dir`: 指定共享编辑日志位置，NameNode通过此同步元数据
   - `dfs.journalnode.edits.dir`: 指定JournalNode存储编辑日志的目录
   - `dfs.ha.automatic-failover.enabled`: 启用自动故障转移
   - `dfs.ha.fencing.methods`: 配置隔离机制，防止脑裂

4. **yarn-site.xml**: YARN资源管理配置
   - `yarn.resourcemanager.ha.enabled`: 启用ResourceManager高可用
   - `yarn.resourcemanager.ha.rm-ids`: 指定ResourceManager节点标识
   - `hadoop.zk.address`: 指定ZooKeeper地址，用于ResourceManager状态同步

5. **hbase-site.xml**: HBase配置
   - `hbase.rootdir`: 指向HDFS上的HBase根目录，使用高可用nameservice "mycluster"
   - `hbase.cluster.distributed`: 设置为true启用分布式模式
   - `hbase.zookeeper.quorum`: 指定ZooKeeper服务器列表
   - `hbase.master.wait.on.zk`: 启用Master等待ZooKeeper进行故障转移协调

#### 初始化流程解释

1. **启动JournalNode**: 
   - JournalNode负责存储共享编辑日志
   - 必须在格式化NameNode前启动，确保编辑日志可以正确同步

2. **格式化主NameNode**:
   - 初始化HDFS文件系统元数据
   - 仅在首次设置集群时执行，后续不应重复操作

3. **Bootstrap Standby NameNode**:
   - 将主NameNode的元数据复制到备用NameNode
   - 确保备用节点拥有与主节点相同的命名空间信息

4. **格式化ZooKeeper**:
   - 初始化ZooKeeper中的HA状态信息
   - 使用`hdfs zkfc -formatZK`命令执行
   - 仅首次设置或重置HA配置时需要

5. **启动ZKFC(ZooKeeper Failover Controller)**:
   - 监控NameNode健康状态
   - 管理自动故障转移过程
   - 与ZooKeeper交互，进行主备NameNode选举

### **修改 `/etc/hosts` 文件**

```txt
# 添加以下内容
10.10.1.20 hadoop-master1
10.10.1.21 hadoop-master2
10.10.1.22 hadoop-master3
10.10.1.23 hadoop-worker1
10.10.1.24 hadoop-worker2
10.10.1.25 hadoop-worker3
```

### **初始化与启动服务**

#### **setup.sh**

此脚本为手动版本，初始化可能会出现很多错误，因此需要逐步排查，确保集群的稳定性。

```bash
# SSH 配置检查
docker exec hadoop-master1 ssh -o StrictHostKeyChecking=no hadoop-master2 exit
docker exec hadoop-master1 ssh -o StrictHostKeyChecking=no hadoop-master3 exit
docker exec hadoop-master2 ssh -o StrictHostKeyChecking=no hadoop-master1 exit
docker exec hadoop-master2 ssh -o StrictHostKeyChecking=no hadoop-master3 exit
docker exec hadoop-master3 ssh -o StrictHostKeyChecking=no hadoop-master1 exit
docker exec hadoop-master3 ssh -o StrictHostKeyChecking=no hadoop-master2 exit

# 启动 journalnode
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start journalnode

# 可以不启动 worker 节点上的 journalnode
docker exec hadoop-worker1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker3 /opt/hadoop/bin/hdfs --daemon start journalnode 

# 初始化 NameNode
docker exec -it hadoop-master1 bash
/opt/hadoop/bin/hdfs namenode -format
exit    # 退出容器
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start namenode

# Bootstrap Standby
docker exec -it hadoop-master2 bash
/opt/hadoop/bin/hdfs namenode -bootstrapStandby
exit
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start namenode

docker exec -it hadoop-master3 bash
/opt/hadoop/bin/hdfs namenode -bootstrapStandby
exit
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start namenode

# 停止 DFS
docker exec hadoop-master1 /opt/hadoop/sbin/stop-dfs.sh

# Zookeeper 数据重新格式化（如果需要，一般不是第一次初始化，都需要使用）
# docker exec -it hadoop-master1 bash
# /opt/hadoop/bin/hdfs zkfc -formatZK
# exit

# 启动 zkfc 和 DFS/YARN
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start zkfc
docker exec hadoop-master1 /opt/hadoop/sbin/start-dfs.sh
docker exec hadoop-master1 /opt/hadoop/sbin/start-yarn.sh
```

#### **clear\_namenode\_data.sh**

用于清理 NameNode 数据的脚本。

> 只能用于初始化hadoop的时候使用

```bash
#!/bin/bash

# 定义容器列表
containers=("hadoop-master1" "hadoop-master2" "hadoop-master3" "hadoop-worker1" "hadoop-worker2" "hadoop-worker3")

# 定义要移除的目录和文件
dirs=(
    "/data/hdfs/journal/node/local/data/mycluster"
    "/tmp/hadoop-root/dfs/data"
)
files=(
    "/tmp/hadoop-root-journalnode.pid"
)

# 遍历每个容器，检查并移除指定的目录和文件
for container in "${containers[@]}"; do
    echo "Checking and removing directories and files in $container..."

    # 移除目录
    for dir in "${dirs[@]}"; do
        docker exec "$container" sh -c "if [ -d '$dir' ]; then rm -r '$dir'; echo 'Removed $dir from $container'; else echo '$dir does not exist in $container'; fi"
    done

    # 移除文件
    for file in "${files[@]}"; do
        docker exec "$container" sh -c "if [ -f '$file' ]; then rm '$file'; echo 'Removed $file from $container'; else echo '$file does not exist in $container'; fi"
    done
done

echo "Cleanup completed."
```

#### **start.sh**

启动集群服务的脚本，先停止所有已运行的服务，然后重新启动。

```bash
#! /bin/bash
 
echo "starting all journalnode"
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker1 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker2 /opt/hadoop/bin/hdfs --daemon start journalnode
docker exec hadoop-worker3 /opt/hadoop/bin/hdfs --daemon start journalnode 
 
echo "starting hadoop-master1..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start namenode
sleep 2
echo "starting hadoop-master2..."
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon start namenode
echo "starting hadoop-master3..."
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon start namenode
sleep 2
echo "starting zkfc..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon start zkfc
echo "starting dfs..."
docker exec hadoop-master1 /opt/hadoop/sbin/start-dfs.sh
sleep 3
echo "starting yarn..."
docker exec hadoop-master1 /opt/hadoop/sbin/start-yarn.sh
echo "Done!"
```

#### **stop.sh**

用于停止所有集群服务的脚本。

```bash
echo "stoping yarn..."
docker exec hadoop-master1 /opt/hadoop/sbin/stop-yarn.sh
sleep 3
echo "stoping dfs..."
docker exec hadoop-master1 /opt/hadoop/sbin/stop-dfs.sh
echo "stoping zkfc..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon stop zkfc
sleep 2
echo "stoping hadoop-master3..."
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon stop namenode
echo "stoping hadoop-master2..."
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon stop namenode
sleep 2
echo "stoping hadoop-master1..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon stop namenode
echo "stoping all journalnode"
docker exec hadoop-worker3 /opt/hadoop/bin/hdfs --daemon stop journalnode 
docker exec hadoop-worker2 /opt/hadoop/bin/hdfs --daemon stop journalnode
docker exec hadoop-worker1 /opt/hadoop/bin/hdfs --daemon stop journalnode
docker exec hadoop-master3 /opt/hadoop/bin/hdfs --daemon stop journalnode
docker exec hadoop-master2 /opt/hadoop/bin/hdfs --daemon stop journalnode
docker exec hadoop-master1 /opt/hadoop/bin/hdfs --daemon stop journalnode
```

#### **check\_services.sh**

检查所有服务状态的脚本。

```bash
#! /bin/bash
echo "====================hadoop-master1:status===================="
docker exec hadoop-master1 jps
echo "====================hadoop-master2:status===================="
docker exec hadoop-master2 jps
echo "====================hadoop-master3:status===================="
docker exec hadoop-master3 jps
echo "====================hadoop-worker1:status===================="
docker exec hadoop-worker1 jps
echo "====================hadoop-worker2:status===================="
docker exec hadoop-worker2 jps
echo "====================hadoop-worker3:status===================="
docker exec hadoop-worker3 jps
echo "=========================zoo1:status========================="
docker exec zoo1 /apache-zookeeper-3.7.1-bin/bin/zkServer.sh status
```

### **HBase 启动指南**

#### **修改 HBase 的配置文件**

1.  **修改 `hbase-env.sh` 文件**

路径：`/opt/docker-data/hbase-2.5.10-hadoop3/conf/hbase-env.sh`

```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64  # 如果使用苹果电脑，需改为适配 arm 的 JAVA_HOME
export HBASE_MANAGES_ZK=false  # 确保前面的 # 被删除，确保后面的值为 false
export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"  # 确保前面的 # 被删除，确保后面的值为 true
```

2.  **修改 `hbase-site.xml` 文件**

路径：`/opt/docker-data/hbase-2.5.10-hadoop3/conf/hbase-site.xml`

```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <!-- 设置集群为分布式模式 -->
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>

  <!-- 设置 HBase 根目录，确保路径指向 HDFS 的高可用配置 -->
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://mycluster/hbase</value>
  </property>

  <!-- 临时目录设置 -->
  <property>
    <name>hbase.tmp.dir</name>
    <value>./tmp</value>
  </property>

  <!-- 允许使用本地文件系统 -->
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
  </property>

  <!-- ZooKeeper 配置 -->
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>zoo1,zoo2,zoo3</value>
  </property>

  <property>
    <name>hbase.zookeeper.property.clientPort</name>
    <value>2181</value>
  </property>

  <!-- 启用 ZooKeeper 管理 HBase Master 的故障转移 -->
  <property>
    <name>hbase.master.wait.on.zk</name>
    <value>true</value>
  </property>

  <!-- 设置 ZooKeeper 中用于监控 HBase Master 状态的路径 -->
  <property>
    <name>hbase.master.znode</name>
    <value>/hbase/master</value>
  </property>
</configuration>
```

3.  **修改 `regionservers` 文件**

路径：`/opt/docker-data/hbase-2.5.10-hadoop3/conf/regionservers`

```txt
hadoop-master1
hadoop-master2
hadoop-master3
```

4.  **建立 `backup-masters` 文件**

路径：`/opt/docker-data/hbase-2.5.10-hadoop3/conf/backup-masters`

```txt
hadoop-master1
hadoop-master2
hadoop-master3
```

5. **复制配置文件**

将Hadoop下的`hdfs-site.xml`、`core-site.xml`、`yarn-site.xml`和`mapred-site.xml`复制到Hbase下的conf目录

### **启动 HBase**

1.  启动 HBase

```bash
docker exec -it hadoop-master1 bash
/opt/hbase/bin/start-hbase.sh
```

2.  使用 `jps` 命令查看 HMaster 进程是否已启动。

```bash
jps
```

输出结果示例：

```txt
12112 NodeManager
11601 DFSZKFailoverController
12818 Jps
11109 NameNode
11430 JournalNode
11223 DataNode
12623 HMaster
11999 ResourceManager
```

3.  登录到 HBase Shell

```bash
/opt/hbase/bin/hbase shell
```

4.  使用 `status` 命令查看 HBase 集群状态。

```bash
status
```

输出结果示例：

```txt
1 active master, 1 backup masters, 2 servers, 0 dead, 0.5000 average load
```

> `HMaster` 一定要在`active``NameNode`上，否则会报错`ERROR: KeeperErrorCode = NoNode for /hbase/master` 并且上面的错误可能是因为`zookeeper`的`dataDir`被格式化了和`Hbase`指定的路径不同,这种时候需要格式化`zookeeper`

## 常见问题处理

### Hadoop相关问题

1. **NameNode无法启动或切换**
   - **问题现象**: NameNode启动失败或无法进行故障转移
   - **可能原因**: JournalNode未启动、ZK数据不一致、SSH配置错误
   - **解决方法**: 
     - 确保所有JournalNode正常运行：`jps | grep JournalNode`
     - 检查ZooKeeper中的数据：`zkCli.sh` 连接后使用 `ls /hadoop-ha`
     - 重置ZooKeeper中的状态：`hdfs zkfc -formatZK`
     - 验证SSH免密登录配置

2. **DataNode无法连接到NameNode**
   - **问题现象**: DataNode启动后无法注册到NameNode
   - **可能原因**: 网络配置问题、主机名解析错误、防火墙限制
   - **解决方法**:
     - 检查/etc/hosts配置
     - 确认DataNode可以ping通NameNode主机名
     - 检查日志中的具体连接错误

3. **SafeMode无法退出**
   - **问题现象**: HDFS一直处于安全模式
   - **可能原因**: 块报告不完整、DataNode数量不足
   - **解决方法**:
     - 检查是否有足够的DataNode: `hdfs dfsadmin -report`
     - 手动离开安全模式: `hdfs dfsadmin -safemode leave`
     - 检查blocks的复制情况

### HBase相关问题

1. **HMaster无法启动**
   - **问题现象**: HMaster启动失败，日志显示ZooKeeper连接问题
   - **可能原因**: ZooKeeper连接配置错误、HDFS权限问题
   - **解决方法**:
     - 验证ZooKeeper集群状态：`/opt/hbase/bin/hbase zkcli`
     - 确认HBase根目录在HDFS上存在且有正确权限
     - 检查HBase配置中的ZooKeeper地址是否正确

2. **Region服务器无法注册**
   - **问题现象**: RegionServer启动但未显示在Master UI中
   - **可能原因**: 主机名解析问题、ZooKeeper会话超时
   - **解决方法**:
     - 检查RegionServer日志中的错误信息
     - 确认主机名解析配置
     - 增加ZooKeeper会话超时设置

3. **ERROR: KeeperErrorCode = NoNode for /hbase/master**
   - **问题现象**: HMaster启动报错，无法在ZooKeeper中找到节点
   - **可能原因**: ZooKeeper数据与HBase配置不一致
   - **解决方法**:
     - 确保HMaster运行在active NameNode上
     - 清理ZooKeeper中的HBase相关数据：在ZK客户端中执行`rmr /hbase`
     - 重启HBase服务：`stop-hbase.sh` 然后 `start-hbase.sh`

### 系统优化建议

1. **增加内存分配**
   - 为大型集群中的主要组件分配更多内存，特别是NameNode和HMaster
   - 修改相应组件的环境变量：`HADOOP_HEAPSIZE`和`HBASE_HEAPSIZE`

2. **调整ZooKeeper配置**
   - 增加ZooKeeper会话超时时间，减少误判断
   - 配置ZooKeeper数据目录使用SSD存储，提高性能

3. **网络优化**
   - 使用专用网络接口用于集群内通信
   - 增加网络带宽，特别是对于大规模数据传输

4. **监控与维护**
   - 定期备份ZooKeeper和HDFS元数据
   - 设置监控系统跟踪集群健康状态
   - 实施定期维护计划，包括日志轮转和垃圾收集

-   **hadoop-env.sh**

> 将下面的内容添加到hadoop-env.sh文件末尾即可