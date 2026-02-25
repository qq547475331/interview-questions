---
title: Kafka
weight: 6
---

# Kafka 面试题

## 1. Kafka 核心概念

**问题：** 解释 Kafka 的核心概念。

**答案：**

| 概念 | 说明 |
|------|------|
| **Producer** | 消息生产者，向 Topic 发送消息 |
| **Consumer** | 消息消费者，从 Topic 订阅消息 |
| **Broker** | Kafka 服务器节点，负责存储和转发消息 |
| **Topic** | 消息主题，逻辑上的消息分类 |
| **Partition** | 分区，Topic 的物理分片，实现水平扩展 |
| **Offset** | 消息在分区中的唯一标识 |
| **Consumer Group** | 消费者组，组内消费者共同消费一个 Topic |
| **ZooKeeper/KRaft** | 集群协调服务（新版使用 KRaft） |

---

## 2. Kafka 高可用

**问题：** Kafka 如何保证高可用？

**答案：**

**副本机制：**
- 每个 Partition 有多个副本（Leader + Follower）
- Leader 负责读写，Follower 同步数据
- Leader 故障时自动选举新 Leader

```bash
# 创建 Topic，3 个分区，3 个副本
kafka-topics.sh --create \
  --topic my-topic \
  --partitions 3 \
  --replication-factor 3 \
  --bootstrap-server localhost:9092
```

**ACK 机制：**
```java
producerProps.put("acks", "all");  // 0, 1, all
```
- `acks=0`：不等待确认，最快但不安全
- `acks=1`：等待 Leader 确认
- `acks=all`：等待所有 ISR 确认，最安全

---

## 3. Kafka 消息保证

**问题：** Kafka 如何保证消息不丢失？

**答案：**

**生产者端：**
```java
// 开启幂等性
props.put("enable.idempotence", "true");

// 事务支持
props.put("transactional.id", "my-producer");
Producer<String, String> producer = new KafkaProducer<>(props);
producer.initTransactions();
producer.beginTransaction();
producer.send(record);
producer.commitTransaction();
```

**消费者端：**
```java
// 手动提交 Offset
props.put("enable.auto.commit", "false");

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    for (ConsumerRecord<String, String> record : records) {
        // 处理消息
        process(record);
    }
    // 处理完成后再提交
    consumer.commitSync();
}
```

---

## 4. Kafka 性能优化

**问题：** 如何优化 Kafka 性能？

**答案：**

**生产者优化：**
```java
props.put("batch.size", 16384);        // 批量发送大小
props.put("linger.ms", 5);             // 发送延迟
props.put("compression.type", "lz4");  // 压缩算法
props.put("buffer.memory", 33554432);  // 缓冲区大小
```

**消费者优化：**
```java
props.put("fetch.min.bytes", 50000);   // 最小获取字节数
props.put("fetch.max.wait.ms", 500);   // 最大等待时间
props.put("max.poll.records", 500);    // 单次最大拉取记录数
```

**分区策略：**
- 根据业务特点选择分区数
- 避免热点分区
- 使用自定义分区器

---

## 5. Kafka 与 RabbitMQ 对比

**问题：** Kafka 和 RabbitMQ 有什么区别？

**答案：**

| 特性 | Kafka | RabbitMQ |
|------|-------|----------|
| **设计目标** | 高吞吐流处理 | 通用消息队列 |
| **消息模型** | 发布-订阅 | 多种模式（点对点、发布订阅） |
| **吞吐量** | 百万级/秒 | 万级/秒 |
| **消息持久化** | 磁盘持久化 | 内存+磁盘 |
| **消息顺序** | 分区内有序 | 队列内有序 |
| **消费模式** | Pull | Push/Pull |
| **适用场景** | 日志收集、流处理 | 企业应用集成 |
