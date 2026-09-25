#!/bin/sh
# Build the ada-toolchain:edge-full image: ada-toolchain:edge plus the extra
# language toolchains for hbnf's other backends.
#
# From Alpine's own repos (apk add):
#   rust cargo zig          the three backends already present
#   gcc-gdc ldc dub         D
#   gfortran                Fortran
#   nim nimble              Nim
#   gcc-objc libobjc        Objective-C
#   ats2                    ATS
#
# From this repo's aports (copied out of .work/packages/, see build.sh):
#   fpc                     Free Pascal (binary bootstrap)
#   odin                    Odin (C++ bootstrap against LLVM 18)
#   newlisp                 newLISP (UTF-8, readline, IPv6)
#   vlang                   V (C bootstrap, -gc none self-compile)
#
# Run build.sh first (or `abuild -r` each language aport so its .apk is in
# .work/packages/), then build-image.sh to make :edge, then this.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
[ -d "$ROOT/.work/packages" ] || { echo "error: .work/packages missing; run ./build.sh first" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/pkgs"
for p in fpc odin newlisp vlang; do
	cp "$ROOT/.work/packages/$p-"*.apk "$tmp/pkgs/" 2>/dev/null || true
done

cat > "$tmp/Dockerfile" <<'EOF'
FROM ada-toolchain:edge
COPY pkgs /pkgs
# apk update first: :edge's index is from when build-image.sh ran, and a
# stale index makes the solver trip over the gprbuild/gpr2-tools `replaces`
# relationship.  The Alpine language packages and the local language aports
# install as two steps, each its own apk solve.
RUN apk update && apk add --no-cache rust cargo zig \
        gcc-gdc ldc dub gfortran nim nimble gcc-objc libobjc ats2
RUN for f in /pkgs/*.apk; do [ -e "$f" ] && apk add --no-cache --allow-untrusted "$f"; done
EOF

docker build -t ada-toolchain:edge-full "$tmp"
echo "==> built ada-toolchain:edge-full"
