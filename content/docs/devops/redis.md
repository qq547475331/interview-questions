---
title: Redis
weight: 4
---

# Redis 面试题

## 1. Redis 数据类型

**问题：** Redis 支持哪些数据类型？

**答案：**

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| **String** | 字符串、整数、浮点数 | 缓存、计数器 |
| **Hash** | 键值对集合 | 存储对象 |
| **List** | 双向链表 | 消息队列、时间线 |
| **Set** | 无序唯一集合 | 标签、共同好友 |
| **Sorted Set** | 有序集合 | 排行榜、延迟队列 |
| **Bitmap** | 位图 | 签到、在线状态 |
| **HyperLogLog** | 基数统计 | UV 统计 |
| **Geo** | 地理位置 | 附近的人 |
| **Stream** | 消息流 | 消息队列 |

---

## 2. Redis 持久化

**问题：** Redis 的持久化方式有哪些？

**答案：**

**RDB（快照）：**
- 定时将内存数据快照保存到磁盘
- 文件紧凑，恢复速度快
- 可能丢失最后一次快照后的数据

```bash
save 900 1      # 900秒内至少1个key变化则保存
save 300 10     # 300秒内至少10个key变化则保存
save 60 10000   # 60秒内至少10000个key变化则保存
```

**AOF（追加文件）：**
- 记录所有写操作命令
- 数据安全性更高
- 文件较大，恢复速度较慢

```bash
appendonly yes
appendfsync everysec  # 每秒同步
```

**混合持久化（Redis 4.0+）：**
- RDB + AOF 结合
- 开头是 RDB 格式，后面是 AOF 格式

---

## 3. Redis 缓存问题

**问题：** 什么是缓存穿透、缓存击穿、缓存雪崩？如何解决？

**答案：**

| 问题 | 现象 | 解决方案 |
|------|------|----------|
| **缓存穿透** | 查询不存在的数据，绕过缓存直达数据库 | 布隆过滤器、缓存空值 |
| **缓存击穿** | 热点key过期，大量请求直达数据库 | 互斥锁、逻辑过期 |
| **缓存雪崩** | 大量key同时过期，数据库压力激增 | 随机过期时间、多级缓存 |

**解决方案代码：**

```java
// 缓存空值防止穿透
public String getData(String key) {
    String value = redis.get(key);
    if (value == null) {
        // 查询数据库
        value = db.query(key);
        if (value == null) {
            // 缓存空值，短时间过期
            redis.setex(key, 60, "");
        } else {
            redis.setex(key, 3600, value);
        }
    }
    return value;
}

// 互斥锁防止击穿
public String getHotData(String key) {
    String value = redis.get(key);
    if (value == null) {
        // 获取锁
        if (redis.setnx("lock:" + key, "1", 10)) {
            try {
                value = db.query(key);
                redis.setex(key, 3600, value);
            } finally {
                redis.del("lock:" + key);
            }
        } else {
            // 获取锁失败，短暂等待后重试
            Thread.sleep(100);
            return getHotData(key);
        }
    }
    return value;
}
```

---

## 4. Redis 高可用

**问题：** Redis 如何实现高可用？

**答案：**

**主从复制：**
```bash
# 从节点配置
replicaof 192.168.1.100 6379
```
- 数据冗余
- 读写分离
- 故障恢复需要手动切换

**哨兵模式（Sentinel）：**
- 监控主从节点
- 自动故障转移
- 最少需要 3 个哨兵节点

```bash
# sentinel.conf
sentinel monitor mymaster 192.168.1.100 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
```

**集群模式（Cluster）：**
- 数据分片（16384 个槽位）
- 自动故障转移
- 支持水平扩展

```bash
# 创建集群
redis-cli --cluster create \
  192.168.1.101:6379 192.168.1.102:6379 192.168.1.103:6379 \
  192.168.1.104:6379 192.168.1.105:6379 192.168.1.106:6379 \
  --cluster-replicas 1
```

---

## 5. Redis 性能优化

**问题：** 如何优化 Redis 性能？

**答案：**

1. **内存优化**
   - 使用 Hash 存储小对象（ziplist 编码）
   - 设置合理的过期时间
   - 启用内存淘汰策略

2. **命令优化**
   - 使用 Pipeline 批量操作
   - 避免大 key（String > 10KB，集合 > 5000 个元素）
   - 使用 SCAN 替代 KEYS

3. **架构优化**
   - 读写分离
   - 使用连接池
   - 本地缓存 + Redis 多级缓存

```bash
# 查看大 key
redis-cli --bigkeys

# 内存分析
redis-cli --memkeys

# 慢查询
slowlog get 10
```
