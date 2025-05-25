#!/bin/bash
# backup-hdfs.sh

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/bigdata-backup/hdfs/$BACKUP_DATE"

echo "=== HDFS数据备份 ==="

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份HDFS元数据
echo "备份NameNode元数据..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs dfsadmin -saveNamespace
docker exec hadoop-master1 tar -czf /tmp/namenode-backup.tar.gz /data/hdfs/namenode/
docker cp hadoop-master1:/tmp/namenode-backup.tar.gz $BACKUP_DIR/

# 备份重要数据
echo "备份用户数据..."
docker exec hadoop-master1 /opt/hadoop/bin/hadoop distcp \
    hdfs://mycluster/user \
    hdfs://mycluster/backup/user_$BACKUP_DATE

echo "HDFS备份完成: $BACKUP_DIR"