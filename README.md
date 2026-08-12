# QMI Web v0.2.0

English | [简体中文](README.zh-CN.md)

QMI Web is an open-source, SMS-only QMI modem and SMS management panel. It
combines a Vue/TypeScript WebUI, a Go backend, SQLite persistence, inbound-SMS
deduplication, status/signal views, and optional notifications.

This is the first production-capable release. Real QMI SMS-only reception,
production hardware mode, restart recovery, and deduplication have been
validated; a 24/48-hour long-term soak is still recommended.

## Scope and security boundary

QMI Web can use QMI DMS, UIM, NAS, read-only WDS status, and WMS for inbound
SMS handling. It deliberately does **not** establish cellular data sessions.
There is no APN editor, dialer, WDS Start Network operation, DHCP, DNS, route,
NAT, AT console, SMS sending, SMS deletion, modem reset, USB mode switch, or
Docker socket access.

The default \`no-device\` mode uses a mock backend and maps no hardware. The
optional \`hardware\` mode is explicit and only accepts one dynamically detected
\`/dev/cdc-wdmX\` node. It runs as UID/GID \`65532\`, drops all capabilities, uses
a read-only root filesystem, keeps bridge networking, and uses an exact current
character-device \`major:minor\` cgroup rule. It does not map \`/dev\` broadly or
access AT serial ports.

## Quick start

For a completely offline source build and deployment, download the Linux amd64
Offline Bundle from the release assets, then disconnect the target host if
desired:

\`\`\`bash
tar --zstd -xf qmi-web-offline-linux-amd64-v0.2.0.tar.zst
cd qmi-web-offline-linux-amd64-v0.2.0
sudo ./install.sh
\`\`\`

Choose \`no-device\` for the safe default or \`hardware\` only after reviewing the
hardware-mode guardrails. The installer checks its manifest, builds with the
bundled Go/Node/npm inputs while offline, builds a \`FROM scratch\` image with no
pull, starts the container, validates \`/health\`, \`/ready\`, and \`/version\`, and
checks SQLite integrity.

Open \`http://<host>:7580\`. The initial local account is \`admin\` / \`admin\`;
change it immediately. A repeated install cancels by default and never resets
the database, administrator password, or \`master.key\`; use \`--upgrade\` only
after reviewing the backup created by the lifecycle scripts.

The Git repository contains complete Go, Vue/TypeScript, tests, Docker and
Compose files, documentation, and a committed Go \`vendor/\` tree. A normal
source clone is useful for review and development, but it does not include the
offline toolchains or npm cache. For an intentionally online maintainer setup,
run \`sudo ./install.sh --prepare-online\`; normal installation never falls back
to the network.

## Supported workflows

- \`make build\`, \`make test\`, \`make frontend\`, \`make backend\`, and \`make image\`
  support development builds.
- \`make offline-build\` validates a prepared Offline Bundle with \`GOPROXY=off\`,
  \`GOSUMDB=off\`, \`-mod=vendor\`, and \`npm ci --offline\`.
- \`make package-offline\` creates the Linux amd64 source and Offline Bundle
  release assets from a clean public Git checkout.
- \`scripts/backup.sh\`, \`scripts/restore.sh\`, \`scripts/update.sh\`, and
  \`scripts/uninstall.sh\` are explicit lifecycle operations. Uninstall preserves
  data and backups unless a second purge confirmation is supplied.
- \`scripts/rollback-to-vohive.sh\` is an explicit, metadata-driven recovery
  path. It backs up QMI Web, recreates only QMI Web in \`no-device\` mode,
  restores the saved device ACL, and starts explicitly named VoHive automation
  and container; it never deletes QMI Web data or guesses deployment names.

Read [offline installation](docs/OFFLINE_INSTALL.md),
[hardware mode](docs/HARDWARE_MODE.md), [security model](docs/SECURITY_MODEL.md),
[build instructions](docs/BUILD.md), and [troubleshooting](docs/TROUBLESHOOTING.md)
before using hardware mode.

## Hardware notes

Device discovery is generic QMI control-node discovery based on \`cdc-wdm\`,
sysfs, and driver information; it is not hard-coded to one vendor. Real
SMS-only validation covered a Quectel-compatible QMI combination using
\`qmi_wwan\` and \`cdc-wdm\`; it does not imply support for every modem or carrier.
The installer stops if a selected device is busy and never kills other
processes or services.

QMI Web is an unofficial community project. It is not affiliated with modem
manufacturers, mobile carriers, or DJI.

## License and contribution

QMI Web is licensed under the [MIT License](LICENSE). Third-party notices and
dependency information are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
and [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md). See [SECURITY.md](SECURITY.md)
for private vulnerability reporting and [CONTRIBUTING.md](CONTRIBUTING.md) for
development and hardware-test rules.
