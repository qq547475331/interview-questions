---
title: RabbitMQ
weight: 7
---

# RabbitMQ 面试题

## 1. RabbitMQ 核心概念

**问题：** 解释 RabbitMQ 的核心概念。

**答案：**

| 概念 | 说明 |
|------|------|
| **Producer** | 消息生产者 |
| **Consumer** | 消息消费者 |
| **Queue** | 消息队列，存储消息的缓冲区 |
| **Exchange** | 交换机，接收生产者消息并路由到队列 |
| **Binding** | 绑定，连接 Exchange 和 Queue 的规则 |
| **Routing Key** | 路由键，Exchange 根据它决定消息路由 |

---

## 2. Exchange 类型

**问题：** RabbitMQ 有哪些 Exchange 类型？

**答案：**

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| **Direct** | 精确匹配 Routing Key | 点对点消息 |
| **Fanout** | 广播到所有绑定的队列 | 发布订阅 |
| **Topic** | 模式匹配 Routing Key | 复杂路由 |
| **Headers** | 根据消息 Headers 匹配 | 多条件路由 |

```java
// Direct Exchange
channel.exchangeDeclare("direct_logs", "direct");
channel.queueBind(queueName, "direct_logs", "error");

// Topic Exchange
channel.exchangeDeclare("topic_logs", "topic");
channel.queueBind(queueName, "topic_logs", "kern.*");
```

---

## 3. 消息可靠性

**问题：** RabbitMQ 如何保证消息可靠性？

**答案：**

**生产者确认：**
```java
// 开启确认模式
channel.confirmSelect();

// 同步确认
channel.basicPublish("", "queue", null, message.getBytes());
if (channel.waitForConfirms()) {
    System.out.println("消息发送成功");
}

// 异步确认
channel.addConfirmListener(
    (deliveryTag, multiple) -> {
        System.out.println("消息确认: " + deliveryTag);
    },
    (deliveryTag, multiple) -> {
        System.out.println("消息丢失: " + deliveryTag);
    }
);
```

**消息持久化：**
```java
// 队列持久化
channel.queueDeclare("queue", true, false, false, null);

// 消息持久化
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
    .deliveryMode(2)  // 持久化
    .build();
channel.basicPublish("", "queue", props, message.getBytes());
```

**消费者确认：**
```java
// 手动确认
channel.basicConsume("queue", false, (consumerTag, delivery) -> {
    // 处理消息
    processMessage(delivery.getBody());
    
    // 确认消息
    channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
    
    // 或拒绝消息
    // channel.basicNack(deliveryTag, false, true);
}, consumerTag -> {});
```

---

## 4. 死信队列

**问题：** 什么是死信队列？如何实现？

**答案：**

**死信来源：**
- 消息被拒绝（basic.reject/basic.nack）且 requeue=false
- 消息过期（TTL）
- 队列达到最大长度

```java
// 声明死信交换机
channel.exchangeDeclare("dlx.exchange", "direct");
channel.queueDeclare("dlx.queue", true, false, false, null);
channel.queueBind("dlx.queue", "dlx.exchange", "dlx.routing.key");

// 声明主队列，设置死信参数
Map<String, Object> args = new HashMap<>();
args.put("x-dead-letter-exchange", "dlx.exchange");
args.put("x-dead-letter-routing-key", "dlx.routing.key");
args.put("x-message-ttl", 60000);  // 消息过期时间
args.put("x-max-length", 1000);     // 队列最大长度

channel.queueDeclare("main.queue", true, false, false, args);
```

---

## 5. 延迟队列

**问题：** RabbitMQ 如何实现延迟队列？

**答案：**

**方式一：TTL + 死信队列**
```java
// 延迟交换机
channel.exchangeDeclare("delay.exchange", "direct");

// 延迟队列（设置 TTL）
Map<String, Object> delayArgs = new HashMap<>();
delayArgs.put("x-dead-letter-exchange", "target.exchange");
delayArgs.put("x-message-ttl", 5000);  // 5秒延迟

channel.queueDeclare("delay.queue", true, false, false, delayArgs);
channel.queueBind("delay.queue", "delay.exchange", "delay.key");
```

