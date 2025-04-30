## Hbase Shell 管理操作

### status

- 显示服务器集群状态

**示例：**
```shell
hbase:001:0> status
1 active master, 2 backup masters, 3 servers, 0 dead, 1.0000 average load
Took 0.3839 seconds  
```

### whoami

- 显示Hbase当前的用户

**示例：**
```shell
hbase:002:0> whoami
root (auth:SIMPLE)
    groups: root
Took 0.0472 seconds
```

### list

- 显示当前所有的表

**示例：**
```shell
hbase:003:0> list
TABLE                                                                                                                                                                                                                
CLONE_ORDER_INFO                                                                                                                                                                                                     
ORDER_INFO                                                                                                                                                                                                           
2 row(s)
Took 0.0294 seconds                                                                                                                                                                                                  
=> ["CLONE_ORDER_INFO", "ORDER_INFO"]
```

### count

- 统计指定表的记录数
- 不对大数据量的表使用，会占用大量资源

**示例：**
```shell
hbase:006:0> count 'ORDER_INFO'
5 row(s)
Took 0.0544 seconds                                                                                                                                                                                                  
=> 5
```

### describe

- 展示表的结构信息

**示例：**
```shell
hbase:007:0> describe 'ORDER_INFO'
Table ORDER_INFO is ENABLED                                                                                                                                                                                          
ORDER_INFO, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}                                                                                                                       
COLUMN FAMILIES DESCRIPTION                                                                                                                                                                                          
{NAME => 'C1', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '5', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C2', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

2 row(s)
Quota is disabled
Took 0.1130 seconds 
```

### exists

- 检查是否存在这个表，适用于表量十分大

**示例：**
```shell
hbase:008:0> exists 'ORDER_INFO'
Table ORDER_INFO does exist                                                                                                                                                                                          
Took 0.0150 seconds                                                                                                                                                                                                  
=> true
hbase:009:0> exists 'ORDER_INFO1'
Table ORDER_INFO1 does not exist                                                                                                                                                                                     
Took 0.0066 seconds                                                                                                                                                                                                  
=> false
```

### is_enabled / is_disabled

- 检测表是否启用或者禁用

**示例：**
```shell
hbase:010:0> is_enabled 'ORDER_INFO'
true                                                                                                                                                                                                                 
Took 0.0312 seconds                                                                                                                                                                                                  
=> true
hbase:011:0> is_disabled 'ORDER_INFO'
false                                                                                                                                                                                                                
Took 0.0099 seconds                                                                                                                                                                                                  
=> false
hbase:012:0> 
```

### alter

- alter可以改变表列族的模式

**示例：**
```shell
hbase:014:0> create 'ALTER_TEST','C1','C2'
Created table ALTER_TEST
Took 0.6650 seconds                                                                                                                                                                                                  
=> Hbase::Table - ALTER_TEST
hbase:015:0> describe 'ALTER_TEST'
Table ALTER_TEST is ENABLED                                                                                                                                                                                          
ALTER_TEST, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}                                                                                                                       
COLUMN FAMILIES DESCRIPTION                                                                                                                                                                                          
{NAME => 'C1', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C2', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

2 row(s)
Quota is disabled
Took 0.0575 seconds                                                                                                                                                                                                  
hbase:016:0> alter 'ALTER_TEST','C3'
Updating all regions with the new schema...
1/1 regions updated.
Done.
Took 1.8192 seconds                                                                                                                                                                                                  
hbase:017:0> describe 'ALTER_TEST'
Table ALTER_TEST is ENABLED                                                                                                                                                                                          
ALTER_TEST, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}                                                                                                                       
COLUMN FAMILIES DESCRIPTION                                                                                                                                                                                          
{NAME => 'C1', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C2', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C3', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

3 row(s)
Quota is disabled
Took 0.0927 seconds                                                                                                                                                                                                  
hbase:018:0> alter 'ALTER_TEST','delete' => 'C3'
Updating all regions with the new schema...
1/1 regions updated.
Done.
Took 1.7897 seconds                                                                                                                                                                                                  
hbase:019:0> describe 'ALTER_TEST'
Table ALTER_TEST is ENABLED                                                                                                                                                                                          
ALTER_TEST, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}                                                                                                                       
COLUMN FAMILIES DESCRIPTION                                                                                                                                                                                          
{NAME => 'C1', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C2', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

2 row(s)
Quota is disabled
Took 0.0699 seconds
```

### disable / enable

- 禁用和启用一张表

**示例：**
```shell
hbase:020:0> disable 'ALTER_TEST'
Took 0.3761 seconds                                                                                                                                                                                                  
hbase:021:0> enable 'ALTER_TEST'
Took 0.6413 seconds
```

### drop

- 删除一张表（只能删除已经禁用的表）

**示例：**
```shell
hbase:022:0> disable 'ALTER_TEST'
Took 0.3607 seconds                                                                                                                                                                                                  
hbase:023:0> drop 'ALTER_TEST'
Took 0.3635 seconds  
```

### truncate

- 清空表数据：禁用表->删除表->创建表
- 在运行这个之前请记得备份拍快照

**示例：**
```shell
hbase:003:0> scan 'CLONE_ORDER_INFO'
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_count, timestamp=2024-10-15T13:25:40.085, value=\x00\x00\x00\x00\x00\x00\x00(                                                                 
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:09.379, value=11111                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
 row2                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.531, value=2024-10-02                                                                                     
 row2                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.518, value=67890                                                                                            
 row2                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.546, value=Bob                                                                                         
 row2                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.573, value=234-567-8901                                                                               
 row3                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.615, value=2024-10-03                                                                                     
 row3                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.594, value=13579                                                                                            
 row3                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.632, value=Charlie                                                                                     
 row3                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.661, value=345-678-9012                                                                               
 row4                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.726, value=2024-10-04                                                                                     
 row4                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.701, value=24680                                                                                            
 row4                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.744, value=David                                                                                       
 row4                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.768, value=456-789-0123                                                                               
 row5                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.810, value=2024-10-05                                                                                     
 row5                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.798, value=11223                                                                                            
 row5                                                  column=C2:customer_name, timestamp=2024-10-15T12:53:27.341, value=Eva                                                                                         
 row5                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.842, value=567-890-1234                                                                               
5 row(s)
Took 0.2718 seconds                                                                                                                                                                                                  
hbase:004:0> truncate 'CLONE_ORDER_INFO'
Truncating 'CLONE_ORDER_INFO' table (it may take a while):
Disabling table...
Truncating table...
Took 1.6162 seconds                                                                                                                                                                                                  
hbase:005:0> scan 'CLONE_ORDER_INFO'
ROW                                                    COLUMN+CELL                                                                                                                                                   
0 row(s)
Took 0.6254 seconds     
```