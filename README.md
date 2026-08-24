# QMI Web

面向 QMI 蜂窝模组的轻量级 SMS-only Web 管理平台。

[English](README.en.md) | 简体中文

QMI Web 旨在提供一个干净、现代、易于使用的本地短信管理面板，内置全新的 V3 VoCat 风格前端（支持 Light/Dark 模式），以及使用 Go 语言开发的稳定后端和 SQLite 数据库引擎。通过静态编译，QMI Web 提供跨架构的原生二进制单文件部署。

> **当前版本：v1.0.0**

## 界面预览

- 现代化的 Dashboard
- 响应式侧边栏和完整移动端适配
- 短信双栏沉浸式阅读与通知机制
- 真实的文本日志提取与导出功能
- **[新] 自动深浅色主题模式**：跟随系统主题实时无缝切换，并支持设置持久化与手动覆盖

## 安全边界 (SMS-only)

QMI Web 秉承严格的纯短信管理定位，不干涉也不建立网络连接：
- **不主动拨号**：不触发 WDS 数据拨号
- **不干涉路由**：不建立或修改主机的默认蜂窝路由、DNS、NAT 或 APN
- **轻量级操作**：只通过 QMI 协议获取模组信息（信号、卡状态）并被动接收短信（WMS）
- **无设备硬写**：不支持发送短信、自动下载 MMS、强制改写设备参数等高危操作

## 快速一键安装

QMI Web v1.0.0 推荐直接运行官方安装脚本。该脚本自动下载 Linux amd64/arm64 版本的二进制程序（内嵌前端静态文件）并配置 `systemd`，无需自行安装 Go / Node / Docker 链：

```bash
curl -fsSL https://raw.githubusercontent.com/xuanxuan1125/qmi-web/main/scripts/install.sh | sudo bash
```

**更新/回滚版本：**
```bash
sudo /opt/qmi-web/scripts/update.sh
```

**卸载：**
```bash
sudo /opt/qmi-web/scripts/uninstall.sh
```

## 支持架构与设备

- **架构**：`Linux amd64`，`Linux arm64` (aarch64)。支持部署在工控机、Raspberry Pi 架构设备或支持 Linux 的 ARM NAS 及 OpenStick 设备上。
- **设备**：兼容大多数使用 QMI 协议的 `cdc-wdm` 蜂窝模组（如移远等常见 4G/5G 模组）。

## ⚠️ 冲突提醒 (ModemManager)

如果你系统上已经运行了 `ModemManager`、`VoHive`、`VoCat` 或 `SimAdmin` 等服务，它们很可能会与 QMI Web 同时争抢同一个模组设备的控制权，导致设备状态异常或短信漏读。

**强烈建议：同一时间只由一个管理程序接管目标 `/dev/cdc-wdmX` 设备。**
（安装脚本会尝试检测 ModemManager 并发出警告，但绝不会擅自停止你的系统服务）

## 手动部署 (Docker Compose)

如果您仍然希望通过 Docker 进行部署，参考此流程。但由于 v1.0.0 已经是无需外部依赖的编译型单文件后端，基于 systemd 原生运行将更轻量、更快且更方便穿透管理 `/dev` 设备节点。

```bash
# 请自行根据需求适配 qmi-web 的 volumes
docker run -d --name qmi-web --device=/dev/cdc-wdm0 -p 7580:7580 ghcr.io/xuanxuan1125/qmi-web:1.0.0
```

## 许可证
MIT License
