# QMI Web API Contract v0.1.3

This contract describes the same-origin API used by the Vue WebUI. It is derived from `internal/api/RouteContracts` and the checked-in route inventory at [`reports/routes-v0.1.3.txt`](../reports/routes-v0.1.3.txt).

## Transport and security

- Public read-only endpoints are `GET /health`, `GET /ready`, and `GET /version`.
- `POST /api/v1/auth/login` requires a same-origin `Origin` header and returns a server-side session cookie plus a CSRF token in the JSON response.
- Every other `/api/v1/*` route requires that session. Mutations additionally require the `X-CSRF-Token` header and same-origin `Origin` header.
- Error responses use `{"error":{"code":"...","message":"...","details":{}}}`.
- API responses use `Cache-Control: no-store`. SPA HTML uses `no-cache`; Vite hashed assets use `public, max-age=31536000, immutable`.

## Page models

| Page | Endpoint | Required response fields |
| --- | --- | --- |
| Overview | `GET /api/v1/dashboard` | `device_status`, `sim`, `signal`, `sms`, `notifications`, `data_guard`, `qmi_validation` |
| Devices | `GET /api/v1/devices` | `devices`, `backend`, `scan_time` |
| Device scan | `POST /api/v1/devices/scan` | same model as Devices; discovery only |
| SIM | `GET /api/v1/sim` | `available`, `present`, `ready`, masked identifiers |
| Signal | `GET /api/v1/signal` | `available`, `rssi`, `rsrp`, `rsrq`, `sinr`, registration state |
| SMS | `GET /api/v1/sms?page=&page_size=&q=&status=` | `items`, `page`, `page_size`, `total` |
| Notifications | `GET /api/v1/notifications` | safe `pushplus` metadata and delivery `items` without bodies |
| Logs | `GET /api/v1/logs?limit=` | structured `items`; `GET /api/v1/logs/stream` is SSE |
| Diagnostics | `GET /api/v1/diagnostics` | platform, DB, guard, ordered QMI validation, backend, detected/active device metadata |
| Settings | `GET/PATCH /api/v1/settings` | general, security, SMS, PushPlus, logging sections |
| About | `GET /version` | version, commit, UTC build time, Go/dependency versions, `MIT` |

## No-device behavior

`GET /api/v1/devices` always returns HTTP 200 with `{"devices":[]}` when no compatible QMI device was found. It never returns version/build fields. SIM and Signal return HTTP 200 with `available:false` and empty read-only fields. Neither the GET endpoints nor a device scan opens a control node, maps a device, sends AT commands, or changes networking.

## Receive-only boundary

The contract deliberately contains no route for APN, PDP, WDS start/stop, dialing, DHCP, routing, DNS, SIM/eSIM mutation, SMS sending, reset, or USB identity changes. `PATCH /api/v1/sms/{id}/read` changes only the local SQLite read marker. `PATCH /api/v1/settings` changes local runtime settings and an encrypted PushPlus configuration; it does not change modem or NAS networking.

## Version response

`GET /version` has the following shape:

```json
{
  "version": "0.1.3",
  "commit": "<build commit>",
  "build_time": "<UTC RFC3339>",
  "go_version": "go1.26.x",
  "qmi_go_version": "v0.6.4",
  "smscodec_version": "v0.1.0",
  "license": "MIT",
  "sms_only": true
}
```
