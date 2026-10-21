#!/bin/sh
# Publish locally built gcc packages as the CI seed for one architecture.
#   tools/make-seed.sh <arch> <dir-with-apks> [--no-push]
#
# <dir-with-apks> holds the packages abuild produced for testing/gcc (every apk
# whose origin is gcc).  Run it from a clean checkout of the commit CI will build:
# the hash recorded is that of testing/gcc in HEAD.  The packages must have been
# built from exactly those files.  Pushes the orphan branch seed-gcc-<arch>
# (force: only the latest seed is kept; pushing it does not trigger CI).
set -eu
arch=$1 dir=$2 push=${3:-}
root=$(cd "$(dirname "$0")/.." && pwd)
git -C "$root" diff --quiet HEAD -- testing/gcc || { echo "error: testing/gcc has uncommitted changes" >&2; exit 1; }

tmp=$(mktemp -d)
git -C "$root" archive HEAD testing/gcc | tar -x -C "$tmp"
hash=$(cd "$tmp/testing/gcc" && find . \( -name src -o -name tmp \) -prune -o -type f \
        -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -d' ' -f1)

out=$tmp/seed; mkdir "$out"
: > "$out/MANIFEST"
ver=$(sed -n 's/^pkgver=//p' "$tmp/testing/gcc/APKBUILD" | head -1)
for f in "$dir"/*.apk; do
    info=$(tar -xzOf "$f" .PKGINFO 2>/dev/null) || continue
    printf '%s\n' "$info" | grep -qx 'origin = gcc' || continue
    size=$(stat -c %s "$f")
    # GitHub rejects files over 100 MB
    [ "$size" -lt 100000000 ] || { echo "skipping $(basename "$f"): $size bytes (> 100 MB)"; continue; }
    cp "$f" "$out/"; basename "$f" >> "$out/MANIFEST"
done
printf '%s\n' "$hash" > "$out/HASH"
echo "seed for $arch: $(wc -l < "$out/MANIFEST") packages, hash $(echo "$hash" | cut -c1-12), pkgver $ver, $(du -sh "$out" | cut -f1)"
[ "$push" = --no-push ] && { echo "built in $out"; exit 0; }
cd "$out"
git init -q -b "seed-gcc-$arch"
git add -A
git -c user.name="seed" -c user.email="seed@invalid" commit -q -m "gcc seed for $arch (testing/gcc hash $hash)"
git push -f "$(git -C "$root" remote get-url origin)" "seed-gcc-$arch"