**方式二：延迟队列插件**
```java
// 声明延迟交换机
Map<String, Object> args = new HashMap<>();
args.put("x-delayed-type", "direct");
channel.exchangeDeclare("delayed.exchange", "x-delayed-message", true, false, args);

// 发送延迟消息
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
    .headers(Collections.singletonMap("x-delay", 5000))  // 5秒延迟
    .build();
channel.basicPublish("delayed.exchange", "routing.key", props, message.getBytes());
```

---

## 6. RabbitMQ 集群

**问题：** RabbitMQ 集群如何工作？

**答案：**

**集群模式：**
- 普通集群：元数据共享，队列数据只存在于一个节点
- 镜像队列：队列数据在多个节点同步

```bash
# 查看集群状态
rabbitmqctl cluster_status

# 加入集群
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
```

**镜像队列配置：**
```bash
# 设置镜像策略
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
```

---

## 7. RabbitMQ 与 Kafka 对比

**问题：** RabbitMQ 和 Kafka 如何选择？

**答案：**

| 场景 | 推荐 | 原因 |
|------|------|------|
| 复杂路由 | RabbitMQ | Exchange 路由灵活 |
| 事务消息 | RabbitMQ | 原生支持事务 |
| 延迟消息 | RabbitMQ | 支持延迟队列 |
| 高吞吐 | Kafka | 百万级 QPS |
| 消息回溯 | Kafka | 支持按 Offset 消费 |
| 流处理 | Kafka | 与流处理框架集成好 |

---

## 8. RabbitMQ 可靠性传输

**问题：** RabbitMQ 如何保证消息不丢失？（从生产者、交换机、队列、消费者四个维度回答）

**答案：**

**1. 生产者端（Confirm 机制）**

```java
// 开启 Confirm 模式
channel.confirmSelect();

// 同步确认
channel.basicPublish("", "queue", null, message.getBytes());
if (channel.waitForConfirms()) {
    System.out.println("消息发送成功");
} else {
    // 发送失败，重试或记录日志
}

// 异步确认（推荐）
channel.addConfirmListener(
    (deliveryTag, multiple) -> {
        // 消息确认成功
        System.out.println("消息已确认: " + deliveryTag);
    },
    (deliveryTag, multiple) -> {
        // 消息丢失，需要重发
        System.out.println("消息丢失: " + deliveryTag);
    }
);
```

**2. 交换机端（持久化）**

```java
// 声明持久化交换机
channel.exchangeDeclare("myExchange", "direct", true);  // 第三个参数 durable=true
```

**3. 队列端（持久化 + 镜像）**

```java
// 声明持久化队列
channel.queueDeclare("myQueue", true, false, false, null);
// 参数：队列名、持久化、独占、自动删除、其他参数

// 消息持久化
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
    .deliveryMode(2)  // 1=非持久化，2=持久化
    .build();
channel.basicPublish("", "myQueue", props, message.getBytes());

// 镜像队列（集群环境）
Map<String, Object> args = new HashMap<>();
args.put("x-ha-policy", "all");  // 所有节点镜像
channel.queueDeclare("haQueue", true, false, false, args);
```

**4. 消费者端（手动 ACK）**

```java
// 关闭自动确认
channel.basicConsume("myQueue", false, (consumerTag, delivery) -> {
    try {
        // 处理消息
        processMessage(delivery.getBody());
        
        // 手动确认（确认当前消息）
        channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
        
        // 或者批量确认（确认所有小于等于当前 deliveryTag 的消息）
        // channel.basicAck(delivery.getEnvelope().getDeliveryTag(), true);
    } catch (Exception e) {
        // 处理失败，拒绝消息
        // requeue=false 进入死信队列，requeue=true 重新入队
        channel.basicNack(delivery.getEnvelope().getDeliveryTag(), false, true);
        
        // 或者单独拒绝单条消息
        // channel.basicReject(delivery.getEnvelope().getDeliveryTag(), false);
    }
}, consumerTag -> {});
```

**可靠性总结：**

| 环节 | 机制 | 说明 |
|------|------|------|
| 生产者 | Confirm | 确保消息到达交换机 |
| 交换机 | 持久化 | 重启后交换机不丢失 |
| 队列 | 持久化 + 镜像 | 消息落盘 + 多副本 |
| 消费者 | 手动 ACK | 确保消息被正确处理 |

---

## 9. Kafka 零拷贝与顺序写入

