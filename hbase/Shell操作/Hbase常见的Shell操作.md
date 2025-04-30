## 创建表

**语法：** `create '表名', '列族名', ...`

```shell
create 'ORDER_INFO', 'C1', 'C2'
```

- 创建一个表，表名为 `ORDER_INFO`，列族为 `C1` 和 `C2`。
- 表可以有多个列族（Column Family）。

## 查看所有表

**命令：**

```shell
list
```

- 列出所有当前存在的表。

## 启用表

**语法：** `enable '表名'`

```shell
enable 'ORDER_INFO'
```

- 启用一个已禁用的表。

## 禁用表

**语法：** `disable '表名'`

```shell
disable 'ORDER_INFO'
```

- 禁用一个表，必须在删除前进行禁用。

## 删除表

**语法：** `drop '表名'`

```shell
drop 'ORDER_INFO'
```

- 删除一个已禁用的表。

## 显示表描述

**语法：** `describe '表名'`

```shell
describe 'ORDER_INFO'
```

**示例：**
```shell
hbase:031:0> describe 'ORDER_INFO'
Table ORDER_INFO is ENABLED                                                                                                                                                                                          
ORDER_INFO, {TABLE_ATTRIBUTES => {METADATA => {'hbase.store.file-tracker.impl' => 'DEFAULT'}}}                                                                                                                       
COLUMN FAMILIES DESCRIPTION                                                                                                                                                                                          
{NAME => 'C1', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

{NAME => 'C2', INDEX_BLOCK_ENCODING => 'NONE', VERSIONS => '1', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'ROW', 
IN_MEMORY => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536 B (64KB)'}                                                                                                                    

2 row(s)
Quota is disabled
Took 0.1003 seconds   
```

- 显示指定表的详细结构信息。

## 修改表结构

**语法：** `alter '表名', { NAME => '列族名', VERSIONS => 版本数 }`

```shell
alter 'ORDER_INFO', { NAME => 'C1', VERSIONS => 5 }
```

**示例：**
```shell
hbase:032:0> alter 'ORDER_INFO',{NAME => 'C1' , VERSIONS => '5'} 
Updating all regions with the new schema...
1/1 regions updated.
Done.
Took 1.8954 seconds           
```

- 修改表的结构，例如调整列族的版本数。

## 插入数据

**语法：** `put '表名', '行键', '列族:列', '值'`

```shell
put 'ORDER_INFO', 'row1', 'C1:order_id', '12345'
```

**示例：**
```shell
hbase:002:0> put 'ORDER_INFO', 'row1', 'C1:order_id', '12345'
Took 0.1551 seconds  
```

- 插入一行数据到表中，`order_id` 列的值为 `'12345'`。

## 获取数据

**语法：** `get '表名', '行键'`

```shell
get 'ORDER_INFO', 'row1'
```

- 获取指定行键的数据。
- 显示中文数据可用 `{FORMATTER => 'toString'}`。

```shell
get 'ORDER_INFO', 'row1', {FORMATTER => 'toString'}
```

**示例：**
```shell
hbase:039:0> get 'ORDER_INFO', 'row1', {FORMATTER => 'toString'}
COLUMN                                                 CELL                                                                                                                                                          
 C1:order_date                                         timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                                           
 C1:order_id                                           timestamp=2024-10-15T12:52:37.409, value=12345                                                                                                                
 C2:customer_name                                      timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                                                
 C2:customer_phone                                     timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                                                         
1 row(s)
Took 0.0159 seconds   
```

## 扫描表

避免扫描大表，以免程序运行时间过长、内存不足，甚至导致节点死机。

### 全表扫描

**语法：** `scan '表名'`

```shell
scan 'ORDER_INFO'
```

**示例：**
```shell
hbase:040:0> scan 'ORDER_INFO'
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
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
```

- 扫描整个表的数据，慎用，效率较低。

### 限定显示条数

**语法：** `scan '表名', {LIMIT => N}`

> LIMIT => N，N不是表示示例的行数而是rowkey的个数

