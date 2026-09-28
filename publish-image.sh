#!/bin/sh
# Publish the locally-built ada-toolchain:edge image to GitHub Container
# Registry, so the cross-version CI workflow (.github/workflows/cross-version.yml)
# can pull it.  Run `./build-image.sh` first, and `docker login ghcr.io` once.
set -eu

: "${GHCR_IMAGE:=ghcr.io/moebiusv/ada-toolchain:edge}"

docker tag ada-toolchain:edge "$GHCR_IMAGE"
docker push "$GHCR_IMAGE"
echo "pushed $GHCR_IMAGE"
