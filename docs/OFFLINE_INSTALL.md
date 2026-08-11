# Offline installation

The verified Offline Bundle is the supported path for a target that must not use
the internet. It contains full source, committed Go vendor dependencies, the
Linux amd64 Go and Node toolchains, npm cache, CA bundle, and an integrity
manifest.

1. Install Docker Engine with the Compose plugin and ensure Bash/coreutils and
   tar with zstd support are available.
2. Extract the release asset with: tar --zstd -xf BUNDLE.tar.zst
3. Enter the extracted directory and run: sudo ./install.sh
4. Select no-device unless an explicit one-device QMI deployment is needed.

The bundle verifies MANIFEST.sha256 before use. Its offline build sets
GOPROXY=off, GOSUMDB=off, -mod=vendor, and npm offline mode. It has no
downloader, network fallback, registry pull, package-manager invocation, or
Git clone path. The final image is built from Dockerfile.offline and
FROM scratch with Docker networking disabled.

The bundle uses Go 1.26.3 from go.dev/dl/go1.26.3.linux-amd64.tar.gz
(SHA-256 2b2cfc7148493da5e73981bffbf3353af381d5f93e789c82c79aff64962eb556)
and Node 26.7.0 from nodejs.org/dist/v26.7.0/node-v26.7.0-linux-x64.tar.xz
(SHA-256 982aa24dd8be4c889c6a8ab337ddff3b0896645b20f4239356e80552c16277ee).
The installer never contacts these URLs.

A source clone intentionally does not carry the large toolchains or npm cache.
A maintainer may explicitly run ./scripts/prepare-online.sh (or
sudo ./install.sh --prepare-online) to create local inputs for a new bundle.
That mode is distinct from offline mode and requires a network by design.
