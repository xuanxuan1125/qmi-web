# Changelog

## v1.0.0

- 新增：自动深浅色主题模式，跟随系统主题实时无缝切换
- 新增：主题设置本地持久化，并完美兼容旧版本配置迁移
- 优化：引入 anti-FOUC 机制消除应用启动时的主题闪烁
- 优化：Windows 一键安装脚本支持 (`install.bat` 与 `install.ps1`) 自动下载执行
- 全新 V3 WebUI，引入 VoCat 风格现代界面（支持 Light / Dark 模式）
- 移动端完美响应式适配（单列重排、抽屉菜单、独立全屏 SMS 阅读器）
- 引入真实文本日志生成与下载
- 修复 Auth Guard 401 鉴权无限跳转问题
- 重构构建流水线：采用 GitHub Actions 自动化输出原生 `linux/amd64` 与 `linux/arm64` 二进制包
- 新增 `install.sh` 一键安装脚本与 `systemd` 集成，并支持自动化安全更新与回滚
- 巩固 SMS-only 安全边界，不引入主动网络干涉

## v0.2.0

- First production-capable release with complete Go and Vue/TypeScript source,
  tests, Docker/Compose configuration, and documentation.
- Added a reproducible Linux amd64 Offline Bundle workflow with portable Go,
  Node/npm cache, Go vendor tree, manifest verification, and a scratch image.
- Added safe no-device installation, explicit hardware mode, lifecycle scripts,
  static least-privilege verification, and public-release hygiene gates.
- Established exclusive host ownership guards and an explicit rollback path to
  protect automated environments from uncontrolled migration failures.
