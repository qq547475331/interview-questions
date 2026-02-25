---
title: Docker
weight: 2
---

# Docker 面试题

## 1. Docker 核心概念

**问题：** 解释 Docker 的核心概念：镜像、容器、仓库。

**答案：**

| 概念 | 说明 | 类比 |
|------|------|------|
| **镜像 (Image)** | 只读模板，包含运行应用所需的代码、库、环境变量和配置文件 | 类（Class） |
| **容器 (Container)** | 镜像的运行实例，是独立、隔离的运行环境 | 对象（Object） |
| **仓库 (Registry)** | 存储和分发镜像的服务，如 Docker Hub | GitHub |

**核心原理：**
- 利用 Linux Namespace 实现隔离
- 利用 Cgroups 实现资源限制
- 利用 UnionFS 实现分层存储

---

## 2. 常用 Docker 命令

**问题：** 列举常用的 Docker 命令。

**答案：**

```bash
# 镜像操作
docker pull nginx:latest          # 拉取镜像
docker images                     # 查看本地镜像
docker rmi nginx                  # 删除镜像
docker build -t myapp:1.0 .       # 构建镜像
docker push myrepo/myapp:1.0      # 推送镜像

# 容器操作
docker run -d -p 80:80 --name web nginx    # 运行容器
docker ps                         # 查看运行中的容器
docker ps -a                      # 查看所有容器
docker stop web                   # 停止容器
docker start web                  # 启动容器
docker restart web                # 重启容器
docker rm web                     # 删除容器
docker exec -it web bash          # 进入容器

# 日志和数据
docker logs -f web                # 查看日志
docker logs --tail 100 web        # 查看最后100行
docker cp web:/etc/nginx/nginx.conf ./  # 复制文件
docker volume ls                  # 查看数据卷
docker network ls                 # 查看网络

# 系统信息
docker info                       # Docker 信息
docker system df                  # 磁盘使用情况
docker system prune               # 清理未使用资源
```

---

## 3. Dockerfile 编写

**问题：** 如何编写一个优化的 Dockerfile？

**答案：**

**最佳实践：**

```dockerfile
# 使用多阶段构建
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# 生产镜像
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**优化原则：**

1. **使用多阶段构建** - 减少最终镜像大小
2. **选择合适的基础镜像** - 优先使用 Alpine 版本
3. **减少镜像层数** - 合并 RUN 命令
4. **使用 .dockerignore** - 排除不需要的文件
5. **合理利用缓存** - 将不常改变的指令放在前面

```dockerfile
# 不好的示例（层数多）
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y vim

# 好的示例（合并层）
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*
```

---

## 4. Docker 网络模式

**问题：** Docker 有哪些网络模式？

**答案：**

| 模式 | 说明 | 使用场景 |
|------|------|----------|
| **bridge** | 默认模式，容器通过网桥通信 | 单机容器互联 |
| **host** | 容器使用宿主机网络栈 | 性能要求高 |
| **none** | 禁用网络 | 完全隔离 |
| **container** | 共享另一个容器的网络 | 紧密耦合的容器 |
| **overlay** | 跨主机网络 | Docker Swarm/K8s |

```bash
# 创建自定义网络
docker network create mynet

# 运行容器并指定网络
docker run -d --name web --network mynet nginx

# 容器间通信（使用容器名）
docker run -d --name app --network mynet myapp
# 在 app 中可以通过 http://web 访问 nginx

# 查看网络详情
docker network inspect mynet
```

---

## 5. Docker 数据持久化

**问题：** Docker 如何实现数据持久化？

**答案：**

**三种方式：**

1. **Bind Mount（绑定挂载）**
   ```bash
   docker run -v /host/path:/container/path nginx
   ```
   - 直接挂载宿主机目录
   - 适合开发环境

2. **Volume（数据卷）**
   ```bash
   docker volume create mydata
   docker run -v mydata:/data nginx
   ```
   - 由 Docker 管理
   - 适合生产环境
   - 支持备份、迁移

3. **tmpfs（临时存储）**
   ```bash
   docker run --tmpfs /cache nginx
   ```
   - 存储在内存中
   - 容器停止数据丢失

**对比：**

| 特性 | Bind Mount | Volume | tmpfs |
|------|-----------|--------|-------|
| 位置 | 任意路径 | Docker 管理 | 内存 |
| 性能 | 依赖宿主机 | 依赖宿主机 | 最快 |
| 移植性 | 差 | 好 | 差 |
| 备份 | 手动 | 支持 | 不支持 |

---

## 6. Docker Compose

**问题：** 如何使用 Docker Compose 管理多容器应用？

**答案：**

**docker-compose.yml 示例：**

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - api
    networks:
      - frontend

  api:
    build: ./api
    environment:
      - DB_HOST=db
      - DB_PORT=3306
    networks:
      - frontend
      - backend

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: myapp
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - backend

volumes:
  db_data:

networks:
  frontend:
  backend:
```

**常用命令：**

```bash
docker-compose up -d          # 后台启动
docker-compose down           # 停止并删除
docker-compose ps             # 查看状态
docker-compose logs -f        # 查看日志
docker-compose build          # 重新构建
docker-compose restart        # 重启服务
docker-compose exec web bash  # 进入容器
```

---

## 7. Docker 安全最佳实践

**问题：** Docker 容器有哪些安全注意事项？

**答案：**

1. **使用非 root 用户运行**
   ```dockerfile
   RUN useradd -m myuser
   USER myuser
   ```

2. **限制容器资源**
   ```bash
   docker run -m 512m --cpus=1.0 nginx
   ```

3. **只读文件系统**
   ```bash
   docker run --read-only --tmpfs /tmp nginx
   ```

4. **禁用特权模式**
   ```bash
   # 避免使用 --privileged
   docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
   ```

5. **镜像安全扫描**
   ```bash
   docker scan myimage
   ```

6. **使用安全的基础镜像**
   - 选择官方镜像
   - 使用 Alpine 等精简镜像
   - 定期更新镜像

---

## 8. Docker 与虚拟机对比

**问题：** Docker 容器与传统虚拟机有什么区别？

**答案：**

| 特性 | Docker 容器 | 虚拟机 |
|------|------------|--------|
| **启动速度** | 秒级 | 分钟级 |
| **资源占用** | 轻量（MB） | 重量级（GB） |
| **性能** | 接近原生 | 有性能损耗 |
| **隔离性** | 进程级隔离 | 系统级隔离 |
| **操作系统** | 共享宿主机内核 | 独立的操作系统 |
| **可移植性** | 高 | 低 |
| **密度** | 单机可运行数千个 | 单机通常几十个 |

**架构对比：**

```
虚拟机架构：
┌─────────────────┐ ┌─────────────────┐
│   Application   │ │   Application   │
├─────────────────┤ ├─────────────────┤
│   Bin/Libs      │ │   Bin/Libs      │
├─────────────────┤ ├─────────────────┤
│  Guest OS       │ │  Guest OS       │
├─────────────────┤ ├─────────────────┤
│  Hypervisor     │ │  Hypervisor     │
└─────────────────┘ └─────────────────┘
├─────────────────────────────────────┤
│           Host OS                   │
└─────────────────────────────────────┘

Docker 架构：
┌─────────────────┐ ┌─────────────────┐
│   Application   │ │   Application   │
├─────────────────┤ ├─────────────────┤
│   Bin/Libs      │ │   Bin/Libs      │
├─────────────────┴─┴─────────────────┤
│         Docker Engine               │
├─────────────────────────────────────┤
│           Host OS                   │
└─────────────────────────────────────┘
```
