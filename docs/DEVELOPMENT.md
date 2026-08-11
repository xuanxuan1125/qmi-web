# Development

The project is intentionally small: Go serves the API and embeds the compiled
Vue WebUI. The version endpoint is the authority for backend, CLI, and UI build
metadata.

- cmd/server is the service entry point.
- cmd/qmi-probe performs only open/fstat/close for one QMI node.
- cmd/qmi-dbcheck and cmd/qmi-backup support local lifecycle operations.
- internal/qmi contains the receive-only QMI adapter.
- web contains the Vue/TypeScript application and its tests.
- internal/security contains source and Compose guard tests.

Use mock mode for normal development. Real-QMI tests are guarded by explicit
build/environment selection and must never be added to normal tests or CI.
