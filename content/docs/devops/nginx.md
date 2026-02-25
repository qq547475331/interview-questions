---
title: Nginx
weight: 5
---

# Nginx 面试题

## 1. Nginx 核心特性

**问题：** Nginx 有哪些核心特性？

**答案：**

| 特性 | 说明 |
|------|------|
| **高并发** | 事件驱动架构，支持数万并发连接 |
| **低内存** | 处理静态文件内存占用低 |
| **反向代理** | 支持 HTTP、HTTPS、TCP、UDP 代理 |
| **负载均衡** | 多种负载均衡算法 |
| **静态缓存** | 高效的静态文件缓存 |
| **热部署** | 支持配置热加载、平滑升级 |
| **模块化** | 丰富的第三方模块 |

---

## 2. Nginx 配置文件结构

**问题：** Nginx 配置文件的结构是怎样的？

**答案：**

```nginx
# 全局块
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# events 块
events {
    worker_connections 1024;
    use epoll;
}

# http 块
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    # 性能优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    gzip on;
    
    # server 块
    server {
        listen 80;
        server_name example.com;
        
        location / {
            root /var/www/html;
            index index.html;
        }
    }
}
```

---

## 3. 负载均衡配置

**问题：** Nginx 如何实现负载均衡？

**答案：**

```nginx
upstream backend {
    # 轮询（默认）
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    
    # 权重
    server 192.168.1.103:8080 weight=5;
    
    # 备用服务器
    server 192.168.1.104:8080 backup;
    
    # 最大失败次数和失败时间
    server 192.168.1.105:8080 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**负载均衡算法：**

| 算法 | 说明 | 配置 |
|------|------|------|
| **round_robin** | 轮询（默认） | 无需配置 |
| **least_conn** | 最少连接 | `least_conn;` |
| **ip_hash** | IP 哈希 | `ip_hash;` |
| **fair** | 按响应时间 | 第三方模块 |
| **url_hash** | URL 哈希 | 第三方模块 |

---

## 4. 反向代理配置

**问题：** Nginx 反向代理的常见配置有哪些？

**答案：**

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:8080;
        
        # 设置请求头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲区设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 错误处理
        proxy_intercept_errors on;
        error_page 500 502 503 504 /50x.html;
    }
}
```

---

## 5. 静态资源优化

**问题：** 如何优化 Nginx 静态资源服务？

**答案：**

```nginx
server {
    listen 80;
    server_name static.example.com;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        root /var/www/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # 开启 gzip
        gzip on;
        gzip_types text/css application/javascript;
    }
    
    # 防盗链
    location /images/ {
        valid_referers none blocked server_names *.example.com;
        if ($invalid_referer) {
            return 403;
        }
    }
    
    # 限速
    location /download/ {
        limit_rate 100k;
    }
}
```

---

## 6. HTTPS 配置

**问题：** 如何配置 Nginx HTTPS？

**答案：**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL 证书
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # SSL 优化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

---

## 7. 限流配置

**问题：** Nginx 如何实现限流？

**答案：**

```nginx
# 定义限流区域
limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

server {
    listen 80;
    
    location / {
        # 请求限流
        limit_req zone=req_limit burst=20 nodelay;
        
        # 连接限流
        limit_conn conn_limit 10;
        
        proxy_pass http://backend;
    }
    
    # 白名单
    location /api/ {
        limit_req zone=req_limit burst=100 nodelay;
        proxy_pass http://backend;
    }
}
```

---

## 8. 常用命令

**问题：** Nginx 常用命令有哪些？

**答案：**

```bash
# 启动
nginx

# 停止
nginx -s stop      # 快速停止
nginx -s quit      # 优雅停止

# 重载配置
nginx -s reload

# 重新打开日志文件
nginx -s reopen

# 测试配置
nginx -t
nginx -t -c /etc/nginx/nginx.conf

# 查看版本
nginx -v
nginx -V           # 详细版本信息

# 指定配置文件启动
nginx -c /etc/nginx/nginx.conf
```

---

## 9. Nginx 负载均衡与真实 IP

**问题：** Nginx 的 `hash $remote_addr` 和 `ip_hash` 有什么区别？在有前端 CDN/代理的情况下，如何获取客户端真实 IP？

**答案：**

**hash vs ip_hash：**

| 指令 | 说明 | 使用场景 |
|------|------|----------|
| `ip_hash` | 基于客户端 IP 的哈希 | 保持会话，但只能用于 HTTP |
| `hash $remote_addr` | 基于任意变量的哈希 | 更灵活，可用于 TCP/UDP |

```nginx
# ip_hash（仅 HTTP）
upstream backend {
    ip_hash;
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

# hash $remote_addr（通用）
upstream backend {
    hash $remote_addr consistent;  # consistent 使用一致性哈希
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

# 基于 URI 的哈希（适合缓存场景）
upstream backend {
    hash $request_uri consistent;
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}
```

**获取真实 IP：**

