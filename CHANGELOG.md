# Changelog

## v0.2.0-rc1

- First clean public release candidate with complete Go and Vue/TypeScript
  source, tests, Docker/Compose configuration, and documentation.
- Added a reproducible Linux amd64 Offline Bundle workflow with portable Go,
  Node/npm cache, Go vendor tree, manifest verification, and a scratch image.
- Added safe no-device installation, explicit hardware mode, lifecycle scripts,
  static least-privilege verification, and public-release hygiene gates.
- Preserved the SMS-only design: no mobile-data session, APN, route, AT, or SMS
  send/delete capability.

## Earlier private development

Private development history is intentionally not imported into the public
repository. This public repository begins with the reviewed release candidate.
