---
title: Linux 系统
weight: 1
---

# Linux 系统面试题

## 1. Linux 文件系统权限

**问题：** 如何理解 Linux 文件权限 `drwxr-xr-x`？如何修改文件权限？

**答案：**

Linux 文件权限由 10 个字符组成：

```
drwxr-xr-x
│└┬┘└┬┘└┬┘
│ │  │  │
│ │  │  └── 其他用户权限
│ │  └───── 所属组权限
│ └──────── 所有者权限
└────────── 文件类型（d=目录，-=文件，l=链接）
```

权限字符含义：
- `r` (4)：读权限
- `w` (2)：写权限
- `x` (1)：执行权限

**修改权限命令：**

```bash
# 数字方式
chmod 755 file.txt    # rwxr-xr-x
chmod 644 file.txt    # rw-r--r--

# 符号方式
chmod u+x file.txt    # 给所有者添加执行权限
chmod g-w file.txt    # 去掉组的写权限
chmod o=r file.txt    # 设置其他用户只有读权限

# 修改所有者
chown user:group file.txt
```

---

## 2. 常用性能监控命令

**问题：** 列举常用的 Linux 性能监控命令及其用途。

**答案：**

| 命令 | 用途 | 常用示例 |
|------|------|----------|
| `top` / `htop` | 实时查看系统进程和资源使用 | `top -p PID` 查看指定进程 |
| `ps` | 查看进程状态 | `ps aux`, `ps -ef` |
| `vmstat` | 查看虚拟内存统计 | `vmstat 1 5` 每秒采样，共5次 |
| `iostat` | 查看IO统计 | `iostat -x 1` |
| `netstat` / `ss` | 查看网络连接 | `ss -tuln`, `netstat -anp` |
| `df` | 查看磁盘空间 | `df -h` |
| `du` | 查看目录大小 | `du -sh /path` |
| `free` | 查看内存使用 | `free -h` |
| `sar` | 系统活动报告 | `sar -u 1 5` CPU监控 |
| `lsof` | 查看打开的文件 | `lsof -i :80` |

---

## 3. 进程管理

**问题：** 如何在 Linux 中查看、终止和管理进程？

**答案：**

```bash
# 查找进程
ps aux | grep nginx
pgrep nginx
pidof nginx

# 终止进程
kill PID          # 正常终止
kill -9 PID       # 强制终止
killall nginx     # 按名称终止
pkill nginx       # 按名称终止

# 后台运行
nohup command &
command &

# 查看后台任务
jobs

# 将后台任务调到前台
fg %1

# 将前台任务放到后台（先按 Ctrl+Z 暂停）
bg %1

# 使用 screen/tmux 会话管理
screen -S mysession    # 创建会话
screen -r mysession    # 恢复会话
tmux new -s mysession  # 创建会话
tmux attach -t mysession # 恢复会话
```

---

## 4. 网络故障排查

**问题：** 服务器无法访问外网，如何排查？

**答案：**

**排查步骤：**

1. **检查网络接口**
   ```bash
   ip addr
   ifconfig
   ```

2. **检查路由表**
   ```bash
   ip route
   route -n
   ```

3. **检查DNS解析**
   ```bash
   cat /etc/resolv.conf
   nslookup baidu.com
   dig baidu.com
   ```

4. **测试网络连通性**
   ```bash
   ping 8.8.8.8          # 测试外网连通
   ping baidu.com        # 测试DNS解析
   traceroute baidu.com  # 追踪路由
   mtr baidu.com         # 综合网络诊断
   ```

5. **检查防火墙**
   ```bash
   iptables -L -n        # 查看iptables规则
   firewall-cmd --list-all  # firewalld
   ufw status            # Ubuntu UFW
   ```

6. **检查端口监听**
   ```bash
   ss -tuln
   netstat -tuln
   ```

---

## 5. 日志分析