```nginx
# 在 CDN/代理后的配置
server {
    listen 80;
    
    # 设置真实 IP 来源（CDN/代理的 IP 段）
    set_real_ip_from 10.0.0.0/8;      # 内网代理
    set_real_ip_from 172.16.0.0/12;   # 内网代理
    set_real_ip_from 192.168.0.0/16;  # 内网代理
    set_real_ip_from 103.21.244.0/22; # Cloudflare
    
    # 从哪个 Header 获取真实 IP
    real_ip_header X-Forwarded-For;
    
    # 递归解析 X-Forwarded-For
    real_ip_recursive on;
    
    location / {
        proxy_pass http://backend;
        
        # 传递真实 IP 给后端
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**X-Forwarded-For 格式：**
```
X-Forwarded-For: client, proxy1, proxy2
# 最左边的 client 是真实客户端 IP
```

---

## 10. Nginx 性能优化参数

**问题：** 请列举 3 个能显著提升 Nginx 并发能力的配置参数。

**答案：**

```nginx
# /etc/nginx/nginx.conf

# 1. worker 进程数（通常设置为 CPU 核心数）
worker_processes auto;  # 或 worker_processes 4;

# 2. 单个 worker 的最大连接数
# 总并发连接数 = worker_processes * worker_connections
events {
    worker_connections 65535;  # 默认 512，生产建议 65535
    use epoll;                 # Linux 高性能网络模型
    multi_accept on;           # 一个 worker 同时接受多个连接
}

# 3. 文件描述符限制
worker_rlimit_nofile 65535;  # 与 worker_connections 匹配

# 4. keepalive 优化
http {
    # 长连接保持时间
    keepalive_timeout 60;
    
    # 单个长连接最大请求数
    keepalive_requests 1000;
    
    # 上游 keepalive
    upstream backend {
        server 127.0.0.1:8080;
        keepalive 100;  # 保持 100 个空闲连接
    }
}

# 5. 缓冲区优化
http {
    # 客户端请求头缓冲区
    client_header_buffer_size 4k;
    large_client_header_buffers 4 8k;
    
    # 客户端请求体缓冲区
    client_body_buffer_size 128k;
    client_max_body_size 50m;
    
    # 代理缓冲区
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    proxy_busy_buffers_size 8k;
}

# 6. TCP 优化
http {
    # 启用 TCP_NOPUSH（与 sendfile 一起使用）
    tcp_nopush on;
    
    # 启用 TCP_NODELAY（小数据包立即发送）
    tcp_nodelay on;
    
    # 开启 sendfile（零拷贝）
    sendfile on;
}
```

**系统级优化：**

```bash
# /etc/sysctl.conf

# 增大文件描述符限制
fs.file-max = 655350

# TCP 连接优化
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# 端口复用
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0

# 应用配置
sysctl -p
```

---

## 11. Nginx 平滑升级原理

**问题：** Nginx 在不中断业务的情况下如何完成版本升级或配置重新加载（Reload）的底层原理是什么？

**答案：**

**Reload 原理：**

```bash
nginx -s reload
```

1. **Master 进程检查配置文件语法**
2. **Master 启动新的 Worker 进程**
3. **旧 Worker 停止接受新连接**
4. **旧 Worker 处理完当前请求后退出**
5. **新 Worker 接管请求**

```
Master
├── Worker 1 (old) → 处理完请求后退出
├── Worker 2 (old) → 处理完请求后退出
├── Worker 3 (new) → 接受新请求
└── Worker 4 (new) → 接受新请求
```

**平滑升级（二进制文件）：**

```bash
# 1. 编译新版本 Nginx
./configure --prefix=/usr/local/nginx-new
make

# 2. 备份旧版本
mv /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx.old

# 3. 替换二进制文件
cp /usr/local/nginx-new/objs/nginx /usr/local/nginx/sbin/

# 4. 发送 USR2 信号（启动新 Master）
kill -USR2 $(cat /usr/local/nginx/logs/nginx.pid)

# 5. 旧 Master 重命名 pid 文件
# nginx.pid → nginx.pid.oldbin

# 6. 发送 WINCH 信号（优雅关闭旧 Worker）
kill -WINCH $(cat /usr/local/nginx/logs/nginx.pid.oldbin)

# 7. 验证新版本正常后，关闭旧 Master
kill -QUIT $(cat /usr/local/nginx/logs/nginx.pid.oldbin)
```

**信号说明：**

| 信号 | 作用 |
|------|------|
| `TERM/INT` | 快速停止 |
| `QUIT` | 优雅停止 |
| `HUP` | 重新加载配置（相当于 reload） |
| `USR1` | 重新打开日志文件（日志切割） |
| `USR2` | 启动新的 Master（平滑升级） |
| `WINCH` | 优雅关闭 Worker |

**零停机升级流程图：**

```
时间线 ────────────────────────────────────────>

旧 Master + Workers
    │
    ├── USR2 ──→ 新 Master + 新 Workers
    │               │
    │               ├── 新请求走新 Workers
    │               │
    ├── WINCH ──→ 旧 Workers 优雅退出
    │               │
    │               ├── 新 Master 独立运行
    │               │
    └── QUIT ──→ 旧 Master 退出
                    │
                    └── 升级完成
```
