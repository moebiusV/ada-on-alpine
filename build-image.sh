#!/bin/sh
# Build the ada-toolchain:edge image from the .apk files produced by build.sh.
#
# The image is plain alpine:edge with the whole toolchain installed, plus
# gcc-gnat/musl-dev/gmp for building against it. gpr2-tools is included: its
# tools are installed as gprbuild2 etc., alongside classic gprbuild.
#
# Run build.sh first (or at least build the .apks you want), then this.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
PKGS="$ROOT/.work/packages"
[ -d "$PKGS" ] || { echo "error: $PKGS missing; run ./build.sh first" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -a "$PKGS" "$tmp/pkgs"

cat > "$tmp/Dockerfile" <<'EOF'
FROM alpine:edge
COPY pkgs /pkgs
RUN set -e; \
    apk add --no-cache --allow-untrusted gcc-gnat musl-dev gmp /pkgs/*.apk >/dev/null 2>&1
EOF

docker build -t ada-toolchain:edge "$tmp"
echo "==> built ada-toolchain:edge"
