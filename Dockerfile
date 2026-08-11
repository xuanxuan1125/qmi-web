# syntax=docker/dockerfile:1
FROM node:26-alpine AS frontend
WORKDIR /src/web
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

FROM golang:1.26.3-alpine AS backend
ARG VERSION=0.2.0-rc1
ARG COMMIT=unknown
ARG BUILD_TIME=unknown
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
COPY --from=frontend /src/internal/web/dist ./internal/web/dist
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -buildvcs=false -trimpath \
  -ldflags="-s -w -X qmi-web/internal/version.Version=${VERSION} -X qmi-web/internal/version.Commit=${COMMIT} -X qmi-web/internal/version.BuildTime=${BUILD_TIME}" \
  -o /out/qmi-web ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
ARG VERSION=0.2.0-rc1
ARG COMMIT=unknown
ARG BUILD_TIME=unknown
LABEL org.opencontainers.image.title="QMI Web" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.created="${BUILD_TIME}" \
      org.opencontainers.image.licenses="MIT"
WORKDIR /
COPY --from=backend /out/qmi-web /qmi-web
USER nonroot:nonroot
EXPOSE 7580
ENTRYPOINT ["/qmi-web"]