```shell
scan 'ORDER_INFO', {LIMIT => 3}
```

**示例：**
```shell
hbase:041:0> scan 'ORDER_INFO' , {LIMIT => 3}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
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
3 row(s)
```

- 限定返回的记录条数。

### 指定查询某些列

**语法：** `scan '表名', {COLUMNS => ['列族:列', ...]}`

```shell
scan 'ORDER_INFO', {COLUMNS => ['C1:order_id', 'C2:customer_name']}
```

**示例：**
```shell
hbase:043:0> scan 'ORDER_INFO', {COLUMNS => ['C1:order_id', 'C2:customer_name']}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row2                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.518, value=67890                                                                                            
 row2                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.546, value=Bob                                                                                         
 row3                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.594, value=13579                                                                                            
 row3                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.632, value=Charlie                                                                                     
 row4                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.701, value=24680                                                                                            
 row4                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.744, value=David                                                                                       
 row5                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.798, value=11223                                                                                            
 row5                                                  column=C2:customer_name, timestamp=2024-10-15T12:53:27.341, value=Eva                                                                                         
5 row(s)
Took 0.0310 seconds   
```

- 只扫描指定的列。

### 根据 RowKey 前缀扫描

**语法：** `scan '表名', {ROWPREFIXFILTER => '前缀'}`

```shell
scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
```

**示例：**
```shell
hbase:044:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0073 seconds                                                                                                                                                                                                  
hbase:045:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
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
Took 0.0292 seconds  
```

- 根据 RowKey 的前缀来扫描表。

### 添加过滤器

**语法：** `scan '表名', {FILTER => "过滤条件"}`

```shell
scan 'ORDER_INFO', {FILTER => "SingleColumnValueFilter('C1', 'order_id', =, 'binary:12345')"}
```

**示例：**
```shell
hbase:046:0> scan 'ORDER_INFO', {FILTER => "SingleColumnValueFilter('C1', 'order_id', =, 'binary:12345')"}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.409, value=12345                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0614 seconds                                                                                                                                                                                                  
hbase:047:0> scan 'ORDER_INFO', {FILTER => "SingleColumnValueFilter('C1', 'order_id', =, 'binary:13579')"}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row3                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.615, value=2024-10-03                                                                                     
 row3                                                  column=C1:order_id, timestamp=2024-10-15T12:52:37.594, value=13579                                                                                            
 row3                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.632, value=Charlie                                                                                     
 row3                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.661, value=345-678-9012                                                                               
1 row(s)
Took 0.0067 seconds     
```

## 删除数据

**语法：** `delete '表名', '行键', '列族:列'`

```shell
delete 'ORDER_INFO', 'row1', 'C1:order_id'
```

**示例：**
```shell
hbase:048:0> put 'ORDER_INFO','row1','C1:order_id','11111'
Took 0.0079 seconds                                                                                                                                                                                                  
hbase:049:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:09.379, value=11111                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0123 seconds                                                                                                                                                                                                  
hbase:050:0> put 'ORDER_INFO','row1','C1:order_id','22222'
Took 0.0123 seconds                                                                                                                                                                                                  
hbase:051:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:25.601, value=22222                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0295 seconds                                                                                                                                                                                                  
hbase:052:0> delete 'ORDER_INFO','row1','C1:order_id'
Took 0.0210 seconds                                                                                                                                                                                                  
hbase:053:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:09.379, value=11111                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0132 seconds                                                                                                                                                                                                  
hbase:054:0> 
```

- 删除指定行中某列的数据。

> **注意：**
>
> - 执行 `delete` 时，如果当前行有多个版本的数据，它会删除最近的一个版本。
> - HBase 默认保留每列三个最近的版本。
> - 可以通过设置 `VERSIONS` 属性来控制保留的版本数量。

## 删除整行

**语法：** `deleteall '表名', '行键'`

```shell
deleteall 'ORDER_INFO', 'row1'
```

- 删除指定行的所有数据。

## 更新数据

- 直接使用 `put` 命令来覆盖已有值，达到更新的效果。

