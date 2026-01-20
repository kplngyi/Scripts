#!/bin/bash

# =================================================================
# Rocky Linux 9.4 完整开荒脚本 (带进度模拟与详细反馈)
# =================================================================
set -e

# 进度条函数
draw_progress() {
    local duration=$1
    local task_name=$2
    local width=40
    echo -n "$task_name: ["
    for ((i=0; i<=width; i++)); do
        sleep 0.02
        echo -n "#"
    done
    echo "] Done!"
}

NEW_USER="kplngyi"

echo "----------------------------------------------------"
echo "🚀 启动 Rocky Linux 环境初始化程序"
echo "----------------------------------------------------"

# 1. 自动设置主机名
echo "🔍 正在检索地理位置信息..."
CITY=$(curl -s --connect-timeout 5 https://ipapi.co/city/ | tr '[:upper:]' '[:lower:]' || echo "server")
HOSTNAME="${CITY}-kplngyi"
sudo hostnamectl set-hostname "$HOSTNAME"
echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts
draw_progress 1 "设置主机名为 $HOSTNAME"

# 2. 创建用户
if ! id "$NEW_USER" &>/dev/null; then
    echo "👤 正在同步用户信息..."
    sudo useradd -m -s /bin/zsh "$NEW_USER"
    sudo usermod -aG wheel "$NEW_USER"
    draw_progress 1 "创建用户 $NEW_USER"
    echo "🔑 [ACTION] 请为新用户 $NEW_USER 设置密码:"
    sudo passwd "$NEW_USER"
else
    echo "⚠️ 用户 $NEW_USER 已存在，跳过创建。"
fi

# 3. 安装软件 (使用 DNF 自带进度条)
echo "📦 正在配置软件源并安装基础包 (这可能需要 1-2 分钟)..."
# 这里的 --setopt=progress=1 确保 DNF 输出进度条
sudo dnf install -y epel-release
sudo dnf install -y git vim zsh curl wget util-linux-user --setopt=progress=1

# 4. 配置 Vim (带下载进度)
echo "📝 正在获取 MIT 课程推荐 Vim 配置..."
USER_HOME="/home/$NEW_USER"
# -# 参数可以让 curl 显示简单的进度条
sudo curl -# -o "$USER_HOME/.vimrc" https://missing.csail.mit.edu/2020/files/vimrc
sudo chown "$NEW_USER:$NEW_USER" "$USER_HOME/.vimrc"

# 5. 配置 Oh My Zsh
echo "🐚 正在通过镜像源安装 Oh My Zsh..."
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    # 使用 sudo -u 切换用户执行
    sudo -u "$NEW_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    draw_progress 1 "Zsh 框架部署"
else
    echo "⚠️ Oh My Zsh 目录已存在。"
fi

echo "----------------------------------------------------"
echo "✅ 所有任务已完成！"
echo "主机名: $HOSTNAME"
echo "提示: 请退出当前 root 会话，尝试使用新用户登录。"
echo "命令: ssh $NEW_USER@$(curl -s ifconfig.me)"
#!/bin/bash
set -e

# =================================================================
# 功能：内存保护 + 主机名修改 + 双用户配置 + Zsh 插件集成
# =================================================================

NEW_USER="kplngyi"
VIMRC_URL="https://raw.githubusercontent.com/kplngyi/Scripts/refs/heads/main/.vimrcn"

echo "----------------------------------------------------"
echo "🚀 启动系统初始化程序..."

# 1. 内存保护：防止 DNF 被 Killed
if [ $(free -m | awk '/^Mem:/{print $2}') -lt 2048 ] && [ $(free -m | awk '/^Swap:/{print $2}') -eq 0 ]; then
    echo "🧠 正在创建 2GB 虚拟内存 (Swap)..."
    dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi

# 2. 设置主机名
CITY=$(curl -s --connect-timeout 5 https://ipapi.co/city/ | tr '[:upper:]' '[:lower:]' || echo "tokyo")
HOSTNAME="${CITY}-kplngyi"
sudo hostnamectl set-hostname "$HOSTNAME"
echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts

# 3. 安装核心软件
sudo dnf install -y epel-release
sudo dnf install -y git vim zsh curl wget util-linux-user --setopt=progress=1

# 4. 创建用户
if ! id "$NEW_USER" &>/dev/null; then
    sudo useradd -m -s /bin/zsh "$NEW_USER"
    sudo usermod -aG wheel "$NEW_USER"
    echo "🔑 [ACTION] 请为新用户 $NEW_USER 设置密码:"
    sudo passwd "$NEW_USER"
fi

# 5. 配置 Vim (Root & kplngyi)
echo "📝 部署 Vim 配置..."
curl -sL -o /root/.vimrc "$VIMRC_URL"
curl -sL -o "/home/$NEW_USER/.vimrc" "$VIMRC_URL"
chown "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.vimrc"

# 6. 部署 Oh My Zsh 及插件
echo "🐚 部署 Zsh 生产力插件..."
USER_HOME="/home/$NEW_USER"
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"

cd /tmp
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    # 安装 Oh My Zsh
    sudo -u "$NEW_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # 安装插件：自动补全 (Autosuggestions) & 语法高亮 (Highlighting)
    sudo -u "$NEW_USER" git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
    sudo -u "$NEW_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
    
    # 激活插件
    sudo -u "$NEW_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$USER_HOME/.zshrc"
fi

echo "----------------------------------------------------"
echo "✅ 初始化成功！"
echo "请重新登录：ssh $NEW_USER@$(curl -s ifconfig.me)"
echo "----------------------------------------------------"echo "----------------------------------------------------"
