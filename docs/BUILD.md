# Build instructions

For a regular development machine with Go and Node/npm already available:

    go mod tidy
    go mod verify
    go mod vendor
    make test
    make build
    make image

The committed `vendor/` directory is the release input. Before changing
dependencies, maintainers run the three Go module commands above in a clean
source checkout, review the resulting change, and commit it.
`scripts/prepare-online.sh` validates that committed vendor tree without
rewriting it while it prepares portable toolchains and the npm cache.

The normal Dockerfile is for connected development/CI builds and may need base
images. It is not the offline release path.

For the release path, use a prepared Linux amd64 Offline Bundle:

    ./scripts/offline-build.sh

It deletes only generated frontend/build outputs, performs npm ci --offline,
frontend typecheck/test/build, Go test/vet/static build with -mod=vendor, and
creates the final scratch image with Docker networking disabled.

make package-offline only works from a clean public Git checkout. It packages
the current commit, never the caller's uncommitted working tree.