```shell
put 'ORDER_INFO', 'row1', 'C1:order_id', '67890'
```

## 计数行数

**语法：** `count '表名'`

```shell
count 'ORDER_INFO'
```

**示例：**
```shell
hbase:054:0> count 'ORDER_INFO'
5 row(s)
Took 0.0174 seconds                                                                                                                                                                                                  
=> 5
```

- 统计表中的行数。

## （增量计数）INCR 操作

在 HBase 中，可以使用 `INCR` 操作来创建并累加列值，适用于计数器等场景。

 **语法格式**

```shell
incr '表名', '行键', '列族:列限定符', 增量值
```

- `表名`：操作的表名称。
- `行键`：指定要操作的行键。
- `列族:列限定符`：指定要操作的列。
- `增量值`：递增的数值，正数表示增加，负数表示减少。

**创建与累加操作**

- **创建操作**：如果指定的列不存在，`INCR` 操作会首先创建该列，并将其初始值设置为指定的值（默认是 `0`），然后执行递增操作。

  ```shell
  incr 'ORDER_INFO', 'row1', 'C1:order_count', 20
  ```

  - 对行键为 `'row1'` 的 `C1:order_count` 列的值设置初始值为 `20`。

- **累加操作**：当列已经存在时，`INCR` 会对现有的值进行累加，增量可以是正数或负数。

  ```shell
  incr 'ORDER_INFO', 'row1', 'C1:order_count', 1
  ```

  - 对行键为 `'row1'` 的 `C1:order_count` 列的值进行递增，增量为 `1`。

- 该操作是原子的，适用于高并发环境下的计数需求。

- 如果某一列需要实现累加功能，必须使用 `INCR` 来创建对应的列。使用 `PUT` 创建的列无法实现累加。

 **获取计数器的值**

- 可以使用 `get_counter` 指令来获取计数器的值，注意使用 `get` 是无法获取计数器的数据的。

  ```shell
  get_counter 'ORDER_INFO', 'row1', 'C1:order_count'
  ```

**示例：**
```shell
hbase:060:0> incr 'ORDER_INFO', 'row1', 'C1:order_count', 20
COUNTER VALUE = 20
Took 0.0053 seconds                                                                                                                                                                                                  
hbase:061:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_count, timestamp=2024-10-15T13:25:40.085, value=\x00\x00\x00\x00\x00\x00\x00(                                                                 
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:09.379, value=11111                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0056 seconds                                                                                                                                                                                                  
hbase:062:0> scan 'ORDER_INFO', {ROWPREFIXFILTER => 'row1' , FORMATTER => 'toString'}
ROW                                                    COLUMN+CELL                                                                                                                                                   
 row1                                                  column=C1:order_count, timestamp=2024-10-15T13:25:40.085, value=(                                                                                      
 row1                                                  column=C1:order_date, timestamp=2024-10-15T12:52:37.435, value=2024-10-01                                                                                     
 row1                                                  column=C1:order_id, timestamp=2024-10-15T13:20:09.379, value=11111                                                                                            
 row1                                                  column=C2:customer_name, timestamp=2024-10-15T12:52:37.460, value=Alice                                                                                       
 row1                                                  column=C2:customer_phone, timestamp=2024-10-15T12:52:37.486, value=123-456-7890                                                                               
1 row(s)
Took 0.0089 seconds                                                                                                                                                                                                  
hbase:063:0> get_counter 'ORDER_INFO' , 'row1','C1:order_count'
COUNTER VALUE = 20
Took 0.0043 seconds                                                                                                                                                                                                  
hbase:064:0> 
```

## 查看表的所有快照

**语法：** `list_snapshots`

```shell
list_snapshots
```

**示例：**
```shell
hbase:065:0> list_snapshots
SNAPSHOT                                               TABLE + CREATION TIME + TTL(Sec)                                                                                                                              
 ORDER_INFO_SNAPSHOT                                   ORDER_INFO (2024-10-15 14:13:25 +0800) FOREVER                                                                                                                
1 row(s)
Took 0.0487 seconds                                                                                                                                                                                                  
=> ["ORDER_INFO_SNAPSHOT"]
hbase:066:0
```

