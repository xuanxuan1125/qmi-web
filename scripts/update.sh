#!/usr/bin/env bash
# Update from a local, already-downloaded Offline Bundle. It never checks online.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"

install_dir=/opt/qmi-web
bundle=
device=
while (($#)); do
  case $1 in
    --install-dir) install_dir=${2:-}; shift 2 ;;
    --bundle) bundle=${2:-}; shift 2 ;;
    --device) device=${2:-}; shift 2 ;;
    -h|--help) echo 'usage: update.sh --bundle qmi-web-offline-linux-amd64-VERSION.tar.zst [--install-dir /opt/qmi-web] [--device /dev/cdc-wdmX]'; exit 0 ;;
    *) qmi_die "unknown option: $1" ;;
  esac
done
qmi_validate_install_dir "$install_dir"
[[ -f $bundle ]] || qmi_die 'update requires a local --bundle file'
[[ -f $install_dir/runtime/installed.env ]] || qmi_die 'installed runtime metadata is missing'
qmi_require tar
qmi_require docker

mode=$(sed -n 's/^MODE=//p' "$install_dir/runtime/installed.env")
port=$(sed -n 's/^PORT=//p' "$install_dir/runtime/installed.env")
container_name=$(sed -n 's/^CONTAINER_NAME=//p' "$install_dir/runtime/installed.env")
[[ $mode == no-device || $mode == hardware ]] || qmi_die 'installed mode metadata is invalid'
[[ $port =~ ^[0-9]+$ && -n $container_name ]] || qmi_die 'installed runtime metadata is incomplete'
if [[ $mode == hardware && -z $device && -f $install_dir/runtime/device-identity.env ]]; then
  device=$(sed -n 's/^DEVICE=//p' "$install_dir/runtime/device-identity.env")
fi
[[ $mode != hardware || -n $device ]] || qmi_die 'hardware update needs --device for the exact cdc-wdm node'

"$SCRIPT_DIR/backup.sh" --install-dir "$install_dir" >/dev/null
qmi_compose -f "$install_dir/compose.yaml" down || qmi_die 'failed to stop the known QMI Web container before update'

stage=$(mktemp -d "${TMPDIR:-/tmp}/qmi-web-update.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
case $bundle in
  *.tar.zst) tar --zstd -C "$stage" -xf "$bundle" ;;
  *.tar.gz) tar -C "$stage" -xzf "$bundle" ;;
  *) qmi_die 'bundle must be .tar.zst or .tar.gz' ;;
esac
mapfile -t roots < <(find "$stage" -mindepth 1 -maxdepth 1 -type d -print)
[[ ${#roots[@]} == 1 && -x ${roots[0]}/install.sh ]] || qmi_die 'bundle layout is not a QMI Web Offline Bundle'
args=(--mode "$mode" --install-dir "$install_dir" --port "$port" --container-name "$container_name" --upgrade)
if [[ $mode == hardware ]]; then args+=(--device "$device"); fi
"${roots[0]}/install.sh" "${args[@]}"
echo 'Update completed from the supplied local bundle; the pre-update backup was retained.'
