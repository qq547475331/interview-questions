---
title: Kubernetes
weight: 3
---

# Kubernetes 面试题

## 1. K8s 核心架构

**问题：** 描述 Kubernetes 的整体架构和核心组件。

**答案：**

**Master 节点组件：**

| 组件 | 功能 |
|------|------|
| **kube-apiserver** | API 入口，处理所有 REST 请求 |
| **etcd** | 分布式键值存储，保存集群状态 |
| **kube-scheduler** | 负责 Pod 调度，选择最佳 Node |
| **kube-controller-manager** | 运行各种控制器（Node、Replication、Endpoint 等） |

**Worker 节点组件：**

| 组件 | 功能 |
|------|------|
| **kubelet** | 管理 Pod 生命周期，与 Master 通信 |
| **kube-proxy** | 维护网络规则，实现 Service 负载均衡 |
| **Container Runtime** | 容器运行时（Docker、containerd、CRI-O） |

**架构图：**

```
┌─────────────────────────────────────────┐
│              Master Node                │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │ API     │ │Scheduler│ │Controller│  │
│  │ Server  │ │         │ │ Manager  │  │
│  └────┬────┘ └────┬────┘ └────┬─────┘  │
│       └───────────┴───────────┘         │
│                   │                     │
│              ┌────┴────┐                │
│              │  etcd   │                │
│              └─────────┘                │
└─────────────────────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
┌─────────┐   ┌─────────┐   ┌─────────┐
│ Worker  │   │ Worker  │   │ Worker  │
│  Node   │   │  Node   │   │  Node   │
│┌───────┐│   │┌───────┐│   │┌───────┐│
││kubelet││   ││kubelet││   ││kubelet││
│└───┬───┘│   │└───┬───┘│   │└───┬───┘│
│┌───┴───┐│   │┌───┴───┐│   │┌───┴───┐│
││kube-  ││   ││kube-  ││   ││kube-  ││
││proxy ││   ││proxy ││   ││proxy ││
│└───────┘│   │└───────┘│   │└───────┘│
└─────────┘   └─────────┘   └─────────┘
```

---

## 2. Pod 生命周期

**问题：** 解释 Pod 的生命周期和状态。

**答案：**

**Pod 状态：**

| 状态 | 说明 |
|------|------|
| **Pending** | Pod 已创建，等待调度或镜像拉取 |
| **Running** | Pod 已绑定到 Node，至少一个容器在运行 |
| **Succeeded** | 所有容器正常退出 |
| **Failed** | 至少一个容器异常退出 |
| **Unknown** | 无法获取 Pod 状态 |
| **CrashLoopBackOff** | 容器反复崩溃重启 |

**容器状态：**

```yaml
Waiting:
  Reason: ContainerCreating  # 或 ImagePullBackOff、CrashLoopBackOff
Running:
  StartedAt: "2024-01-01T00:00:00Z"
Terminated:
  ExitCode: 0
  Reason: Completed
```

**重启策略：**

```yaml
restartPolicy: Always    # 默认，总是重启
restartPolicy: OnFailure # 失败时重启
restartPolicy: Never     # 从不重启
```

---

## 3. K8s 资源对象

**问题：** 列举常用的 K8s 资源对象及其用途。

**答案：**

**工作负载资源：**

| 资源 | 用途 | 特点 |
|------|------|------|
| **Pod** | 最小部署单元 | 包含一个或多个容器 |
| **Deployment** | 无状态应用部署 | 支持滚动更新、回滚 |
| **StatefulSet** | 有状态应用部署 | 稳定网络标识、持久存储 |
| **DaemonSet** | 守护进程 | 每个 Node 运行一个 Pod |
| **Job** | 一次性任务 | 运行到完成 |
| **CronJob** | 定时任务 | 基于时间调度 |

**服务发现资源：**

| 资源 | 用途 |
|------|------|
| **Service** | 暴露应用，提供负载均衡 |
| **Ingress** | HTTP/HTTPS 路由 |
| **Endpoint** | 后端 Pod 地址列表 |