- 列出所有的 HBase 表快照。

## 创建快照

**语法：** `snapshot '表名', '快照名'`

```shell
snapshot 'ORDER_INFO', 'ORDER_INFO_SNAPSHOT'
# create_snapshot 'ORDER_INFO', 'ORDER_INFO_SNAPSHOT'
# 这种创建也行
```

**示例：**
```shell
hbase:064:0> snapshot 'ORDER_INFO', 'ORDER_INFO_SNAPSHOT'
Took 2.4963 seconds                                                                                                                                                                                                  
hbase:065:0> list_snapshots
SNAPSHOT                                               TABLE + CREATION TIME + TTL(Sec)                                                                                                                              
 ORDER_INFO_SNAPSHOT                                   ORDER_INFO (2024-10-15 14:13:25 +0800) FOREVER                                                                                                                
1 row(s)
Took 0.0487 seconds                                                                                                                                                                                                  
=> ["ORDER_INFO_SNAPSHOT"]
hbase:066:0> 
```

- 创建表的快照，作为表当前状态的备份。

## 使用快照

**语法：** `clone_snapshot '快照名', '表名'`

```shell
clone_snapshot 'ORDER_INFO_SNAPSHOT', 'CLONE_ORDER_INFO'
```

**示例：**
```shell
hbase:001:0> clone_snapshot 'ORDER_INFO_SNAPSHOT', 'CLONE_ORDER_INFO'
Took 2.5459 seconds                                                                                                                                                                                                  
hbase:002:0> list
TABLE                                                                                                                                                                                                                
CLONE_ORDER_INFO                                                                                                                                                                                                     
ORDER_INFO                                                                                                                                                                                                           
2 row(s)
Took 0.0142 seconds                                                                                                                                                                                                  
=> ["CLONE_ORDER_INFO", "ORDER_INFO"]
hbase:003:0> 
```

## 通过快照恢复数据

**语法：** `restore_snapshot '快照名'`

> 会直接作用在所拍快照的表中

```shell
restore_snapshot 'ORDER_INFO_SNAPSHOT'
```

- 注意：恢复时，表需要先被禁用，可以使用如下命令：

```shell
disable 'ORDER_INFO'
restore_snapshot 'ORDER_INFO_SNAPSHOT'
```

**示例：**
```shell
hbase:007:0> restore_snapshot 'ORDER_INFO_SNAPSHOT'

ERROR: Table ORDER_INFO should be disabled!

For usage try 'help "restore_snapshot"'

Took 0.0209 seconds                                                                                                                                                                                                  
hbase:008:0> disable 'ORDER_INFO'
Took 0.3326 seconds                                                                                                                                                                                                  
hbase:009:0> restore_snapshot 'ORDER_INFO_SNAPSHOT'
Took 0.2898 seconds                                                                                                                                                                                                  
hbase:010:0> 
```


## 删除快照

**语法：** `delete_snapshot '快照名'`

```shell
delete_snapshot 'ORDER_INFO_SNAPSHOT'
```

- 删除指定的快照。

## 快照导出

- 如果需要将快照从一个集群导出到另一个集群，可以使用 ExportSnapshot 工具：

```shell
hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot -snapshot ORDER_INFO_SNAPSHOT -copy-to hdfs://mycluster/hbaseSnapshot -mappers 4
```
-snapshot：要导出的快照名称。
-copy-to：目标集群的 HDFS 路径。
-mappers：指定并行执行的 mapper 数量。

