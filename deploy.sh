#!/bin/bash

# 面试题库部署脚本
# 用于本地构建并推送到 GitHub，触发 GitHub Actions 自动部署到 Cloudflare Pages

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

info "开始部署流程..."
echo ""

# 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    info "检测到未提交的更改:"
    git status -s
    echo ""
    read -p "是否提交这些更改? (y/n): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        read -p "输入提交信息: " commit_msg
        if [[ -z "$commit_msg" ]]; then
            commit_msg="Update: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        git add .
        git commit -m "$commit_msg"
        success "更改已提交"
    else
        warning "跳过提交更改"
    fi
else
    info "没有未提交的更改"
fi

echo ""

# 检查远程仓库地址
REMOTE_URL=$(git remote get-url origin)
info "当前远程仓库: $REMOTE_URL"

# 如果是 HTTPS 地址，提示用户
if [[ $REMOTE_URL == https://* ]]; then
    warning "检测到 HTTPS 地址，建议使用 SSH 地址"
    info "正在切换到 SSH 地址..."
    git remote set-url origin git@github.com:qq547475331/interview-questions.git
    success "已切换到 SSH 地址"
fi

echo ""

# 拉取最新代码
info "拉取远程最新代码..."
if git pull origin main; then
    success "代码已更新"
else
    error "拉取代码失败"
    exit 1
fi

echo ""

# 本地构建（可选，用于预览）
read -p "是否在本地构建预览? (y/n): " build_local
if [[ $build_local == [yY] || $build_local == [yY][eE][sS] ]]; then
    info "开始本地构建..."
    if command -v hugo &> /dev/null; then
        hugo --minify
        success "本地构建完成"
        info "预览地址: http://localhost:1313"
        info "运行 'hugo server --minify' 启动预览服务器"
    else
        error "未找到 Hugo，跳过本地构建"
    fi
    echo ""
fi

# 推送到 GitHub 触发部署
info "推送到 GitHub 触发自动部署..."
if git push origin main; then
    success "推送成功！"
    echo ""
    info "GitHub Actions 将自动构建并部署到 Cloudflare Pages"
    info "查看部署状态: https://github.com/qq547475331/interview-questions/actions"
else
    error "推送失败"
    exit 1
fi

echo ""
success "部署流程完成！"
info "网站地址: https://interview-questions.pages.dev"
