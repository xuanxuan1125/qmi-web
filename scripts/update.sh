#!/usr/bin/env bash
set -e

INSTALL_DIR="/opt/qmi-web"

if [ ! -f "$INSTALL_DIR/bin/qmi-web" ]; then
    echo "QMI Web 未安装在 $INSTALL_DIR，请运行 install.sh 进行安装。"
    exit 1
fi

echo "正在查询最新版本..."
LATEST_RELEASE=$(curl -fsSL https://api.github.com/repos/xuanxuan1125/qmi-web/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep -oP '"tag_name": "\K[^"]+')

if [ -z "$LATEST_VERSION" ]; then
    echo "无法获取最新版本。"
    exit 1
fi

CURRENT_VERSION=$("$INSTALL_DIR/bin/qmi-web" --version 2>/dev/null | head -n 1 | awk '{print $NF}' || echo "unknown")

if [ "$CURRENT_VERSION" = "${LATEST_VERSION#v}" ] || [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "当前已是最新版 ($CURRENT_VERSION)。"
    exit 0
fi

echo "发现新版本: $LATEST_VERSION (当前版本: $CURRENT_VERSION)"

ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64) TARGET_ARCH="amd64" ;;
    aarch64|arm64) TARGET_ARCH="arm64" ;;
    *) echo "架构不支持: $ARCH"; exit 1 ;;
esac

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

TAR_NAME="qmi-web-${LATEST_VERSION}-linux-${TARGET_ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/xuanxuan1125/qmi-web/releases/download/${LATEST_VERSION}/${TAR_NAME}"
SHA_URL="https://github.com/xuanxuan1125/qmi-web/releases/download/${LATEST_VERSION}/SHA256SUMS"

echo "正在下载..."
curl -fsSLO "$DOWNLOAD_URL"
curl -fsSLO "$SHA_URL"

if ! grep "$TAR_NAME" SHA256SUMS | sha256sum -c -; then
    echo "SHA256 校验失败！"
    rm -rf "$TMP_DIR"
    exit 1
fi

tar -xzf "$TAR_NAME"

echo "备份旧版本..."
cp "$INSTALL_DIR/bin/qmi-web" "$INSTALL_DIR/bin/qmi-web.old"

echo "停止服务..."
systemctl stop qmi-web

echo "替换文件..."
cp "qmi-web-${LATEST_VERSION}-linux-${TARGET_ARCH}/bin/qmi-web" "$INSTALL_DIR/bin/qmi-web"
cp "qmi-web-${LATEST_VERSION}-linux-${TARGET_ARCH}/scripts/"*.sh "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/bin/qmi-web"
chmod +x "$INSTALL_DIR/scripts/"*.sh

echo "启动服务..."
systemctl start qmi-web

sleep 2
if curl -s -I http://127.0.0.1:7580 | grep -q "200 OK"; then
    echo "更新成功。"
else
    echo "更新失败，健康检查不通过，正在自动恢复旧版本..."
    systemctl stop qmi-web
    mv "$INSTALL_DIR/bin/qmi-web.old" "$INSTALL_DIR/bin/qmi-web"
    systemctl start qmi-web
    echo "已回滚至旧版本。"
fi

rm -rf "$TMP_DIR"
