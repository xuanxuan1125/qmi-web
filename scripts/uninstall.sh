#!/usr/bin/env bash
# Remove the known QMI Web service without deleting persistent data by default.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"

install_dir=/opt/qmi-web
purge_data=false
purge_confirmation=
while (($#)); do
  case $1 in
    --install-dir) install_dir=${2:-}; shift 2 ;;
    --purge-data) purge_data=true; shift ;;
    --confirm-purge) purge_confirmation=${2:-}; shift 2 ;;
    -h|--help) echo 'usage: uninstall.sh [--install-dir /opt/qmi-web] [--purge-data --confirm-purge DELETE_QMI_WEB_DATA]'; exit 0 ;;
    *) qmi_die "unknown option: $1" ;;
  esac
done
qmi_validate_install_dir "$install_dir"
[[ -d $install_dir ]] || qmi_die "install directory does not exist: $install_dir"

if [[ -f $install_dir/compose.yaml ]]; then
  qmi_require docker
  qmi_compose -f "$install_dir/compose.yaml" down --rmi local || qmi_die 'failed to remove the known QMI Web container/image'
fi
"$SCRIPT_DIR/revoke-device-acl.sh" --install-dir "$install_dir"
rm -f -- "$install_dir/compose.yaml"
rm -rf -- "$install_dir/runtime"
if [[ -f $install_dir/config/.qmi-web-generated ]]; then
  rm -f -- "$install_dir/config/config.yaml" "$install_dir/config/.qmi-web-generated"
  rmdir --ignore-fail-on-non-empty "$install_dir/config" 2>/dev/null || true
fi
if [[ $purge_data == true ]]; then
  [[ $purge_confirmation == DELETE_QMI_WEB_DATA ]] || qmi_die 'data purge requires both --purge-data and --confirm-purge DELETE_QMI_WEB_DATA'
  rm -rf -- "$install_dir/data"
  echo 'Persistent data removed by explicit double confirmation. Backups were retained.'
else
  echo 'QMI Web service removed. data/ and backups/ were retained.'
fi
