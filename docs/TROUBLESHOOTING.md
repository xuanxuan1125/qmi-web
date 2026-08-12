# Troubleshooting

- No QMI cdc-wdm device found: hardware mode requires a real /dev/cdc-wdmX
  character device. Check that the host driver exposes a QMI control node. Do
  not use an AT port as a substitute.
- Multiple devices found: rerun with --device /dev/cdc-wdmX or choose one
  locally. The installer intentionally will not guess.
- Device is busy: inspect the owner reported by fuser or lsof. Stop or
  coordinate with that known owner yourself; QMI Web will not kill it.
- Foreign qmicli process: identify the parent command, systemd cgroup, and
  triggering timer. Stop the owning service and use a runtime mask for a
  recurring unit before retrying; do not whitelist qmicli or use kill -9.
- ModemManager conflict: an active ModemManager can probe a QMI node even when
  the application container is healthy. Record its original enabled/active
  state, stop and runtime-mask it during an exclusive cutover, then restore it
  from the saved state only after QMI Web is released.
- A container can open the device while another host supervisor still probes
  it. Treat that as an ownership failure; `/health` and HTTP 200 are not an
  ownership proof.
- Permission probe failed: verify the host supports getfacl and setfacl. The
  script will not fall back to root or a broad device mapping.
- Port is busy: choose a different host port with --port.
- Docker unavailable: install or start Docker Engine and its Compose plugin;
  do not expect the installer to install system packages.
- Offline npm cache or toolchain missing: use the official Offline Bundle. A
  source clone needs explicit --prepare-online preparation by a maintainer.
- Checksum mismatch: discard the damaged bundle and obtain a new release asset;
  do not bypass the manifest check.
- WMS has no SMS: this can reflect modem storage or registration state. QMI Web
  does not modify WMS storage, send messages, or configure the modem.
- Wrong architecture: the current bundle is Linux amd64 only. arm64 is not
  claimed as built or validated in this release candidate.

Advanced modem reconfiguration is outside the QMI Web installer scope. Do not
paste identifiers, messages, credentials, database files, or full logs into an
issue.
