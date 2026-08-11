#!/usr/bin/env bash
# QMI Web's supported entry point. The default is hardware-free no-device mode.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/scripts/common.sh"
ROOT=$(qmi_root)

mode=
install_dir=/opt/qmi-web
port=7580
device=
container_name=qmi-web
prepare_online=false
upgrade=false

usage() {
  cat <<'EOF'
usage: install.sh [--mode no-device|hardware] [--install-dir /opt/qmi-web]
                  [--port 7580] [--device /dev/cdc-wdmX]
                  [--container-name qmi-web] [--upgrade] [--prepare-online]

Default mode is no-device. An interactive terminal offers no-device, hardware,
or exit. --prepare-online is an explicit maintainer-only opt-in; normal and
offline-bundle installs never fetch dependencies.
EOF
}

while (($#)); do
  case $1 in
    --mode) mode=${2:-}; shift 2 ;;
    --install-dir) install_dir=${2:-}; shift 2 ;;
    --port) port=${2:-}; shift 2 ;;
    --device) device=${2:-}; shift 2 ;;
    --container-name) container_name=${2:-}; shift 2 ;;
    --upgrade) upgrade=true; shift ;;
    --prepare-online) prepare_online=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; qmi_die "unknown option: $1" ;;
  esac
done

if [[ -z $mode ]]; then
  if [[ -t 0 ]]; then
    printf 'Select QMI Web mode:\n  1) no-device (default, no modem access)\n  2) hardware (one selected cdc-wdm node)\n  3) exit\nChoice [1]: '
    read -r choice || true
    case ${choice:-1} in
      1) mode=no-device ;;
      2) mode=hardware ;;
      3) echo 'Installation cancelled.'; exit 0 ;;
      *) qmi_die 'invalid selection' ;;
    esac
  else
    mode=no-device
  fi
