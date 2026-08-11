# Dependency audit

This release candidate uses pinned Go modules and a pinned npm lockfile. The
public release contains a committed Go vendor tree for offline Go builds and
carries the npm cache only inside the release asset, never in the Git branch.

The direct module/package license status is summarized in DEPENDENCIES.md and
THIRD_PARTY_NOTICES.md. Vendor and package metadata must be reviewed when
dependencies change. No unsupported license or locally modified third-party
source is accepted into a public bundle.

The two modem/SMS direct modules are github.com/iniwex5/qmi-go v0.6.4 and
github.com/warthog618/sms v0.3.0. Both ship a reproducible MIT license text in
the vendor tree. Every vendored module included in this release has a retained
license or notice file.
