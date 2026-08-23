#!/usr/bin/env bash
set -e

echo "[1/7] 检查系统架构"
ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64)
        TARGET_ARCH="amd64"
        ;;
    aarch64|arm64)
        TARGET_ARCH="arm64"
        ;;
    *)
        echo "当前架构暂不支持: $ARCH"
        exit 1
        ;;
esac

echo "[2/7] 查询最新版本"
if [ -z "$QMI_WEB_VERSION" ]; then
    for arg in "$@"; do
        case $arg in
            --version=*)
                QMI_WEB_VERSION="${arg#*=}"
                shift
                ;;
        esac
    done
fi

if [ -z "$QMI_WEB_VERSION" ]; then
    LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/xuanxuan1125/qmi-web/releases/latest)
    QMI_WEB_VERSION=$(echo "$LATEST_RELEASE" | grep -oP '"tag_name": "\K[^"]+')
    # If jq or grep failed, fallback to hardcoded or fail
    if [ -z "$QMI_WEB_VERSION" ]; then
        echo "无法获取最新版本，正在回退。请尝试指定版本: QMI_WEB_VERSION=v0.3.0"
        exit 1
    fi
fi
echo "使用版本: $QMI_WEB_VERSION"

echo "[3/7] 下载 QMI Web"
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

TAR_NAME="qmi-web-${QMI_WEB_VERSION}-linux-${TARGET_ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/xuanxuan1125/qmi-web/releases/download/${QMI_WEB_VERSION}/${TAR_NAME}"
SHA_URL="https://github.com/xuanxuan1125/qmi-web/releases/download/${QMI_WEB_VERSION}/SHA256SUMS"

curl -fsSLO "$DOWNLOAD_URL"
curl -fsSLO "$SHA_URL"

echo "[4/7] 校验 SHA256"
if ! grep "$TAR_NAME" SHA256SUMS | sha256sum -c -; then
    echo "SHA256 校验失败！停止安装。"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "[5/7] 安装程序"
tar -xzf "$TAR_NAME"
INSTALL_DIR="/opt/qmi-web"

# Stop existing service if running
if systemctl is-active --quiet qmi-web; then
    systemctl stop qmi-web
fi

# Create directories
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/scripts"

# Copy files
cp "qmi-web-${QMI_WEB_VERSION}-linux-${TARGET_ARCH}/bin/qmi-web" "$INSTALL_DIR/bin/"
cp "qmi-web-${QMI_WEB_VERSION}-linux-${TARGET_ARCH}/scripts/"*.sh "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/bin/qmi-web"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Provide config only if it doesn't exist
if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
    cp "qmi-web-${QMI_WEB_VERSION}-linux-${TARGET_ARCH}/config.example.yaml" "$INSTALL_DIR/config.yaml"
fi

echo "[6/7] 配置 systemd"
if [ ! -f /etc/systemd/system/qmi-web.service ]; then
    cp "qmi-web-${QMI_WEB_VERSION}-linux-${TARGET_ARCH}/qmi-web.service.example" /etc/systemd/system/qmi-web.service
fi

systemctl daemon-reload
systemctl enable qmi-web
systemctl start qmi-web

echo "[7/7] 验证 Web 服务"
sleep 2
if curl -s -I http://127.0.0.1:7580 | grep -q "200 OK"; then
    echo "服务启动成功。"
else
    echo "警告：服务可能未正常启动。请检查 systemctl status qmi-web"
fi

# Cleanup
rm -rf "$TMP_DIR"

if systemctl is-active --quiet ModemManager; then
    echo ""
    echo "警告：检测到 ModemManager 正在运行。ModemManager 可能占用 QMI 设备。"
    echo "建议同一时间仅由一个程序控制 modem。"
fi

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "QMI Web 安装完成。"
echo "访问地址："
echo "http://${IP}:7580"
