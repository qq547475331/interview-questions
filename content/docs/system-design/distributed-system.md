---
title: 分布式系统
weight: 1
---

# 分布式系统面试题

## 1. 分布式系统的 CAP 理论

**问题：** 请解释 CAP 理论，以及在系统设计中的权衡。

**答案：**

CAP 理论指出，分布式系统不可能同时满足以下三个特性：

| 特性 | 说明 |
|------|------|
| **一致性（Consistency）** | 所有节点在同一时间看到相同的数据 |
| **可用性（Availability）** | 每个请求都能收到非错误的响应 |
| **分区容错性（Partition Tolerance）** | 系统在网络分区时仍能继续运行 |

### CAP 权衡

1. **CP 系统**（一致性 + 分区容错）
   - 例如：ZooKeeper、etcd、HBase
   - 适用场景：金融交易、库存管理

2. **AP 系统**（可用性 + 分区容错）
   - 例如：Cassandra、DynamoDB、Eureka
   - 适用场景：社交网络、内容分发

3. **CA 系统**（一致性 + 可用性）
   - 实际上不存在，因为网络分区不可避免

---

## 2. 分布式事务

**问题：** 分布式事务的解决方案有哪些？

**答案：**

### 2PC（两阶段提交）

```
阶段一（准备阶段）：
1. 协调者向所有参与者发送准备请求
2. 参与者执行本地事务，锁定资源
3. 参与者返回准备成功或失败

阶段二（提交阶段）：
1. 如果所有参与者准备成功，协调者发送提交请求
2. 如果有参与者准备失败，协调者发送回滚请求
3. 参与者执行提交或回滚，释放锁
```

**缺点：** 同步阻塞、单点故障、数据不一致风险

### 3PC（三阶段提交）

增加了预提交阶段，减少阻塞时间，但实现复杂。

### TCC（Try-Confirm-Cancel）

```java
// Try 阶段：预留资源
boolean tryDeduct(Account account, Money amount);

// Confirm 阶段：确认执行
boolean confirmDeduct(Account account, Money amount);

// Cancel 阶段：取消回滚
boolean cancelDeduct(Account account, Money amount);
```

### Saga 模式

- **编排式（Choreography）**：服务间通过事件驱动
- **编排式（Orchestration）**：由协调器统一管理

### 本地消息表

将分布式事务转换为本地事务 + 消息发送。

---

## 3. 分布式锁

**问题：** 如何实现分布式锁？

**答案：**

### 基于 Redis

```python
import redis
import uuid
import time

class RedisLock:
    def __init__(self, redis_client, lock_key, expire_time=30):
        self.redis = redis_client
        self.lock_key = lock_key
        self.expire_time = expire_time
        self.identifier = str(uuid.uuid4())
    
    def acquire(self):
        # SET key value NX EX seconds
        return self.redis.set(
            self.lock_key, 
            self.identifier, 
            nx=True, 
            ex=self.expire_time
        )
    
    def release(self):
        # 使用 Lua 脚本保证原子性
        lua_script = """
        if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
        else
            return 0
        end
        """
        self.redis.eval(lua_script, 1, self.lock_key, self.identifier)
```

### 基于 ZooKeeper

```java
// 创建临时顺序节点
String lockPath = zk.create("/lock/node", data, 
    ZooDefs.Ids.OPEN_ACL_UNSAFE, 
    CreateMode.EPHEMERAL_SEQUENTIAL);

// 检查是否是最小序号节点
List<String> children = zk.getChildren("/lock", false);
Collections.sort(children);
if (lockPath.endsWith(children.get(0))) {
    // 获得锁
} else {
    // 监听前一个节点
}
```

### 基于 etcd

使用 etcd 的租约（Lease）和事务（Txn）机制实现。

---

## 4. 负载均衡算法

**问题：** 常见的负载均衡算法有哪些？

**答案：**

| 算法 | 说明 | 适用场景 |
|------|------|----------|
| **轮询（Round Robin）** | 按顺序轮流分配 | 服务器性能相近 |
| **加权轮询** | 根据权重分配 | 服务器性能不同 |
| **随机** | 随机选择 | 简单场景 |
| **最少连接** | 选择当前连接数最少的服务器 | 长连接场景 |
| **IP 哈希** | 根据客户端 IP 计算哈希 | 需要会话保持 |
| **一致性哈希** | 环形哈希空间 | 缓存分片 |

### 一致性哈希

```
1. 将服务器节点映射到哈希环上
2. 将请求 key 映射到哈希环上
3. 顺时针找到第一个服务器节点

优点：
- 增删节点只影响相邻节点
- 数据分布均匀

虚拟节点：
- 每个物理节点对应多个虚拟节点
- 解决数据倾斜问题
```

---

## 5. 微服务架构

**问题：** 微服务架构的优势和挑战是什么？

**答案：**

### 优势

1. **独立部署**：服务可独立开发、测试、部署
2. **技术异构**：不同服务可使用不同技术栈
3. **弹性扩展**：按需扩展特定服务
4. **故障隔离**：单个服务故障不影响整体
5. **团队自治**：小团队负责独立服务

### 挑战

1. **分布式复杂性**
   - 网络延迟
   - 分布式事务
   - 服务发现

2. **运维复杂度**
   - 服务数量多
   - 监控和日志收集
   - 部署流水线

3. **数据一致性**
   - 最终一致性
   - 分布式锁

### 核心组件

```
┌─────────────────────────────────────────┐
│              API Gateway                │
│    (Kong / Zuul / Spring Cloud Gateway) │
└─────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
┌────────┐    ┌────────┐    ┌────────┐
│Service │    │Service │    │Service │
│   A    │    │   B    │    │   C    │
└────────┘    └────────┘    └────────┘
    │              │              │
    └──────────────┼──────────────┘
                   ▼
┌─────────────────────────────────────────┐
│         Service Discovery               │
│       (Eureka / Consul / Nacos)         │
└─────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
┌────────┐    ┌────────┐    ┌────────┐
│ Config │    │  Log   │    │ Monitor│
│ Server │    │ Center │    │ Center │
└────────┘    └────────┘    └────────┘
```