**问题：** 如何查看和分析 Linux 系统日志？

**答案：**

**常见日志文件位置：**

```
/var/log/messages      # 系统通用日志（CentOS）
/var/log/syslog        # 系统通用日志（Ubuntu）
/var/log/auth.log      # 认证日志
/var/log/secure        # 安全日志（CentOS）
/var/log/nginx/        # Nginx 日志
/var/log/apache2/      # Apache 日志
/var/log/mysql/        # MySQL 日志
/var/log/kern.log      # 内核日志
/var/log/dmesg         # 启动日志
```

**常用日志命令：**

```bash
# 实时查看日志
tail -f /var/log/syslog

# 查看最后100行
tail -n 100 /var/log/syslog

# 查看包含关键字的日志
grep "error" /var/log/syslog

# 使用 journalctl（systemd）
journalctl -u nginx          # 查看服务日志
journalctl -f                # 实时查看
journalctl --since "1 hour ago"
journalctl -p err            # 只看错误级别

# 日志分析工具
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn  # IP统计
```

---

## 6. Shell 脚本基础

**问题：** 编写一个 Shell 脚本，监控磁盘使用率，超过80%时发送告警。

**答案：**

```bash
#!/bin/bash

# 磁盘监控脚本
THRESHOLD=80
EMAIL="admin@example.com"

# 获取磁盘使用率
df -h | awk 'NR>1 {
    gsub(/%/,"",$5)
    if ($5 > threshold) {
        print "Warning: Disk usage on " $6 " is " $5 "%"
        system("echo \"Disk usage alert: " $6 " " $5 "%\" | mail -s \"Disk Alert\" " email)
    }
}' threshold=$THRESHOLD email=$EMAIL

# 更简洁的版本
df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
    usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
    partition=$(echo $output | awk '{ print $2 }')
    if [ $usage -ge $THRESHOLD ]; then
        echo "Running out of space: $partition ($usage%)"
    fi
done
```

---

## 7. 定时任务 Crontab

**问题：** 如何设置定时任务？Crontab 时间格式是什么？

**答案：**

**Crontab 格式：**

```
* * * * * command
│ │ │ │ │
│ │ │ │ └── 星期几 (0-7, 0和7都是周日)
│ │ │ └──── 月份 (1-12)
│ │ └────── 日期 (1-31)
│ └──────── 小时 (0-23)
└────────── 分钟 (0-59)
```

**常用示例：**

```bash
# 编辑 crontab
crontab -e

# 每分钟执行
* * * * * /path/to/script.sh

# 每5分钟执行
*/5 * * * * /path/to/script.sh

# 每小时执行
0 * * * * /path/to/script.sh

# 每天凌晨2点执行
0 2 * * * /path/to/script.sh

# 每周一执行
0 0 * * 1 /path/to/script.sh

# 每月1号执行
0 0 1 * * /path/to/script.sh

# 查看 crontab 日志
tail -f /var/log/cron
```

---

## 8. 文件查找和处理

**问题：** 如何查找大文件、老文件，以及如何批量处理文件？

**答案：**

```bash
# 查找大文件（超过100MB）
find / -type f -size +100M -exec ls -lh {} \;
find / -type f -size +100M 2>/dev/null | head -10

# 查找7天前的文件并删除
find /path/to/logs -name "*.log" -mtime +7 -delete
find /path/to/logs -name "*.log" -mtime +7 -exec rm {} \;

# 查找并替换文件内容
find . -type f -name "*.txt" -exec sed -i 's/old/new/g' {} \;

# 批量重命名
for file in *.txt; do mv "$file" "${file%.txt}.bak"; done

# 查找包含特定内容的文件
grep -r "keyword" /path/to/search
grep -rl "keyword" /path/to/search  # 只显示文件名

# 统计代码行数
find . -name "*.py" -o -name "*.js" | xargs wc -l
cloc .  # 使用 cloc 工具
```
