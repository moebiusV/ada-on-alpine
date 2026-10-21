#!/bin/sh
# CI: pre-seed .work with prebuilt gcc packages for one architecture.
#   tools/seed-restore.sh <arch>
#
# The gcc carrier (testing/gcc) cannot be built within GitHub's 6 h job limit on
# the emulated architectures, so the packages are built once by hand
# (tools/make-seed.sh) and published on the orphan branch seed-gcc-<arch>.  They
# are used only if the content hash of testing/gcc recorded with them is the one
# of this checkout; otherwise nothing is seeded and the stage builds gcc itself.
# What is written is exactly what build.sh leaves after building the aport
# (packages, hash, manifest), so build.sh then treats gcc as already built.
set -eu
arch=$1
url=${SEED_URL:-https://github.com/moebiusV/ada-on-alpine}
branch=seed-gcc-$arch

cur=$(cd testing/gcc && find . \( -name src -o -name tmp \) -prune -o -type f \
        -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -d' ' -f1)

if ! git ls-remote --exit-code --heads "$url" "$branch" >/dev/null 2>&1; then
    echo "seed: no branch $branch; gcc will be built here"
    exit 0
fi
tmp=$(mktemp -d)
git clone -q --depth 1 --branch "$branch" "$url" "$tmp"
if [ "$(cat "$tmp/HASH" 2>/dev/null)" != "$cur" ]; then
    echo "seed: $branch is for another testing/gcc ($(cut -c1-12 "$tmp/HASH" 2>/dev/null) vs $(echo "$cur" | cut -c1-12)); gcc will be built here"
    exit 0
fi
mkdir -p .work/packages .work/hashes .work/manifest
while read -r f; do
    n=${f%%-[0-9]*}
    rm -f .work/packages/"$n"-[0-9]*.apk
    cp "$tmp/$f" .work/packages/
done < "$tmp/MANIFEST"
cp "$tmp/MANIFEST" .work/manifest/gcc
printf '%s\n' "$cur" > .work/hashes/gcc
echo "seed: gcc for $arch restored from $branch ($(wc -l < "$tmp/MANIFEST") packages)"