**配置资源：**

| 资源 | 用途 |
|------|------|
| **ConfigMap** | 存储配置数据 |
| **Secret** | 存储敏感数据 |
| **PersistentVolume** | 持久化存储 |
| **PersistentVolumeClaim** | 存储申请 |

---

## 4. Deployment 更新策略

**问题：** Deployment 的更新策略有哪些？如何实现零停机部署？

**答案：**

**更新策略类型：**

```yaml
spec:
  strategy:
    type: RollingUpdate  # 或 Recreate
    rollingUpdate:
      maxSurge: 25%      # 更新时最多可超出的 Pod 数量
      maxUnavailable: 25% # 更新时最大不可用 Pod 数量
```

| 策略 | 说明 |
|------|------|
| **RollingUpdate** | 滚动更新，逐步替换旧 Pod |
| **Recreate** | 先删除所有旧 Pod，再创建新 Pod（有停机时间） |

**零停机部署配置：**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # 确保始终有 Pod 可用
  template:
    spec:
      containers:
      - name: app
        image: myapp:v2
        readinessProbe:    # 就绪探针
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

**常用命令：**

```bash
# 更新镜像
kubectl set image deployment/web-app app=myapp:v2

# 查看更新状态
kubectl rollout status deployment/web-app

# 查看历史版本
kubectl rollout history deployment/web-app

# 回滚到上一个版本
kubectl rollout undo deployment/web-app

# 回滚到指定版本
kubectl rollout undo deployment/web-app --to-revision=2
```

---

## 5. Service 类型

**问题：** Kubernetes Service 有哪些类型？

**答案：**

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| **ClusterIP** | 集群内部访问 | 微服务间通信 |
| **NodePort** | 通过 Node IP 暴露 | 开发测试 |
| **LoadBalancer** | 云厂商负载均衡 | 生产环境 |
| **ExternalName** | 映射外部 DNS | 访问外部服务 |

**示例：**

```yaml
# ClusterIP（默认）
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080

# NodePort
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # 范围 30000-32767

# LoadBalancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: myapp
```

---

## 6. 健康检查

**问题：** Kubernetes 中的健康检查机制有哪些？

**答案：**

**三种探针：**

| 探针 | 用途 | 失败行为 |
|------|------|----------|
| **LivenessProbe** | 检查容器是否存活 | 失败则重启容器 |
| **ReadinessProbe** | 检查容器是否就绪 | 失败则从 Service 摘除 |
| **StartupProbe** | 检查应用是否启动 | 用于慢启动应用 |

**配置示例：**

```yaml
spec:
  containers:
  - name: app
    image: myapp:v1
    
    # 存活探针
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    # 就绪探针
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    
    # 启动探针（用于慢启动应用）
    startupProbe:
      httpGet:
        path: /health
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

**探针类型：**

```yaml
# HTTP GET
httpGet:
  path: /health
  port: 8080
  httpHeaders:
  - name: Custom-Header
    value: Awesome

# TCP Socket
tcpSocket:
  port: 8080

# Exec Command
exec:
  command:
  - cat
  - /tmp/healthy
```

---

## 7. 资源限制

**问题：** 如何在 Kubernetes 中设置资源限制？

**答案：**

```yaml
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      # 资源请求（调度依据）
      requests:
        memory: "128Mi"    # 128 MB
        cpu: "100m"        # 0.1 核
      # 资源限制（硬性上限）
      limits:
        memory: "512Mi"    # 512 MB
        cpu: "500m"        # 0.5 核
```

**概念说明：**

| 配置项 | 说明 |
|--------|------|
| **requests** | 调度时保证分配的资源，也是 HPA 计算依据 |
| **limits** | 容器能使用的最大资源 |

**注意事项：**
- CPU 是可压缩资源，超过 limits 会被限制
- 内存是不可压缩资源，超过 limits 会被 OOM Kill
- 建议设置 requests = limits，避免资源争抢

---

## 8. K8s 故障排查

**问题：** Pod 启动失败如何排查？

**答案：**

**排查步骤：**

```bash
# 1. 查看 Pod 状态
kubectl get pods
kubectl describe pod <pod-name>

