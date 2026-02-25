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
