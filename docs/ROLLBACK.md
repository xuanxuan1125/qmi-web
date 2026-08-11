# Rollback and recovery

Before an explicit update, scripts/update.sh creates a consistent local backup.
To restore a selected backup:

    sudo ./scripts/restore.sh --install-dir /opt/qmi-web --file /path/to/backup.tar.gz --confirm

The QMI Web container must be stopped manually first. Restore validates the
archive path and SQLite integrity, creates a pre-restore backup when data
exists, then replaces only the selected database/configuration/key files.

To remove the service while preserving data and backups:

    sudo ./scripts/uninstall.sh --install-dir /opt/qmi-web

Data deletion needs both --purge-data and
--confirm-purge DELETE_QMI_WEB_DATA. Hardware ACL restoration is attempted only
for the saved, matching QMI device identity.
