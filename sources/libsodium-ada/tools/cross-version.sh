#!/bin/sh
# Cross-version smoke test for the libsodium-ada binding.
#
# Builds the binding and runs its smoke suite (including the Crypto.Raw
# statebytes cross-checks) against each pinned libsodium release in turn:
# oldest supported -> latest stable.  Each version is built from the upstream
# release tarball into its own prefix; the binding is then built and linked
# against that prefix's libsodium, so the suite exercises each ABI and a
# mismatch is caught at link or run time.
#
# The binding requires libsodium >= 1.0.19: it binds the crypto_*_statebytes()
# size-query functions introduced there (see Crypto.Raw).
#
# Runs inside the ada-toolchain container (gcc/gprbuild present; make/curl are
# installed if missing).  Exits non-zero on the first version that fails.
set -eu

: "${SODIUM_VERSIONS:=1.0.19 1.0.20 1.0.22}"
: "${JOBS:=$(nproc 2>/dev/null || echo 4)}"

command -v make >/dev/null 2>&1 || apk add --no-cache make >/dev/null 2>&1 || true
command -v curl >/dev/null 2>&1 || apk add --no-cache curl >/dev/null 2>&1 || true

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)   # .../sources/libsodium-ada/tools
binding=$(dirname "$here")                          # .../sources/libsodium-ada
build="$binding/.cross"
mkdir -p "$build/src"

for ver in $SODIUM_VERSIONS; do
    prefix="$build/libsodium-$ver"

    if [ ! -f "$prefix/lib/libsodium.so" ] && [ ! -f "$prefix/lib/libsodium.a" ]; then
        echo "==> libsodium $ver: building from source"
        src="$build/src/libsodium-$ver"
        mkdir -p "$src"
        curl -fsSL "https://download.libsodium.org/libsodium/releases/libsodium-$ver.tar.gz" \
            | tar xz -C "$src" --strip-components=1
        (cd "$src" && ./configure --prefix="$prefix" >/dev/null \
            && make -j"$JOBS" >/dev/null && make install >/dev/null)
    fi

    echo "==> libsodium $ver: binding + smoke test"
    (
        cd "$binding"
        export LIBRARY_PATH="$prefix/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
        rm -rf obj lib smoke-obj stage
        gprbuild -P crypto.gpr -p -XLIBRARY_TYPE=static >/dev/null
        mkdir -p stage
        gprinstall -P crypto.gpr -p -f -XLIBRARY_TYPE=static \
            --prefix="$PWD/stage/usr" --sources-subdir=include/crypto \
            --build-name=static --build-var=LIBRARY_TYPE >/dev/null
        GPR_PROJECT_PATH="$PWD/stage/usr/share/gpr" gprbuild -P tests/smoke.gpr -p >/dev/null
        LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ./tests/crypto_smoke
    )
    echo "==> libsodium $ver: PASS"
done

echo "cross-version: all versions passed ($SODIUM_VERSIONS)"
