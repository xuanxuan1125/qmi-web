# QMI Web

[English](README.md) | 简体中文

开源、SMS-only 的 QMI 蜂窝模块与短信管理面板。

## 项目简介

QMI Web 使用 Go 后端、Vue/TypeScript WebUI 和 SQLite，管理 QMI 模块状态并接收短信。项目只接收短信，不提供移动数据拨号功能。

## 核心功能

- DMS、UIM、NAS、只读 WDS 状态和 WMS 读取。
- UCS2、长短信重组、SQLite 持久化和重启去重。
- 登录保护、状态面板、通知配置和诊断信息。
- `no-device` 默认模式，以及显式选择的 `hardware` 模式。

## 截图

仓库只接受 Mock 或脱敏截图；真实号码、IMEI、IMSI、ICCID、短信正文和内部地址不得上传。可参考 `docs/images/README.md`。

## 当前状态

当前版本为 v0.2.0。真实 QMI SMS 接收、非 root 硬件访问、生产硬件模式、重启恢复和去重已经验证。24/48 小时长期 soak 仍建议由部署者自行完成。

## 支持的平台

目前正式离线包针对 Linux amd64。Docker Engine、Docker Compose、bash/coreutils 是运行前提；不需要 Go、Node、npm 或互联网。

## 硬件要求

需要一个由 Linux `qmi_wwan` 驱动提供的 `/dev/cdc-wdmX` 字符设备。安装器会动态检查 sysfs、USB VID:PID、驱动、字符设备 major/minor 和占用情况；多个候选设备时必须明确选择，设备忙时不会抢占。

## 软件要求

在线源码开发需要 Go 1.26.3、Node.js 26、npm 和 Docker。离线包已经包含 Go、Node/npm、npm cache、Go vendor、CA 证书和构建脚本。

## 快速安装

```bash
sudo ./install.sh
```

默认选择 `no-device`。首次登录为 `admin` / `admin`，登录后立即修改密码。

## 完全离线安装

```bash
tar --zstd -xf qmi-web-offline-linux-amd64-v0.2.0.tar.zst
cd qmi-web-offline-linux-amd64-v0.2.0
sudo ./install.sh
```

安装器校验清单、离线构建前端和 Go、构建 scratch 镜像、启动容器并检查 `/health`、`/ready`、`/version` 与 SQLite integrity。不会自动联网或 Docker pull。

## no-device 模式

这是安全默认值，不映射任何硬件，适合首次安装、升级前检查和开发。它不会影响宿主机的 USB、路由或 DNS。

## hardware 模式

hardware 模式必须显式选择一个动态检测到的 `/dev/cdc-wdmX`。容器使用 UID/GID `65532:65532`、`CapDrop=ALL`、只读根文件系统、bridge 网络、单设备 bind mount 和精确的当前 major:minor cgroup 规则。不映射整个 `/dev`、`ttyUSB` 或 Docker socket。

hardware 模式不会修改 USB 模式，不发送 AT，不设置 APN，不启动蜂窝数据。

## QMI 设备检测

```bash
sudo ./scripts/detect-qmi-device.sh
sudo ./scripts/detect-qmi-device.sh --record
```

检测只读取设备节点和 sysfs，不打开控制设备，不发送 QMI 请求。重新枚举后必须重新检测；major/minor 变化时应重新生成 Compose 并受控重建容器。

## fnNAS / 飞牛 NAS 注意事项

部分 fnOS/fnNAS Docker 环境对字符设备 ownership/ACL 的处理与普通 Docker 主机不同。QMI Web 使用已经验证的最小设备授权方式，保持 non-root、CapDrop=ALL 和 single-device access，不通过 root 或 privileged 绕过权限问题。请不要把私人 NAS IP、用户名或路径写入公开报告。

## SMS-only 安全设计

项目不包含蜂窝数据拨号、APN 管理、WDS Start Network、DHCP、默认路由修改、DNS 修改、NAT、AT 控制台、短信发送或短信删除。所有生产短信测试都应由外部手机发送。

