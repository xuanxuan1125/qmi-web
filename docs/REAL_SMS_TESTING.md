# Automatic real-SMS validation (optional experimental tooling)

The v0.2.0 Stable production gate uses a manually sent SMS from an external
phone. The operator generates a unique `TEST_ID` and proves that the same ID
travels through WMS, `ReadMessage`, decoding, and SQLite. A row-count increase
alone is not an application pass, and Stable does not depend on a provider or
delivery report.

This document describes optional experimental automation for a future,
explicitly operator-enabled hardware test. It is never invoked by normal
builds, GitHub Actions, or the v0.2.0 Stable gate.

The public repository contains no real API key, phone number, sender, message
body, cookie, or session. The runner reads these values only from the current
process environment:

```text
NEKOKO_SMS_API_KEY
NEKOKO_SMS_TARGET
NEKOKO_SMS_FROM
```

Do not put those values in Git, shell history, process arguments, Docker
configuration, logs, reports, or release assets. Use a secret manager or a
short-lived process environment supplied by the operator. The runner clears
these variables before its process exits and prints only redacted gate
metadata.

The example entry point is:

```text
python3 scripts/test/send-sms-api.example.py \
  --stage CANARY \
  --db /path/to/qmi-web.db \
  --status-file /path/to/app-status.json \
  --rate-state /path/to/real-sms-rate-state.json
```

Supported encodings are `ascii`, `ucs2`, and `multipart`. The default API
retry schedule is immediate, +10 seconds, and +30 seconds. An external API
timeout, DNS failure, 4xx/5xx response, or explicit API rejection is reported
as `TEST_INFRA_SMS_API_FAILURE` / `SMS_TEST_BLOCKED_BY_EXTERNAL_API`; it is not
reported as a QMI Web failure. After API acceptance, the gate waits up to ten
minutes and polls SQLite every five seconds for the exact `TEST_ID`.

For a 60-minute soak, use the low-rate scheduler. It sends only four messages
at T+5, T+20, T+35, and T+50 minutes and enforces a five-minute minimum between
successful sends to the same target:

```text
python3 scripts/test/real_sms_soak.py \
  --db /path/to/qmi-web.db \
  --status-file /path/to/app-status.json \
  --rate-state /path/to/real-sms-rate-state.json
```

The scheduler does not start WDS, APN, DHCP, routes, NAT, or any modem data
session. The API request must use the NAS's ordinary Ethernet/default route;
cellular data must remain disconnected.

CI deliberately does not provide these variables and never calls the real SMS
API. Real hardware execution is an operator-approved, explicit action.
