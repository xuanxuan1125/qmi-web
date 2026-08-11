# Security policy

Please do not open a public issue for a suspected vulnerability. Use the
repository's private security-advisory channel when available, or contact the
maintainers through the repository contact method with a minimal reproduction.
Do not include passwords, tokens, cookies, phone numbers, SMS text, IMEI, IMSI,
ICCID, serial numbers, database files, or configuration files.

QMI Web's deployment model is deliberately narrow:

- \`no-device\` mode maps no device and uses the mock backend.
- \`hardware\` mode selects exactly one dynamic \`cdc-wdm\` QMI control node.
- The service runs as UID/GID \`65532\`, with \`CapDrop=ALL\`, no added
  capabilities, a read-only root filesystem, and no Docker socket.
- Hardware mode checks an exact current character-device \`major:minor\` rule,
  uses a single bind mount, and performs an open/fstat/close permission probe
  before QMI initialization.
- The supported QMI operations are receive-only SMS and observational modem
  status. Data-session activation, APN/profile changes, routing, DHCP, DNS,
  AT commands, SMS send/delete, and modem/USB reconfiguration are excluded.

See [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) for the full boundary and
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for safe failure handling.
