---
title: Java 面试题
weight: 1
---

# Java 面试题

## 1. Java 中的集合框架

**问题：** 请介绍 Java 集合框架的主要接口和实现类。

**答案：**

Java 集合框架主要分为两大类：

### Collection 接口
- **List**：有序、可重复
  - ArrayList：基于数组，查询快
  - LinkedList：基于链表，增删快
  - Vector：线程安全（已过时）
  
- **Set**：无序、不可重复
  - HashSet：基于 HashMap
  - TreeSet：基于红黑树，有序
  - LinkedHashSet：保持插入顺序

### Map 接口
- **HashMap**：基于哈希表，非线程安全
- **TreeMap**：基于红黑树，有序
- **LinkedHashMap**：保持插入顺序
- **ConcurrentHashMap**：线程安全

---

## 2. HashMap 的工作原理

**问题：** 请详细说明 HashMap 的工作原理。

**答案：**

HashMap 基于哈希表实现，主要特点：

1. **数据结构**：数组 + 链表/红黑树（JDK 8+）
2. **put 流程**：
   - 计算 key 的 hash 值
   - 通过 `(n-1) & hash` 计算索引
   - 如果冲突，使用链表或红黑树解决

3. **扩容机制**：
   - 默认初始容量：16
   - 负载因子：0.75
   - 当元素数量 > 容量 × 负载因子时扩容

```java
// 简化的 put 逻辑
public V put(K key, V value) {
    int hash = hash(key);
    int index = (n - 1) & hash;
    // ... 处理冲突和插入
}
```

---

## 3. JVM 内存模型

**问题：** 请介绍 JVM 的内存结构和垃圾回收机制。

**答案：**

### JVM 内存结构

1. **堆（Heap）**
   - 新生代（Eden、Survivor0、Survivor1）
   - 老年代（Old Generation）

2. **方法区（Method Area）**
   - 类信息、常量、静态变量
   - JDK 8 后使用元空间（Metaspace）

3. **虚拟机栈（VM Stack）**
   - 局部变量表
   - 操作数栈
   - 动态链接

4. **本地方法栈（Native Method Stack）**

5. **程序计数器（PC Register）**

### 垃圾回收

- **Minor GC**：清理新生代
- **Major GC**：清理老年代
- **Full GC**：清理整个堆

**常用垃圾收集器：**
- Serial、Parallel
- CMS（Concurrent Mark Sweep）
- G1（Garbage First）
- ZGC（低延迟）

---

## 4. 多线程与并发

**问题：** Java 中实现多线程的方式有哪些？如何保证线程安全？

**答案：**

### 实现多线程的方式

1. **继承 Thread 类**
```java
class MyThread extends Thread {
    @Override
    public void run() {
        // 线程执行逻辑
    }
}
```

2. **实现 Runnable 接口**
```java
class MyRunnable implements Runnable {
    @Override
    public void run() {
        // 线程执行逻辑
    }
}
```

3. **实现 Callable 接口**（可返回结果）
```java
class MyCallable implements Callable<String> {
    @Override
    public String call() throws Exception {
        return "result";
    }
}
```

### 保证线程安全

1. **synchronized 关键字**
   - 同步方法
   - 同步代码块

2. **Lock 接口**
   - ReentrantLock
   - ReadWriteLock

3. **原子类**
   - AtomicInteger
   - AtomicReference

4. **并发集合**
   - ConcurrentHashMap
   - CopyOnWriteArrayList

5. **线程池**
   - ExecutorService
   - ThreadPoolExecutor

---

## 5. Spring 框架核心

**问题：** 请介绍 Spring 框架的核心特性：IOC 和 AOP。

**答案：**

### IOC（控制反转）

将对象的创建和管理交给 Spring 容器，降低组件之间的耦合度。

**实现方式：**
- XML 配置
- 注解配置（@Component、@Service、@Repository、@Controller）
- Java 配置（@Configuration、@Bean）

**依赖注入方式：**
- 构造器注入（推荐）
- Setter 注入
- 字段注入（@Autowired）

### AOP（面向切面编程）

将横切关注点（日志、事务、权限等）从业务逻辑中分离。

**核心概念：**
- **Aspect**：切面
- **Join Point**：连接点
- **Pointcut**：切点
- **Advice**：通知（Before、After、Around）
- **Target**：目标对象

```java
@Aspect
@Component
public class LoggingAspect {
    @Before("execution(* com.example.service.*.*(..))")
    public void logBefore(JoinPoint joinPoint) {
        System.out.println("Method called: " + joinPoint.getSignature());
    }
}
```