**示例：**
```shell
(base) root@hadoop-master1:/opt/hbase/bin# ./hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot -snapshot ORDER_INFO_SNAPSHOT -copy-to hdfs://mycluster/hbaseSnapshot -mappers 4
2024-10-15T14:43:57,762 INFO  [main] snapshot.ExportSnapshot: Verify the source snapshot's expiration status and integrity.
2024-10-15T14:44:00,202 INFO  [main] snapshot.ExportSnapshot: Copy Snapshot Manifest from hdfs://mycluster/hbase/.hbase-snapshot/ORDER_INFO_SNAPSHOT to hdfs://mycluster/hbaseSnapshot/.hbase-snapshot/.tmp/ORDER_INFO_SNAPSHOT
2024-10-15T14:44:01,187 INFO  [main] client.ConfiguredRMFailoverProxyProvider: Failing over to rm2
2024-10-15T14:44:01,290 INFO  [main] mapreduce.JobResourceUploader: Disabling Erasure Coding for path: /tmp/hadoop-yarn/staging/root/.staging/job_1728971830625_0001
2024-10-15T14:44:02,566 INFO  [main] snapshot.ExportSnapshot: Loading Snapshot 'ORDER_INFO_SNAPSHOT' hfile list
2024-10-15T14:44:02,657 INFO  [main] mapreduce.JobSubmitter: number of splits:3
2024-10-15T14:44:02,808 INFO  [main] mapreduce.JobSubmitter: Submitting tokens for job: job_1728971830625_0001
2024-10-15T14:44:02,811 INFO  [main] mapreduce.JobSubmitter: Executing with tokens: []
2024-10-15T14:44:05,190 INFO  [main] conf.Configuration: resource-types.xml not found
2024-10-15T14:44:05,190 INFO  [main] resource.ResourceUtils: Unable to find 'resource-types.xml'.
2024-10-15T14:44:05,671 INFO  [main] impl.YarnClientImpl: Submitted application application_1728971830625_0001
2024-10-15T14:44:05,727 INFO  [main] mapreduce.Job: The url to track the job: http://hadoop-master2:8088/proxy/application_1728971830625_0001/
2024-10-15T14:44:05,727 INFO  [main] mapreduce.Job: Running job: job_1728971830625_0001
2024-10-15T14:44:15,854 INFO  [main] mapreduce.Job: Job job_1728971830625_0001 running in uber mode : false
2024-10-15T14:44:15,855 INFO  [main] mapreduce.Job:  map 0% reduce 0%
2024-10-15T14:44:25,930 INFO  [main] mapreduce.Job:  map 33% reduce 0%
2024-10-15T14:44:26,933 INFO  [main] mapreduce.Job:  map 67% reduce 0%
2024-10-15T14:44:27,936 INFO  [main] mapreduce.Job:  map 100% reduce 0%
2024-10-15T14:44:28,942 INFO  [main] mapreduce.Job: Job job_1728971830625_0001 completed successfully
2024-10-15T14:44:28,992 INFO  [main] mapreduce.Job:             Total time spent by all maps in occupied slots (ms)=26453
                Total time spent by all reduces in occupied slots (ms)=0
                Total time spent by all map tasks (ms)=26453
                Total vcore-milliseconds taken by all map tasks=26453
                Total megabyte-milliseconds taken by all map tasks=27087872
        Map-Reduce Framework
                Map input records=3
                Map output records=0
                Input split bytes=594
                Spilled Records=0
                Failed Shuffles=0
                Merged Map outputs=0
                GC time elapsed (ms)=233
                CPU time spent (ms)=2660
                Physical memory (bytes) snapshot=1093185536
                Virtual memory (bytes) snapshot=7706193920
                Total committed heap usage (bytes)=1143996416
                Peak Map Physical memory (bytes)=372260864
                Peak Map Virtual memory (bytes)=2569465856
        org.apache.hadoop.hbase.snapshot.ExportSnapshot$Counter
                BYTES_COPIED=15707
                BYTES_EXPECTED=15707
                BYTES_SKIPPED=0
                COPY_FAILED=0
                FILES_COPIED=3
                FILES_SKIPPED=0
                MISSING_FILES=0
        File Input Format Counters 
                Bytes Read=0
        File Output Format Counters 
                Bytes Written=0
2024-10-15T14:44:28,993 INFO  [main] snapshot.ExportSnapshot: Finalize the Snapshot Export
2024-10-15T14:44:29,014 INFO  [main] snapshot.ExportSnapshot: Verify the exported snapshot's expiration status and integrity.
2024-10-15T14:44:29,772 INFO  [main] snapshot.ExportSnapshot: Export Completed: ORDER_INFO_SNAPSHOT
```