# 2. 查看 Pod 事件
kubectl get events --sort-by='.lastTimestamp'

# 3. 查看容器日志
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # 上一个容器实例

# 4. 进入容器调试
kubectl exec -it <pod-name> -- /bin/sh

# 5. 查看资源使用
kubectl top pod <pod-name>
kubectl top node
```

**常见问题：**

| 现象 | 可能原因 | 解决方法 |
|------|----------|----------|
| ImagePullBackOff | 镜像拉取失败 | 检查镜像名、Secret、网络 |
| CrashLoopBackOff | 容器反复崩溃 | 查看日志，检查启动命令 |
| Pending | 调度失败 | 检查资源、节点亲和性、污点 |
| OOMKilled | 内存不足 | 增加内存限制 |
| Evicted | 节点资源不足 | 清理节点或增加资源 |

---

## 9. K8s 网络模型

**问题：** 解释 Kubernetes 的网络模型。

**答案：**

**核心原则：**
1. 每个 Pod 有独立的 IP 地址
2. 所有 Pod 可以在任何节点上互相通信（无需 NAT）
3. 所有节点可以与所有 Pod 通信
4. Pod 内部容器共享网络命名空间

**网络方案（CNI）：**

| 方案 | 特点 |
|------|------|
| **Flannel** | 简单，Overlay 网络 |
| **Calico** | 支持网络策略，BGP 路由 |
| **Cilium** | 基于 eBPF，高性能 |
| **Weave** | 自动发现，加密通信 |

**网络策略示例：**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

---

## 10. K8s 网络流向（Flannel VXLAN）

**问题：** 请详细描述一个 Pod 访问另一个 Pod 的网络流向（以 Flannel 的 VXLAN 模式为例）。

**答案：**

**网络流向：**

```
Pod A (Node 1) → cni0 → flannel.1 (VTEP) → eth0 → 物理网络 → eth0 → flannel.1 (VTEP) → cni0 → Pod B (Node 2)
```

**详细过程：**

1. **Pod A 发起请求**
   - 目标 IP 是 Pod B 的 IP（10.244.2.5）
   - 根据路由表，数据包发送到 cni0 网桥

2. **Node 1 处理**
   ```bash
   # 查看路由
   ip route
   10.244.2.0/24 via 10.244.2.0 dev flannel.1 onlink
   ```
   - 目标网段 10.244.2.0/24 走 flannel.1 设备
   - flannel.1 是 VTEP（VXLAN Tunnel Endpoint）

3. **VXLAN 封装**
   - 原始数据包被封装在 UDP 报文中
   - 外层源 IP：Node 1 IP
   - 外层目标 IP：Node 2 IP（通过 etcd 获取）
   - VNI（VXLAN Network Identifier）：默认 1

4. **物理网络传输**
   - 封装后的 UDP 包（端口 8472）通过物理网络发送

5. **Node 2 处理**
   - flannel.1 接收到 UDP 包，解封装
   - 内层目标 IP 是 Pod B
   - 通过 cni0 网桥转发到 Pod B

**查看 VTEP 信息：**
```bash
# 查看 VTEP 和 MAC 地址映射
ip neigh show dev flannel.1

# 查看 FDB（Forwarding Database）
bridge fdb show dev flannel.1

# 查看 arp 表
ip neigh show
```

---

## 11. K8s 调度策略（Taints & Tolerations）

**问题：** 什么是 Taints（污点）和 Tolerations（容忍度）？在生产中如何利用它们实现"独占节点"？

**答案：**

**概念：**

| 概念 | 作用 | 类比 |
|------|------|------|
| **Taint（污点）** | 节点属性，排斥 Pod | "此节点只接受特定 Pod" |
| **Toleration（容忍）** | Pod 属性，允许被调度到带污点的节点 | "我可以接受这个污点" |

**污点类型：**

```bash
# 添加污点
kubectl taint nodes node1 dedicated=gpu:NoSchedule

