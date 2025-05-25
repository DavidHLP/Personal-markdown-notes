
echo "========== 大数据平台健康检查 =========="

echo "1. ZooKeeper集群状态:"
docker exec zoo1 /apache-zookeeper-3.7.1-bin/bin/zkServer.sh status
docker exec zoo2 /apache-zookeeper-3.7.1-bin/bin/zkServer.sh status
docker exec zoo3 /apache-zookeeper-3.7.1-bin/bin/zkServer.sh status

echo -e "\n2. Hadoop集群状态:"
echo "--- NameNode状态 ---"
docker exec hadoop-master1 /opt/hadoop/bin/hdfs haadmin -getServiceState nn1
docker exec hadoop-master2 /opt/hadoop/bin/hdfs haadmin -getServiceState nn2
docker exec hadoop-master3 /opt/hadoop/bin/hdfs haadmin -getServiceState nn3

echo "--- HDFS报告 ---"
docker exec hadoop-master1 /opt/hadoop/bin/hdfs dfsadmin -report | head -20

echo "--- YARN节点 ---"
docker exec hadoop-master1 /opt/hadoop/bin/yarn node -list