fi
[[ $mode == no-device || $mode == hardware ]] || qmi_die '--mode must be no-device or hardware'
qmi_validate_install_dir "$install_dir"
[[ $port =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || qmi_die 'port must be 1-65535'
[[ $container_name =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || qmi_die 'container name contains unsupported characters'
[[ $EUID -eq 0 ]] || qmi_die 'run with sudo so persistent directories can be owned by the non-root container UID'
[[ $install_dir != *$'\n'* && $install_dir != *'"'* ]] || qmi_die 'install directory contains an unsupported character'
project_name=$(printf '%s' "$container_name" | tr '[:upper:].' '[:lower:]-')

if [[ $prepare_online == true ]]; then
  "$SCRIPT_DIR/scripts/prepare-online.sh"
else
  export QMI_WEB_OFFLINE=1
  qmi_manifest_verify "$ROOT"
fi

qmi_require docker
docker info >/dev/null 2>&1 || qmi_die 'Docker Engine is not available'
qmi_compose version >/dev/null 2>&1 || qmi_die 'Docker Compose plugin is not available'

existing=false
if [[ -f $install_dir/runtime/installed.env || -f $install_dir/data/qmi-web.db || -f $install_dir/compose.yaml ]]; then
  existing=true
fi
if [[ $existing == true && $upgrade != true ]]; then
  if [[ -t 0 ]]; then
    read -r -p 'Existing installation detected. Upgrade it? [y/N] ' answer
    [[ $answer == y || $answer == Y ]] || { echo 'Installation cancelled; existing data was not changed.'; exit 0; }
    upgrade=true
  else
    qmi_die 'existing installation detected; rerun with --upgrade after taking a backup'
  fi
fi

VERSION=$(qmi_version "$ROOT")
COMMIT=$(cat "$ROOT/RELEASE_COMMIT" 2>/dev/null || printf unknown)
data="$install_dir/data"
config="$install_dir/config"
logs="$install_dir/logs"
runtime="$install_dir/runtime"

if [[ $existing == true && -x $runtime/qmi-backup && -f $data/qmi-web.db ]]; then
  "$SCRIPT_DIR/scripts/backup.sh" --install-dir "$install_dir" >/dev/null
fi
if [[ $existing == true && -f $install_dir/compose.yaml ]]; then
  qmi_compose -f "$install_dir/compose.yaml" down || qmi_die 'failed to stop the known existing QMI Web container'
fi

# Build before touching a QMI node. offline-build.sh has no network fallback.
QMI_WEB_COMMIT="$COMMIT" "$SCRIPT_DIR/scripts/offline-build.sh"

selected_record=
major=
minor=
vidpid=
acl_granted=false
restore_on_error() {
  status=$?
  if (( status != 0 )) && [[ $acl_granted == true ]]; then
    qmi_compose -f "$install_dir/compose.yaml" down >/dev/null 2>&1 || true
    "$SCRIPT_DIR/scripts/revoke-device-acl.sh" --install-dir "$install_dir" >/dev/null 2>&1 || true
  fi
  exit "$status"
}
trap restore_on_error EXIT

choose_device() {
  local records_text choice
  if [[ -n $device ]]; then
    selected_record=$("$SCRIPT_DIR/scripts/detect-qmi-device.sh" --record --device "$device")
  else
    records_text=$("$SCRIPT_DIR/scripts/detect-qmi-device.sh" --record) || qmi_die 'No QMI cdc-wdm device found.'
    mapfile -t records <<< "$records_text"
    if ((${#records[@]} == 1)); then
      selected_record=${records[0]}
    elif ((${#records[@]} > 1)); then
      [[ -t 0 ]] || qmi_die 'multiple QMI devices found; rerun with --device /dev/cdc-wdmX'
      echo 'Multiple QMI control nodes were found:'
      for i in "${!records[@]}"; do
        IFS=$'\t' read -r record_device record_major record_minor record_vidpid record_driver <<< "${records[$i]}"
        printf '  %d) %s (major=%s minor=%s USB=%s driver=%s)\n' "$((i+1))" "$record_device" "$record_major" "$record_minor" "$record_vidpid" "$record_driver"
      done
      read -r -p 'Choose one device number: ' choice
      [[ $choice =~ ^[0-9]+$ && $choice -ge 1 && $choice -le ${#records[@]} ]] || qmi_die 'invalid device selection'
      selected_record=${records[$((choice-1))]}
    else
      qmi_die 'No QMI cdc-wdm device found.'
    fi
  fi
  IFS=$'\t' read -r device major minor vidpid _ <<< "$selected_record"
  [[ $device == /dev/cdc-wdm* && $major =~ ^[0-9]+$ && $minor =~ ^[0-9]+$ ]] || qmi_die 'device discovery returned an invalid target'
}

check_device_busy() {
  if command -v fuser >/dev/null 2>&1 && fuser "$device" >/dev/null 2>&1; then
    echo "Device is currently in use by:" >&2
    fuser -v "$device" >&2 || true
    qmi_die 'refusing to stop or take over a busy device'
  fi
  if command -v lsof >/dev/null 2>&1 && lsof "$device" >/dev/null 2>&1; then
    echo "Device is currently in use by:" >&2
    lsof "$device" >&2 || true
    qmi_die 'refusing to stop or take over a busy device'
  fi
}

prepare_device_acl() {
  qmi_require getfacl
  qmi_require setfacl
  if [[ ! -f $runtime/device-acl.before ]]; then
    umask 077
    getfacl -p "$device" > "$runtime/device-acl.before"
    printf 'DEVICE=%s\nVIDPID=%s\nMAJOR=%s\nMINOR=%s\n' "$device" "$vidpid" "$major" "$minor" > "$runtime/device-identity.env"
    chmod 600 "$runtime/device-acl.before" "$runtime/device-identity.env"
  fi
  setfacl -m u:65532:rw "$device"
  getfacl -p "$device" | grep -Eq '^user:65532:rw-' || qmi_die 'exact temporary ACL verification failed'
  acl_granted=true
}

write_compose() {
  if [[ $mode == no-device ]]; then
    cat > "$install_dir/compose.yaml" <<EOF
name: $project_name
services:
  qmi-web:
    image: local/qmi-web:$VERSION
    container_name: $container_name
    restart: unless-stopped
    environment:
      QMI_WEB_BACKEND: mock
      QMI_WEB_SMS_ONLY: "true"
    ports:
      - "$port:7580"
    volumes:
      - "$data:/data"
      - "$config:/config:ro"
      - "$logs:/logs"
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=16m
    cap_add: []
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    privileged: false
    mem_limit: 256m
    network_mode: bridge
EOF
  else
    cat > "$install_dir/compose.yaml" <<EOF
name: $project_name
services:
  qmi-web:
    image: local/qmi-web:$VERSION
    container_name: $container_name
    restart: unless-stopped
    environment:
      QMI_WEB_BACKEND: qmi
      QMI_WEB_DEVICE: "$device"
      QMI_WEB_SMS_ONLY: "true"
      QMI_WEB_REAL_VALIDATION: "true"
      QMI_WEB_REAL_VALIDATION_WINDOW: "60m"
      QMI_WEB_REAL_VALIDATION_STATUS_FILE: "/data/app-status.json"
      QMI_WEB_SMS_RECONCILE_INTERVAL: "60s"
      QMI_WEB_DEVICE_RECONNECT_MAX_BACKOFF: "30s"
      QMI_WEB_DEBUG_STORE_PDU: "false"
    ports:
      - "$port:7580"
    volumes:
      - "$data:/data"
      - "$config:/config:ro"
      - "$logs:/logs"
      - type: bind
        source: "$device"
        target: "$device"
        read_only: false
        bind:
          create_host_path: false
    device_cgroup_rules:
      - "c $major:$minor rw"
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=16m
    cap_add: []
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    privileged: false
    mem_limit: 256m
    network_mode: bridge
EOF
  fi
}

verify_runtime_security() {
  local actual_user privileged capadd capdrop readonly rules devices network mounts
  actual_user=$(docker inspect --format '{{.Config.User}}' "$container_name")
  privileged=$(docker inspect --format '{{.HostConfig.Privileged}}' "$container_name")
  capadd=$(docker inspect --format '{{json .HostConfig.CapAdd}}' "$container_name")
  capdrop=$(docker inspect --format '{{json .HostConfig.CapDrop}}' "$container_name")
  readonly=$(docker inspect --format '{{.HostConfig.ReadonlyRootfs}}' "$container_name")
  rules=$(docker inspect --format '{{range .HostConfig.DeviceCgroupRules}}{{println .}}{{end}}' "$container_name")
  devices=$(docker inspect --format '{{json .HostConfig.Devices}}' "$container_name")
  network=$(docker inspect --format '{{.HostConfig.NetworkMode}}' "$container_name")
  mounts=$(docker inspect --format '{{range .Mounts}}{{printf "%s|%s|%s\n" .Source .Destination .Type}}{{end}}' "$container_name")
  [[ $actual_user == 65532:65532 && $privileged == false && $readonly == true && $network == bridge ]] || return 1
  [[ $capdrop == *ALL* ]] || return 1
  [[ $capadd == '[]' || $capadd == 'null' ]] || return 1
  [[ $devices == '[]' || $devices == 'null' ]] || return 1
  [[ $mounts != *docker.sock* && $mounts != *'/dev|/dev|'* ]] || return 1
  if [[ $mode == no-device ]]; then
    [[ -z $rules ]] || return 1
    [[ $mounts != *'/dev/cdc-wdm'* ]] || return 1
  else
    [[ $rules == "c $major:$minor rw" ]] || return 1
    [[ $mounts == *"$device|$device|bind"* ]] || return 1
  fi
}

mkdir -p -- "$data" "$config" "$logs" "$runtime" "$install_dir/backups"
chown -R 65532:65532 "$data" "$config" "$logs"
chmod 700 "$data" "$config" "$logs" "$runtime" "$install_dir/backups"
if [[ ! -f $config/config.yaml ]]; then
  cp -- "$ROOT/config/config.example.yaml" "$config/config.yaml"
  chown 65532:65532 "$config/config.yaml"
  chmod 600 "$config/config.yaml"
  : > "$config/.qmi-web-generated"
  chmod 600 "$config/.qmi-web-generated"
fi
cp -- "$ROOT/build/offline/qmi-dbcheck" "$runtime/qmi-dbcheck"
cp -- "$ROOT/build/offline/qmi-backup" "$runtime/qmi-backup"
chmod 755 "$runtime/qmi-dbcheck" "$runtime/qmi-backup"

if [[ $mode == hardware ]]; then
  choose_device
  check_device_busy
  prepare_device_acl
  docker run --rm --read-only --user 65532:65532 --cap-drop ALL --security-opt no-new-privileges:true \
    --network bridge --device-cgroup-rule "c $major:$minor rw" \
    --mount "type=bind,src=$device,dst=$device" \
    --entrypoint /qmi-probe "local/qmi-web:$VERSION" "$device"
fi

write_compose
qmi_compose -f "$install_dir/compose.yaml" config -q
qmi_compose -f "$install_dir/compose.yaml" up -d --no-build
if ! verify_runtime_security; then
  qmi_compose -f "$install_dir/compose.yaml" down || true
  qmi_die 'runtime security inspection failed; stopped the new QMI Web container'
fi
qmi_wait_http_200 "$port" /health 30 || qmi_die 'health endpoint did not return HTTP 200'
qmi_wait_http_200 "$port" /ready 10 || qmi_die 'ready endpoint did not return HTTP 200'
qmi_wait_http_200 "$port" /version 10 || qmi_die 'version endpoint did not return HTTP 200'
"$runtime/qmi-dbcheck" "$data/qmi-web.db"

printf 'VERSION=%s\nCOMMIT=%s\nMODE=%s\nPORT=%s\nCONTAINER_NAME=%s\nPROJECT_NAME=%s\n' "$VERSION" "$COMMIT" "$mode" "$port" "$container_name" "$project_name" > "$runtime/installed.env"
chmod 600 "$runtime/installed.env"
acl_granted=false
trap - EXIT
printf 'QMI Web installed successfully.\nMode: %s\nURL: http://<host>:%s\nDefault user: admin\nDefault password: admin\nPlease change the password after first login.\n' "$mode" "$port"
