# QMI Web Offline Bundle

This bundle is self-contained for Linux amd64 source compilation and Docker
deployment. It contains the complete source tree, Go vendor dependencies,
portable Go/Node toolchains, npm cache, CA bundle, and MANIFEST.sha256.

Run:

    sudo ./install.sh

Choose no-device for the default safe experience. Hardware mode requires an
explicit QMI control-node selection and will stop if the device is busy or fails
the non-root permission probe. After installation, open http://<host>:7580,
sign in with admin / admin, and change the password immediately.

No network access, package installation, registry image pull, Go download, npm
download, or Git clone is used in the Offline Bundle path.