## 合并区域（Regions）

**语法：** `merge_region 'region1', 'region2'`

- 合并两个指定的 Region。
- 需先通过 `list_regions '表名'` 找到具体的 Region 名称。

## 分裂区域（Regions）

**语法：** `split '表名', '分裂键'`

```shell
split 'ORDER_INFO', 'row3'
```

- 将表按照指定的行键进行分裂，用于数据均衡。

## major_compact

**语法：** `major_compact '表名'`

- 对指定表进行 major compaction，合并所有存储文件。

## minor_compact

**语法：** `compact '表名'`

- 对指定表进行 minor compaction，合并部分存储文件，释放 HFile。

## 权限管理

**赋予权限：** `grant '用户', '权限', '表名', '列族', '列'`

```shell
grant 'admin', 'RWXCA', 'ORDER_INFO'
```

- 给用户赋予读写、执行等权限。

**收回权限：** `revoke '用户', '表名', '列族', '列'`

```shell
revoke 'admin', 'ORDER_INFO'
```

- 收回用户权限。

## 备份与恢复

- 可以使用 `exportSnapshot` 和 `restore_snapshot` 工具来备份与恢复表数据。

## 执行 Command 文件

- 使用 HBase Shell 运行上传的 command 文件。

```shell
hbase shell /path/to/command-file.txt
```

- 确保文件中包含合法的 HBase Shell 命令。

## 导入导出数据

**语法：** 使用 `bulkload` 工具。

- `importtsv` 可以用于将 TSV 格式的数据文件导入 HBase 表。
- `export` 可以将表中的数据导出为 HDFS 中的文本文件。

```shell
./hbase org.apache.hadoop.hbase.mapreduce.ImportTsv \
-Dimporttsv.separator=',' \
-Dimporttsv.columns=HBASE_ROW_KEY,cf1:name,cf1:age,cf1:city,cf1:phone,cf1:email,cf2:occupation,cf2:company,cf2:salary,cf2:experience,cf2:department,cf3:hobby,cf3:favorite_color,cf3:sport,cf3:pet,cf3:music,cf4:address,cf4:zipcode,cf4:state,cf4:country,cf4:continent,cf5:social_media,cf5:website,cf5:blog,cf5:subscribed,cf5:membership \
USER_INFO /hbasedata/hbase_large_million_dataset.csv
```

### 示例

```shell
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=HBASE_ROW_KEY,C1:order_id,C2:customer_name 'ORDER_INFO' /path/to/data.tsv
```

## 大量数据的计数统计

对于大规模数据集，可以使用 **MapReduce** 任务来对表中的行数进行统计，以提高效率。例如使用 `rowcounter` 工具。

```shell
hbase org.apache.hadoop.hbase.mapreduce.RowCounter 'ORDER_INFO'
```

## 过滤器

在 HBase 中，过滤器用于限制扫描或获取数据时返回的结果集，帮助提高查询效率，减少不必要的数据传输。

**语法：**
  - 其实在hbase shell中，执行的ruby脚本，背后还是调用hbase提供的Java API
  - 在HBase中有很多的多过滤器，语法格式看起来会比较复杂，所以重点理解这个语法是什么意思
  - 过滤器在hbaseshell中是使用一个表达式来描述，在Java里面new各种对象

**解释：**
```shell
scan "ORDER_INFO" , {FILTER => "RowFilter（=,'binary:02602f66-adc7-40d4-8485-76b5632b5b53'）"，COLUMNS => ['C1:STATUS' 'C1:PAYWAY'], FORMATTER =>'toString'}
```
- “RowFilter（=,"binary:02602f66-adc7-40d4-8485-76b5632b5b53'）”这个就是一个表达式
  - RowFilter就是JavaAPi中Filter的构造器名称
  - 可以理解为RowFilter0就是创建一个过滤器对象
  - =是JRuby一个特殊记号，表示是一个比较运算符，还可以是>、<、>=...
  - binary:02602f66-adc7-4dd4-8485-76b5632b5b53是一个比较器的表达式，为了方便大家理解，可以将比较器理解为值，binary:xxxox表示直接和值进行毕节



