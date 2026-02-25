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
