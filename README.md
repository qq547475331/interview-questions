# 面试题库

基于 Hugo + Hugo Book Theme 构建的面试题网站。

## 项目结构

```
mydocs/
├── archetypes/          # 内容模板
├── assets/              # 资源文件
├── content/             # 网站内容
│   ├── docs/            # 文档（面试题）
│   │   ├── frontend/    # 前端开发
│   │   ├── backend/     # 后端开发
│   │   ├── database/    # 数据库
│   │   ├── algorithm/   # 算法与数据结构
│   │   └── system-design/ # 系统设计
│   └── _index.md        # 首页
├── static/              # 静态文件
├── themes/              # 主题
│   └── hugo-book/       # Hugo Book Theme
├── hugo.toml            # 站点配置
└── .github/workflows/   # GitHub Actions 配置
    └── deploy.yml       # 自动部署配置
```

## 本地开发

### 前置要求

- [Hugo Extended](https://gohugo.io/installation/) (v0.146+)
- Git

### 安装步骤

1. 克隆仓库（包含子模块）
```bash
git clone --recursive https://github.com/qq547475331/interview-questions.git
cd your-repo
```

2. 启动本地服务器
```bash
hugo server --minify
```

3. 访问 http://localhost:1313

### 添加新内容

```bash
# 创建新的面试题页面
hugo new content docs/frontend/react.md

# 创建新的分类
hugo new content docs/devops/_index.md
```

## 部署

### Cloudflare Pages 配置

1. Fork 本仓库到你的 GitHub 账号

2. 在 Cloudflare Dashboard 中创建 Pages 项目
   - 连接 GitHub 仓库
   - 构建设置：
     - 构建命令：`hugo --minify`
     - 构建输出目录：`public`
   - 环境变量：
     - `HUGO_VERSION`: `0.145.0`

3. 或者使用 GitHub Actions 自动部署（已配置）
   - 在 GitHub 仓库 Settings > Secrets 中添加：
     - `CLOUDFLARE_API_TOKEN`: Cloudflare API Token
     - `CLOUDFLARE_ACCOUNT_ID`: Cloudflare Account ID

## 内容格式

面试题使用 Markdown 格式，支持以下特性：

- 代码高亮
- 表格
- 提示框（hint shortcode）
- 折叠内容（details shortcode）
- 数学公式（KaTeX）
- Mermaid 图表

### 示例

```markdown
---
title: JavaScript 面试题
weight: 1
---

# JavaScript 面试题

## 1. 什么是闭包？

**问题：** 请解释什么是闭包？

**答案：**

闭包是指有权访问另一个函数作用域中的变量的函数...

```javascript
function createCounter() {
  let count = 0;
  return function() {
    return ++count;
  };
}
```
```

## 主题定制

### 自定义样式

编辑 `assets/_custom.scss`：

```scss
@import "plugins/numbered";

// 自定义样式
.book-page {
  max-width: 900px;
}
```

### 自定义变量

编辑 `assets/_variables.scss`：

```scss
$color-primary: #0055ff;
$color-light: #f8f9fa;
```

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/new-questions`)
3. 提交更改 (`git commit -am 'Add some questions'`)
4. 推送到分支 (`git push origin feature/new-questions`)
5. 创建 Pull Request

## 许可证

MIT License
测试 GitHub Actions 自动部署