### 按行键（RowKey）过滤器

1. **PrefixFilter**：根据行键的前缀进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "PrefixFilter('row1')"}
   ```
   - 只返回行键以 `'row1'` 开头的行。

2. **RowFilter**：基于行键的比较进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "RowFilter(=, 'binary:row1')"}
   ```
   - 只返回行键等于 `'row1'` 的行。

3. **InclusiveStopFilter**：扫描到指定的行键时停止。
   ```shell
   scan 'ORDER_INFO', {FILTER => "InclusiveStopFilter('row3')"}
   ```
   - 扫描数据，直到行键为 `'row3'` 时停止。

4. **RandomRowFilter**：随机返回部分行数据。
   ```shell
   scan 'ORDER_INFO', {FILTER => "RandomRowFilter(0.5)"}
   ```
   - 以 50% 的概率返回表中的行数据。

### 列过滤器

1. **SingleColumnValueFilter**：根据指定列的值进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "SingleColumnValueFilter('C1', 'order_id', =, 'binary:12345')"}
   ```
   - 只返回 `order_id` 列值为 `12345` 的行。

2. **ColumnPrefixFilter**：根据列名前缀进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "ColumnPrefixFilter('order')"}
   ```
   - 只返回列名前缀为 `'order'` 的列。

3. **QualifierFilter**：基于列限定符（Qualifier）的比较进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "QualifierFilter(=, 'binary:order_id')"}
   ```
   - 只返回列限定符等于 `'order_id'` 的列。

4. **FamilyFilter**：基于列族的比较进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "FamilyFilter(=, 'binary:C1')"}
   ```
   - 只返回列族等于 `'C1'` 的数据。

5. **DependentColumnFilter**：当指定列存在时，才返回整行数据。
   ```shell
   scan 'ORDER_INFO', {FILTER => "DependentColumnFilter('C1', 'order_id')"}
   ```
   - 只返回包含 `C1:order_id` 列的行。

### 其他类型过滤器

1. **PageFilter**：用于分页查询，限制返回的行数。
   ```shell
   scan 'ORDER_INFO', {FILTER => "PageFilter(10)"}
   ```
   - 只返回前 10 行数据。

2. **ValueFilter**：根据列值进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "ValueFilter(=, 'binary:12345')"}
   ```
   - 只返回值为 `12345` 的列。

3. **TimestampsFilter**：根据时间戳进行过滤。
   ```shell
   scan 'ORDER_INFO', {FILTER => "TimestampsFilter([1631022245123, 1631022245124])"}
   ```
   - 只返回匹配指定时间戳的数据。

4. **KeyOnlyFilter**：只返回行键，不返回列值。
   ```shell
   scan 'ORDER_INFO', {FILTER => "KeyOnlyFilter()"}
   ```
   - 只返回行键，用于仅检查行存在与否。

5. **SkipFilter**：跳过包含特定条件的行。
   ```shell
   scan 'ORDER_INFO', {FILTER => "SkipFilter(SingleColumnValueFilter('C1', 'order_id', =, 'binary:12345'))"}
   ```
   - 跳过 `order_id` 等于 `'12345'` 的行。

6. **FirstKeyOnlyFilter**：每行只返回第一个键值对。
   ```shell
   scan 'ORDER_INFO', {FILTER => "FirstKeyOnlyFilter()"}
   ```
   - 用于只获取每行的第一个键值对，通常用于行计数。

### 组合过滤器

可以使用 `FilterList` 组合多个过滤器。

```shell
scan 'ORDER_INFO', {FILTER => "FilterList(AND, SingleColumnValueFilter('C1', 'order_id', =, 'binary:12345'), PrefixFilter('row1'))"}
```

- 组合使用多个过滤条件，返回符合所有条件的行。
- 可以使用 `AND` 或 `OR` 逻辑操作符来控制组合过滤器的行为。