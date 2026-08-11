# Deployment security

The complete security policy is in the repository root SECURITY.md and the
detailed model is in SECURITY_MODEL.md.

Review highlights:

- No-device is the default and maps no modem node.
- Hardware mode needs a locally selected, non-busy cdc-wdm control node.
- The runtime is non-root, capability-free, read-only, and not privileged.
- Hardware access is a single exact bind mount plus a single current
  major/minor cgroup rule, never a broad /dev or serial mapping.
- A saved, exact ACL is restored only for the matching selected device.
- Static source checks prohibit mobile-data, APN, routing, AT, and SMS
  send/delete behavior.

Security reports and issue attachments must be anonymized.
