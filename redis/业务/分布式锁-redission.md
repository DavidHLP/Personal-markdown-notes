# 分布式锁-redissionc

基于Redis的SETNX命令实现的分布式锁存在以下几个关键问题：

1. 不可重入性
**问题描述**：当前实现的锁不支持重入，即在持有锁的线程中无法再次获取同一把锁。
**影响**：
- 在嵌套调用场景下会导致死锁
- 限制了代码的灵活性，增加了开发复杂度
**对比**：
- Java内置的synchronized和ReentrantLock都支持可重入
- 可重入性是避免死锁的重要特性

2. 缺乏重试机制
**问题描述**：当前实现在获取锁失败时直接返回失败，没有提供重试机制。
**期望行为**：
- 在锁竞争时能够自动重试
- 支持配置最大重试次数和重试间隔
- 提供指数退避等重试策略

3. 锁超时释放的可靠性问题
**问题描述**：虽然通过设置过期时间可以防止死锁，但仍然存在以下问题：
**风险点**：
- 业务执行时间超过锁的超时时间，导致锁提前释放
- 虽然通过Lua脚本避免了误删其他线程的锁，但业务逻辑可能被重复执行
- 难以确定合理的超时时间设置

4. 主从一致性问题
**问题描述**：在Redis主从架构下，主从同步存在延迟，可能导致锁状态不一致。
**具体场景**：
1. 线程A在主节点获取锁成功
2. 主节点在同步数据给从节点前宕机
3. 从节点提升为新主节点
4. 线程B从新主节点获取到相同的锁

**后果**：同一把锁被两个线程同时持有，破坏了分布式锁的互斥性。

这些问题使得基于SETNX实现的分布式锁在生产环境中可能存在可靠性风险。

## Redisson概述

Redisson是一个在Redis的基础上实现的Java驻内存数据网格（In-Memory Data Grid）。它不仅提供了一系列的分布式的Java常用对象，还提供了许多分布式服务，其中就包含了各种分布式锁的实现。

Redission提供了分布式锁的多种多样的功能：
- 可重入锁（Reentrant Lock）
- 公平锁（Fair Lock）
- 联锁（MultiLock）
- 红锁（RedLock）
- 读写锁（ReadWriteLock）
- 信号量（Semaphore）
- 可过期性信号量（PermitExpirableSemaphore）
- 闭锁（CountDownLatch）

## Redisson分布式锁的实现

- 引入依赖

```xml
<dependency>
	<groupId>org.redisson</groupId>
	<artifactId>redisson</artifactId>
	<version>{根据你的Spring Boot 和 Java 版本选择}</version>
</dependency>
```