# 污点效果
NoSchedule      # 不调度新 Pod（已运行的不受影响）
PreferNoSchedule # 尽量不调度
NoExecute       # 不调度，且驱逐已运行的 Pod（不匹配时）
```

**实现独占节点：**

```yaml
# 1. 给节点添加污点
# kubectl taint nodes node-gpu-01 dedicated=gpu:NoSchedule

# 2. 普通 Pod（不会被调度到该节点）
apiVersion: v1
kind: Pod
metadata:
  name: normal-pod
spec:
  containers:
  - name: app
    image: nginx
  # 没有 toleration，无法调度到带污点的节点

# 3. GPU Pod（可以调度到该节点）
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  nodeSelector:
    hardware-type: gpu  # 还可以配合标签选择
  containers:
  - name: cuda
    image: nvidia/cuda
```

**其他使用场景：**

```bash
# 专用节点（如 master 节点默认污点）
kubectl taint nodes master node-role.kubernetes.io/master=:NoSchedule

# 维护模式
kubectl taint nodes node1 maintenance=true:NoExecute

# 特殊硬件
kubectl taint nodes node-ssd storage=ssd:NoSchedule
```

---

## 12. Pod 故障排查实战

**问题：** Pod 状态显示 ImagePullBackOff 或 CrashLoopBackOff，你的排查流程是什么？

**答案：**

**ImagePullBackOff 排查：**

```bash
# 1. 查看详细事件
kubectl describe pod <pod-name>
# 关注 Events 部分的 Error 信息

# 2. 常见原因和解决

# 原因1：镜像不存在或标签错误
# Error: ImagePullBackOff - rpc error: code = Unknown desc = Error response from daemon: pull access denied
# 解决：检查镜像名和标签是否正确
docker pull <image>:<tag>  # 本地测试

# 原因2：私有仓库认证失败
# 解决：创建 ImagePullSecret
kubectl create secret docker-registry regcred \
  --docker-server=<your-registry-server> \
  --docker-username=<your-name> \
  --docker-password=<your-pword> \
  --docker-email=<your-email>

# 在 Pod 中引用
spec:
  imagePullSecrets:
  - name: regcred

# 原因3：网络问题无法拉取镜像
# 解决：检查节点网络，或使用代理
kubectl run test --image=busybox --rm -it -- ping 8.8.8.8
```

**CrashLoopBackOff 排查：**

```bash
# 1. 查看日志
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # 上次崩溃的日志

# 2. 常见原因

# 原因1：启动命令错误
# 解决：检查 command 和 args 配置

# 原因2：配置文件缺失
# 解决：检查 ConfigMap/Secret 挂载
kubectl exec <pod-name> -- ls /etc/config/

# 原因3：资源限制导致 OOM
# 解决：查看是否 OOMKilled
kubectl describe pod <pod-name> | grep -A 5 "Last State"
# 增加内存限制

# 原因4：健康检查配置不当
# 解决：调整探针配置
kubectl describe pod <pod-name> | grep -A 10 "Liveness"

# 原因5：依赖服务未就绪
# 解决：使用 initContainers 等待依赖
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z db 3306; do sleep 2; done']
```

**通用排查流程：**

```bash
# 1. 查看 Pod 状态和事件
kubectl get pod <pod-name> -o yaml
kubectl describe pod <pod-name>

# 2. 查看节点状态
kubectl get nodes -o wide
kubectl describe node <node-name>

# 3. 检查资源配额
kubectl get resourcequota
kubectl describe limitrange

# 4. 进入容器调试（如果能启动）
kubectl exec -it <pod-name> -- /bin/sh

# 5. 对比正常 Pod 的配置
diff <(kubectl get pod good-pod -o yaml) <(kubectl get pod bad-pod -o yaml)
```
