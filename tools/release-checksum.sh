#!/bin/sh
# release-checksum.sh — update an APKBUILD's pkgver + sha512sums from a pushed
# GitHub tag, then (optionally) commit and push the overlay.
#
#   ./tools/release-checksum.sh <pkgname> <tag> [--commit] [--push]
#
# The Ada program apkbuild_bump does the APKBUILD rewrite (the part that is
# easy to get wrong by hand); this script does the network fetch, the hashing,
# the build of that helper, and the git steps.
#
# Requires: curl, sha512sum, and gprbuild (or a prebuilt tools/apkbuild_bump).
set -eu

pkg=${1:-}
tag=${2:-}
if [ -z "$pkg" ] || [ -z "$tag" ]; then
    echo "usage: $0 <pkgname> <tag> [--commit] [--push]" >&2
    exit 1
fi
shift 2

case "$tag" in
    v*) version=$(printf '%s' "$tag" | sed 's/^v//') ;;
    *)  version=$tag ;;
esac

root=$(cd "$(dirname "$0")/.." && pwd)
apkbuild="$root/testing/$pkg/APKBUILD"
[ -f "$apkbuild" ] || { echo "no such aport: $apkbuild" >&2; exit 1; }

url="https://github.com/moebiusV/$pkg/archive/refs/tags/$tag.tar.gz"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "fetching $url"
curl -fsSL -o "$tmp/$pkg-$tag.tar.gz" "$url"

hash=$(sha512sum "$tmp/$pkg-$tag.tar.gz" | awk '{print $1}')

# Build the Ada helper if it is not already built.
if [ ! -x "$root/tools/apkbuild_bump" ]; then
    (cd "$root/tools" && gprbuild -P apkbuild_bump.gpr -q -p)
fi

"$root/tools/apkbuild_bump" "$apkbuild" "$version" "$hash"

cd "$root"
git diff --stat -- "$apkbuild"
git diff -- "$apkbuild"

for a in "$@"; do
    case "$a" in
        --commit)
            git add "$apkbuild"
            git commit -m "$pkg: $version (tag tarball checksum)"
            ;;
        --push)
            git push origin main
            ;;
    esac
done
