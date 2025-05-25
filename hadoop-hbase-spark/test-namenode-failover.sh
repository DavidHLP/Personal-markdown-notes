#!/bin/bash
# test-namenode-failover.sh

echo "=== NameNode故障转移测试 ==="

# 查看当前Active NameNode
echo "当前Active NameNode:"
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1
docker exec hadoop-master2 /opt/hadoop/bin/hdfs haadmin -getServiceState nn2
docker exec hadoop-master3 /opt/hadoop/bin/hdfs haadmin -getServiceState nn3

# 模拟故障转移
echo "手动切换到nn2..."
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -transitionToStandby nn1
docker exec hadoop-master2 /opt/hadoop/bin/hdfs haadmin -transitionToActive nn2

# 验证切换结果
echo "切换后状态:"
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1
docker exec hadoop-master2 /opt/hadoop/bin/hdfs haadmin -getServiceState nn2
docker exec hadoop-master3 /opt/hadoop/bin/hdfs haadmin -getServiceState nn3

echo "=== 故障转移测试完成 ==="