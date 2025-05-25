#!/bin/bash
# data-flow-test.sh

echo "=== 数据流完整性测试 ==="

# 1. HDFS存储测试
echo "1. 测试HDFS存储..."
docker exec hadoop-master1 bash -c "
echo 'Hello Big Data Platform' | /opt/hadoop/bin/hdfs dfs -put - /tmp/test-data.txt
/opt/hadoop/bin/hdfs dfs -cat /tmp/test-data.txt
/opt/hadoop/bin/hdfs dfs -rm /tmp/test-data.txt
"

# 2. HBase数据库测试
echo "2. 测试HBase数据库..."
docker exec hadoop-master1 /opt/hbase/bin/hbase shell <<EOF
create 'test_flow', 'data'
put 'test_flow', 'row1', 'data:message', 'Integration Test Success'
get 'test_flow', 'row1'
disable 'test_flow'
drop 'test_flow'
exit
EOF

# 3. Spark计算测试
echo "3. 测试Spark计算..."
docker exec hadoop-master1 /opt/spark/bin/spark-submit \
  --master spark://hadoop-master1:7077 \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.12-3.4.1.jar 5

echo "=== 数据流测试完成 ==="