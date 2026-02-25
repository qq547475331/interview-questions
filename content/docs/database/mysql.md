---
title: MySQL 面试题
weight: 1
---

# MySQL 面试题

## 1. MySQL 索引原理

**问题：** 请介绍 MySQL 索引的类型和工作原理。

**答案：**

### 索引类型

1. **B-Tree 索引**（默认）
   - 适合范围查询和等值查询
   - 支持最左前缀匹配

2. **Hash 索引**
   - 仅支持等值查询
   - 查询效率 O(1)

3. **Full-text 索引**
   - 用于全文搜索

4. **R-Tree 索引**
   - 用于空间数据

### InnoDB 索引结构

- **聚簇索引**：数据行存储在索引的叶子节点
- **非聚簇索引**：叶子节点存储主键值

**最左前缀原则：**
对于复合索引 (a, b, c)，查询条件必须从最左列开始匹配。

---

## 2. 事务的 ACID 特性

**问题：** 请解释事务的 ACID 特性。

**答案：**

| 特性 | 说明 |
|------|------|
| **原子性（Atomicity）** | 事务是不可分割的最小工作单元，要么全部成功，要么全部失败 |
| **一致性（Consistency）** | 事务执行前后，数据库从一个一致状态变为另一个一致状态 |
| **隔离性（Isolation）** | 多个事务并发执行时，互不干扰 |
| **持久性（Durability）** | 事务一旦提交，对数据库的改变是永久的 |

### 隔离级别

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|---------|------|-----------|------|
| READ UNCOMMITTED | ✓ | ✓ | ✓ |
| READ COMMITTED | ✗ | ✓ | ✓ |
| REPEATABLE READ | ✗ | ✗ | ✓ |
| SERIALIZABLE | ✗ | ✗ | ✗ |

---

## 3. SQL 优化

**问题：** 如何进行 SQL 性能优化？

**答案：**

### 查询优化

1. **避免 SELECT ***
   - 只查询需要的列

2. **使用索引**
   - WHERE 条件中使用索引列
   - 避免在索引列上使用函数

3. **优化 JOIN**
   - 小表驱动大表
   - 确保 JOIN 条件有索引

4. **避免子查询**
   - 尽量使用 JOIN 替代

5. **分页优化**
   ```sql
   -- 避免大偏移量
   SELECT * FROM table WHERE id > 10000 LIMIT 10;
   ```

### 表结构优化

1. **选择合适的数据类型**
2. **适当的冗余字段**
3. **分表分库**
4. **读写分离**

---

## 4. 锁机制

**问题：** MySQL 有哪些锁类型？

**答案：**

### 按粒度分

1. **行锁（Row Lock）**
   - 锁定单行记录
   - InnoDB 支持

2. **表锁（Table Lock）**
   - 锁定整个表
   - MyISAM 使用

3. **页锁（Page Lock）**
   - 锁定数据页

### 按功能分

1. **共享锁（S Lock）**
   - 读锁，允许多个事务同时读取

2. **排他锁（X Lock）**
   - 写锁，阻塞其他事务读写

3. **意向锁**
   - 表级锁，表示事务将要获取的行锁类型

### InnoDB 行锁算法

- **Record Lock**：锁定单个记录
- **Gap Lock**：锁定范围，防止幻读
- **Next-Key Lock**：Record Lock + Gap Lock

---

## 5. 主从复制

**问题：** MySQL 主从复制的原理是什么？

**答案：**

### 复制原理

1. **主库（Master）**
   - 记录所有修改操作到 binlog
   - Dump 线程发送 binlog 到从库

2. **从库（Slave）**
   - I/O 线程接收 binlog，写入 relay log
   - SQL 线程重放 relay log 中的事件

### 复制模式

1. **异步复制**（默认）
   - 主库不等待从库确认

2. **半同步复制**
   - 至少一个从库确认后才返回

3. **组复制**
   - 基于 Paxos 协议的多主复制

### 复制类型

- **基于语句（SBR）**：记录 SQL 语句
- **基于行（RBR）**：记录行数据变化
- **混合模式（MBR）**：根据情况自动选择

---

## 6. MySQL 锁机制与死锁

**问题：** 什么是死锁？在高并发写入时，如何减少 MySQL 的锁冲突？

**答案：**

**死锁定义：**
两个或多个事务相互等待对方释放锁，形成循环等待，导致无法继续执行。

```sql
-- 事务1
BEGIN;
UPDATE accounts SET amount = amount - 100 WHERE id = 1;  -- 持有 id=1 的锁
UPDATE accounts SET amount = amount + 100 WHERE id = 2;  -- 等待 id=2 的锁

-- 事务2
BEGIN;
UPDATE accounts SET amount = amount - 100 WHERE id = 2;  -- 持有 id=2 的锁
UPDATE accounts SET amount = amount + 100 WHERE id = 1;  -- 等待 id=1 的锁（死锁！）
```