**问题：** 为什么 Kafka 的写入性能极高？请从"零拷贝（Zero-copy）"和"顺序写入"角度分析。

**答案：**

**1. 顺序写入（Sequential Write）**

传统磁盘随机写入慢，但顺序写入性能接近内存：

```
随机写入：寻道时间 + 旋转延迟 + 传输时间 ≈ 10ms
顺序写入：无寻道时间，连续写入 ≈ 100MB/s（HDD），数GB/s（SSD）
```

Kafka 的日志文件是追加写入：
```
partition-0.log:
[消息1][消息2][消息3][消息4]...  持续追加到文件末尾
```

**2. 零拷贝（Zero-copy）**

**传统数据传输（4 次拷贝，4 次上下文切换）：**

```
磁盘 → 内核缓冲区 → 用户缓冲区 → Socket 缓冲区 → 网卡
```

1. 磁盘 → 内核缓冲区（DMA 拷贝）
2. 内核缓冲区 → 用户缓冲区（CPU 拷贝）
3. 用户缓冲区 → Socket 缓冲区（CPU 拷贝）
4. Socket 缓冲区 → 网卡（DMA 拷贝）

**Kafka 零拷贝（2 次拷贝，2 次上下文切换）：**

```java
// 使用 Java NIO 的 transferTo
FileChannel.transferTo(position, count, socketChannel);

// 底层使用 sendfile 系统调用
sendfile(socket, file, offset, count);
```

数据流：
```
磁盘 → 内核缓冲区 → 网卡
```

1. 磁盘 → 内核缓冲区（DMA 拷贝）
2. 内核缓冲区 → 网卡（DMA 拷贝，通过 gather 操作）

**性能对比：**

| 方式 | 拷贝次数 | 上下文切换 | 吞吐量 |
|------|----------|-----------|--------|
| 传统方式 | 4 次 | 4 次 | 低 |
| 零拷贝 | 2 次 | 2 次 | 高（数倍提升） |

**3. 其他优化：**

```
- 批量处理：一批消息一次写入
- 压缩：减少网络传输和磁盘占用
- 分区并行：多个分区同时写入
```

---

## 10. Kafka 消息堆积监控与扩容

**问题：** 线上环境突然出现 Kafka 消息大规模堆积，作为运维，你会从哪些维度进行监控和扩容？

**答案：**

**监控维度：**

```bash
# 1. 查看消费者组延迟
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group my-consumer-group

# 关键指标：
# CURRENT-OFFSET: 当前消费位置
# LOG-END-OFFSET: 最新消息位置
# LAG: 延迟消息数（重点关注）

# 2. 查看 Topic 各分区状态
kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --topic my-topic

# 3. 查看消费者组成员
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group my-consumer-group --members
```

**排查步骤：**

```
1. 确认堆积范围
   - 所有分区都堆积？还是部分分区？
   - 如果是部分分区 → 可能是热点 Key 问题

2. 检查消费者状态
   - 消费者是否存活？
   - 消费者数量是否足够？
   - 消费者是否有异常日志？

3. 检查消费速度
   - 单条消息处理时间是否过长？
   - 是否有阻塞操作（如数据库查询）？

4. 检查生产者
   - 是否有突发流量？
   - 消息体是否突然变大？
```

**解决方案：**

```bash
# 1. 临时扩容消费者（消费者数 <= 分区数）
# 增加消费者实例，提高并行度

# 2. 增加分区（需要提前规划，不能在线减少）
kafka-topics.sh --bootstrap-server localhost:9092 \
  --alter --topic my-topic --partitions 12

# 3. 跳过部分消息（紧急恢复）
# 将消费者偏移量跳到最新
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --group my-consumer-group --topic my-topic --reset-offsets --to-latest --execute

# 4. 降低生产者速率（如果有流控）
# 调整生产者参数
# batch.size, linger.ms 等
```

**预防措施：**

```yaml
# 1. 监控告警
- name: Kafka Consumer Lag
  rules:
  - alert: KafkaConsumerLagHigh
    expr: kafka_consumer_group_lag > 10000
    for: 5m
    annotations:
      summary: "Kafka consumer lag is high"

# 2. 自动扩容（K8s HPA）
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kafka-consumer-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kafka-consumer
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: External
    external:
      metric:
        name: kafka_consumer_lag
      target:
        type: AverageValue
        averageValue: "1000"
```
