# Contributing

Use a clean branch and run \`make verify\` plus \`make test\` before opening a pull
request. Frontend changes should also run \`make frontend\`. Keep the Go module
vendor tree synchronized with \`go mod tidy\`, \`go mod verify\`, and \`go mod
vendor\` when dependencies change.

Do not add mobile-data, APN, routing, DHCP, DNS, NAT, AT-command, SMS send,
SMS delete, SIM-write, modem-reset, USB-mode, broad \`/dev\`, root-container,
privileged-container, capability, or Docker-socket functionality. Changes to
hardware mode must preserve the exact single-device bind mount and dynamic
\`major:minor\` cgroup rule.

Real-hardware tests are opt-in and never run in normal Go tests or CI. Do not
attach real SMS data, identifiers, network addresses, credentials, logs, or
database files to issues or pull requests. Use mock fixtures with anonymized
values instead.
