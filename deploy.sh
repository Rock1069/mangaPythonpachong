#!/bin/bash
# ============================================
# 漫画柜阅读器 - Debian 一键部署脚本
# 适用于 Debian 11/12 (Bullseye/Bookworm)
# 运行方式: sudo bash deploy.sh
# ============================================
set -e

APP_NAME="manga-reader"
APP_DIR="/opt/${APP_NAME}"
APP_USER="manga"
VENV_DIR="${APP_DIR}/venv"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

echo "======================================"
echo "  漫画柜阅读器 - Debian 部署脚本"
echo "======================================"
echo ""

# ---------- 1. 检查是否为 root ----------
if [ "$(id -u)" != "0" ]; then
    echo "❌ 请使用 sudo 运行此脚本: sudo bash deploy.sh"
    exit 1
fi

# ---------- 2. 安装系统依赖 ----------
echo ">>> [1/6] 安装系统依赖..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nginx curl

# ---------- 3. 创建专用用户 ----------
echo ">>> [2/6] 创建专用用户 ${APP_USER}..."
if ! id -u ${APP_USER} >/dev/null 2>&1; then
    useradd -r -s /bin/false -m ${APP_USER}
    echo "  用户 ${APP_USER} 已创建"
else
    echo "  用户 ${APP_USER} 已存在，跳过"
fi

# ---------- 4. 部署代码 ----------
echo ">>> [3/6] 部署代码到 ${APP_DIR}..."

# 如果当前目录有代码，复制过去；否则需要手动上传
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "${SCRIPT_DIR}/requirements.txt" ]; then
    echo "  从 ${SCRIPT_DIR} 复制项目文件..."
    mkdir -p "${APP_DIR}"
    cp -r "${SCRIPT_DIR}"/* "${APP_DIR}/"
    # 排除自身
    rm -f "${APP_DIR}/deploy.sh"
else
    echo "  ⚠ 未检测到项目文件，请将代码放置在 ${APP_DIR}"
    echo "  你可以手动执行: git clone <repo> ${APP_DIR}"
fi

# ---------- 5. 创建虚拟环境并安装依赖 ----------
echo ">>> [4/6] 创建 Python 虚拟环境..."
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
fi

echo ">>> [5/6] 安装 Python 依赖..."
"${VENV_DIR}/bin/pip" install --upgrade pip -q
"${VENV_DIR}/bin/pip" install -r "${APP_DIR}/requirements.txt" -q

# ---------- 6. 创建 systemd 服务 ----------
echo ">>> [6/6] 创建 systemd 服务..."

cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=漫画柜阅读器 API 服务
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
ExecStart=${VENV_DIR}/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment="MANGA_HOST=0.0.0.0"
Environment="MANGA_PORT=8000"
Environment="MANGA_PAGE_DELAY=1.0"

# 安全加固
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=${APP_DIR}
ReadOnlyPaths=/usr

# 日志
StandardOutput=journald
StandardError=journald
SyslogIdentifier=${APP_NAME}

[Install]
WantedBy=multi-user.target
EOF

# 设置权限
chown -R ${APP_USER}:${APP_USER} "${APP_DIR}"

# 重载 systemd 并启动服务
systemctl daemon-reload
systemctl enable "${APP_NAME}"
systemctl restart "${APP_NAME}"

echo ""
echo "======================================"
echo "  ✅ 部署完成！"
echo "======================================"
echo ""
echo "  服务状态检查:"
echo "    sudo systemctl status ${APP_NAME}"
echo ""
echo "  查看日志:"
echo "    sudo journalctl -u ${APP_NAME} -f"
echo ""
echo "  API 地址: http://$(hostname -I | awk '{print $1}'):8000/"
echo ""
echo "--- 可选：配置 Nginx 反向代理 ---"
echo "  编辑 /etc/nginx/sites-available/${APP_NAME} 并启用"
echo "  配置示例见: ${APP_DIR}/nginx-example.conf"
echo ""
echo "  重启服务:"
echo "    sudo systemctl restart ${APP_NAME}"
echo ""
