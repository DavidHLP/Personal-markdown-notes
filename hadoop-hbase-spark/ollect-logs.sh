#!/bin/bash
# collect-logs.sh

LOG_DIR="/opt/bigdata-logs/$(date +%Y%m%d)"
mkdir -p $LOG_DIR

echo "=== 收集集群日志 ==="

# 收集Hadoop日志
echo "收集Hadoop日志..."
docker exec hadoop-master1 tar -czf /tmp/hadoop-logs.tar.gz /opt/hadoop/logs/
docker cp hadoop-master1:/tmp/hadoop-logs.tar.gz $LOG_DIR/

# 收集HBase日志
echo "收集HBase日志..."
docker exec hadoop-master1 tar -czf /tmp/hbase-logs.tar.gz /opt/hbase/logs/
docker cp hadoop-master1:/tmp/hbase-logs.tar.gz $LOG_DIR/

# 收集Spark日志
echo "收集Spark日志..."
docker exec hadoop-master1 tar -czf /tmp/spark-logs.tar.gz /opt/spark/logs/
docker cp hadoop-master1:/tmp/spark-logs.tar.gz $LOG_DIR/

echo "日志已收集到: $LOG_DIR"