## Docker 安全设计

hardware 容器保持 non-root、`privileged=false`、`CapAdd=[]`、`CapDrop=ALL`、`ReadonlyRootfs=true`、`no-new-privileges`、bridge 网络和精确设备规则。更新器或宿主脚本负责容器重建，应用容器不需要 Docker socket。

## 首次登录与修改密码

首次登录使用本地 `admin` / `admin`，然后在设置页修改密码。重复安装不会重置管理员、SQLite 或 `master.key`。忘记密码时使用受控的本地维护流程，不要把数据库或密钥上传到 issue。

## 短信接收与 SQLite

短信由 WMS indication 或 storage reconciliation 读取，经过解码、长短信重组和 SQLite 去重后显示在 SMS 页面。备份前使用项目脚本，恢复前先停止服务并验证备份 hash 与 `PRAGMA integrity_check`。

## 通知

通知配置保存在本地配置目录。请使用最小权限的专用 token，并避免把 token、cookie 或完整号码写入日志、报告和 Git。

## 备份、更新和卸载

```bash
sudo ./scripts/backup.sh
sudo ./scripts/update.sh
sudo ./scripts/uninstall.sh
```

更新脚本会先备份并保留数据；卸载默认保留数据和备份，清理前请确认精确目录。生产升级前必须人工确认硬件身份、设备占用、回滚包和管理员数据。

## 故障排查

先查看 `/health`、`/ready`、`/version`、容器日志和 `app-status.json`。检查设备是否仍为字符设备、驱动是否为 `qmi_wwan`、是否被其他进程占用，以及 WDS 是否始终为 disconnected。遇到权限错误不要改成 root、privileged 或 `chmod 666`；先恢复 ACL 基线并停止硬件模式。

## 从源码构建

```bash
go mod verify
go test -mod=vendor ./...
go vet -mod=vendor ./...
cd web && npm ci && npm run typecheck && npm test && npm run build
```

需要联网准备依赖时使用 `sudo ./install.sh --prepare-online`，正常安装不会网络回退。

## 完全离线从源码构建

官方 Offline Bundle 中执行：

```bash
./scripts/offline-build.sh
```

脚本使用 `GOPROXY=off`、`GOSUMDB=off`、vendor 和 npm offline cache，并以 `network none` 构建 scratch 镜像。

## 开发与测试

```bash
make test
make verify
make security-check
```

硬件测试必须使用独立运行目录、精确设备 bind mount 和明确回滚，不得挂载生产 SQLite。

## 项目结构

`cmd/` 为服务和维护工具，`internal/` 为 Go 后端，`web/` 为 Vue 前端，`scripts/` 为安装/备份/检测脚本，`docs/` 为契约、构建和安全说明，`vendor/` 为离线 Go 依赖。

## 第三方依赖

依赖版本和许可证见 [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 许可证

本项目使用 MIT License，见 [LICENSE](LICENSE)。

## 安全问题报告

请不要公开提交凭据、token、master.key、真实短信、完整号码或设备身份。安全问题请按 [SECURITY.md](SECURITY.md) 的私下流程报告。

## 免责声明

QMI Web 是非官方社区项目，不隶属于调制解调器厂商、运营商或设备厂商。硬件、Docker 主机和运营商兼容性各不相同，使用者应自行备份并承担部署风险。

## 已测试硬件

已验证一组 Quectel-compatible QMI / `qmi_wwan` / `cdc-wdm` 组合。该结果不代表所有模块、固件或运营商都兼容。

## 已知限制

- 不支持蜂窝数据、APN、AT 控制台和短信发送。
- 硬件兼容性依赖 modem、内核和 Docker 主机实现。
- 24/48 小时长期 soak 尚未作为本版本的承诺。
- 当前离线发布包为 Linux amd64；arm64 离线包尚未验证。

## 版本状态

当前 stable release：v0.2.0。项目定位为首个具备生产能力的版本，不宣称 battle-tested long-term stable。