**查看死锁：**
```sql
-- 查看最近一次死锁信息
SHOW ENGINE INNODB STATUS;

-- 开启死锁日志
SET GLOBAL innodb_print_all_deadlocks = ON;
```

**减少锁冲突的方法：**

1. **按固定顺序访问资源**
   ```sql
   -- 所有事务都按 id 升序更新
   UPDATE accounts SET amount = amount - 100 WHERE id IN (1, 2) ORDER BY id;
   ```

2. **减少事务范围**
   - 尽快提交事务
   - 避免在事务中做耗时操作

3. **使用乐观锁**
   ```sql
   -- 使用版本号
   UPDATE accounts SET amount = amount - 100, version = version + 1
   WHERE id = 1 AND version = 5;
   ```

4. **批量操作分批处理**
   ```sql
   -- 避免一次更新太多行
   UPDATE table SET status = 1 WHERE id BETWEEN 1 AND 10000 LIMIT 1000;
   ```

5. **合理使用索引**
   - 确保 WHERE 条件走索引，避免锁升级

---

## 7. MySQL 主从延迟

**问题：** 导致 MySQL 主从延迟的核心原因有哪些？如何监控并有效降低延迟？

**答案：**

**延迟原因：**

| 原因 | 说明 |
|------|------|
| **大事务** | 一个事务包含大量操作 |
| **锁等待** | 从库执行时遇到锁冲突 |
| **硬件差异** | 从库性能低于主库 |
| **网络延迟** | 主从之间网络不稳定 |
| **单线程复制** | 传统复制是单线程 |
| **DDL 操作** | ALTER TABLE 等大操作 |

**监控延迟：**

```sql
-- 查看从库状态
SHOW SLAVE STATUS\G

-- 关键指标
Seconds_Behind_Master: 10  -- 延迟秒数

-- 使用 pt-heartbeat 更精确监控
pt-heartbeat --database=test --update --daemonize
pt-heartbeat --database=test --check
```

**降低延迟的方法：**

1. **并行复制（MySQL 5.6+）**
   ```ini
   # my.cnf
   slave_parallel_workers = 4
   slave_parallel_type = LOGICAL_CLOCK
   ```

2. **读写分离，从库只读**
   - 避免在从库上执行写操作

3. **大事务拆分**
   ```sql
   -- 避免
   DELETE FROM logs WHERE create_time < '2023-01-01';
   
   -- 改为分批
   DELETE FROM logs WHERE create_time < '2023-01-01' LIMIT 1000;
   ```

4. **使用 GTID 复制**
   ```ini
   gtid_mode = ON
   enforce_gtid_consistency = ON
   ```

5. **升级硬件**
   - 使用 SSD
   - 增加内存

6. **使用缓存**
   - 读请求优先走缓存，减少对从库压力

---

## 8. MySQL 高可用架构

**问题：** 请描述 MySQL 常见的高可用架构方案。

**答案：**

### 主从复制 + 读写分离

```
┌─────────────┐
│   应用层    │
└──────┬──────┘
       │
┌──────┴──────┐
│  代理层     │  <-- MyCat, ProxySQL
│  (读写分离) │
└──────┬──────┘
       │
   ┌───┴───┐
   ▼       ▼
┌──────┐ ┌──────┐
│ Master│ │ Slave│
│ (写)  │ │ (读) │
└──────┘ └──────┘
```

### MHA（Master High Availability）

```
┌─────────┐
│  MHA    │  <-- 监控主库，自动故障转移
│ Manager │
└────┬────┘
     │
┌────┼────┐
▼    ▼    ▼
M1   S1   S2
(主) (从) (从)
```

- 自动故障检测和转移
- 通常在 10-30 秒内完成切换

### MySQL Group Replication

```
┌─────────┐
│  Primary │
│  (读写)  │
└────┬────┘
     │
┌────┼────┐
▼    ▼    ▼
S1   S2   S3
(Secondary，可读)
```

- 组内自动选主
- 自动故障转移
- 强一致性

### InnoDB Cluster

```
MySQL Shell + MySQL Router + Group Replication
```

- 官方推荐方案
- 自动配置和管理
- 支持读写分离

**对比：**

| 方案 | 自动切换 | 数据一致性 | 适用场景 |
|------|----------|-----------|----------|
| 主从复制 | 需配合工具 | 异步 | 读多写少 |
| MHA | 是 | 异步 | 传统架构 |
| Group Replication | 是 | 强一致 | 高可用要求 |
| InnoDB Cluster | 是 | 强一致 | 新架构首选 |
