#!/bin/bash

# =================================================================
# 脚本名称: 0setup_auto.sh
# 适用系统: Rocky Linux 9.4+ (RHEL 系列)
# 功能: 内存保护, 主机名修改, 创建用户 (密码固定), Vim/Zsh 生产力环境
# =================================================================

set -e

# --- 变量配置 ---
NEW_USER="kplngyi"
USER_PASSWORD="1"
VIMRC_URL="https://raw.githubusercontent.com/kplngyi/Scripts/refs/heads/main/.vimrc"

# --- 进度条函数 ---
draw_progress() {
    local task_name=$1
    local width=40
    echo -n "$task_name: ["
    for ((i=0; i<=width; i++)); do
        sleep 0.01
        echo -n "#"
    done
    echo "] Done!"
}

echo "----------------------------------------------------"
echo "🌟 启动 Rocky Linux 环境初始化程序 (自动密码版)"
echo "----------------------------------------------------"

# 1️⃣ 内存保护 (低内存机器防止 DNF 被 Killed)
echo "🧠 检查内存状态..."
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
SWAP_EXISTS=$(free -m | awk '/^Swap:/{print $2}')

if [ "$SWAP_EXISTS" -eq 0 ] && [ "$TOTAL_MEM" -lt 2000 ]; then
    echo "⚠️ 内存仅为 ${TOTAL_MEM}MB，正在创建 2GB Swap..."
    sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "✅ Swap 虚拟内存已启用。"
fi

# 2️⃣ 获取 IPv4 地理位置并设置主机名
echo "🌍 正在检索地理位置..."
CITY=$(curl -4 -s --connect-timeout 5 https://ipapi.co/city/ | tr '[:upper:]' '[:lower:]' || echo "tokyo")
IPV4_ADDR=$(curl -4 -s --connect-timeout 5 ifconfig.me || echo "127.0.0.1")
HOSTNAME="${CITY}-kplngyi"

echo "🏷️ 设置主机名为: $HOSTNAME"
sudo hostnamectl set-hostname "$HOSTNAME"
echo "$IPV4_ADDR $HOSTNAME" | sudo tee -a /etc/hosts
draw_progress "主机名设置"

# 3️⃣ 安装基础软件
echo "📦 安装基础软件..."
sudo dnf install -y epel-release
sudo dnf install -y git vim zsh curl wget util-linux-user --setopt=progress=1
draw_progress "基础软件安装"

# 4️⃣ 创建新用户并设置密码
if ! id "$NEW_USER" &>/dev/null; then
    echo "👤 创建新用户 $NEW_USER 并设置默认密码为 $USER_PASSWORD..."
    sudo useradd -m -s /bin/zsh "$NEW_USER"
    sudo usermod -aG wheel "$NEW_USER"
    echo "$NEW_USER:$USER_PASSWORD" | sudo chpasswd
    draw_progress "用户创建"
else
    echo "⚠️ 用户 $NEW_USER 已存在，跳过创建。"
fi

# 5️⃣ 配置 Vim (Root 和新用户)
echo "📝 部署 Vim 配置..."
curl -sL -o /root/.vimrc "$VIMRC_URL"
USER_HOME="/home/$NEW_USER"
curl -sL -o "$USER_HOME/.vimrc" "$VIMRC_URL"
sudo chown "$NEW_USER:$NEW_USER" "$USER_HOME/.vimrc"
draw_progress "Vim 配置"

# 6️⃣ 安装 Oh My Zsh 及插件
echo "🐚 部署 Oh My Zsh 及插件..."
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
cd /tmp
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    # 安装 Oh My Zsh (非交互)
    sudo -u "$NEW_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # 安装插件
    sudo -u "$NEW_USER" git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
    sudo -u "$NEW_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

    # 激活插件
    sudo -u "$NEW_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$USER_HOME/.zshrc"
    draw_progress "Zsh 插件集成"
fi

# 7️⃣ 完成提示
echo "----------------------------------------------------"
echo "✅ 初始化完成！"
echo "主机名: $HOSTNAME"
echo "公网 IPv4: $IPV4_ADDR"
echo "Swap: $(swapon --show || echo '未启用')"
echo "用户: $NEW_USER, 密码: $USER_PASSWORD"
echo "请使用命令登录新用户: ssh $NEW_USER@$IPV4_ADDR"
echo "----------------------------------------------------"
