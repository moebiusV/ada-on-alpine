#!/bin/sh
# Build the Ada toolchain aports inside the Alpine musl image (no cross-
# compilation), in dependency order. Requires Docker. Produces the .apk files
# under .work/packages/. The build runs abuild as a non-root user, bootstraps
# gprbuild, installs it, then builds the rest against it in order.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT/.work/packages"
mkdir -p "$OUT"

# Dependency order: each package's build deps must precede it. libadalang OOMs
# on <8GB (built -j1). gpr2-tools (installs as gprbuild2 etc., alongside classic
# gprbuild) is disabled/WIP and not in the default list: gprbuild2 crashes on
# library projects. afl++ (a C/C++ fuzzing tool) builds against neither gprbuild
# nor gpr2-tools, so it sits after the spine.
PKGS="${PKGS:-gprbuild bracke-cryptolib bracke-zlib libsodium-ada mustache-ada hbnf imsg-ada xmlada aunit buildabook gnatcoll gnatcoll-db gnatcoll-gmp gnatcoll-iconv spawn vss aws adasat py3-e3-core py3-e3-testsuite prettier-ada py3-langkit langkit gpr libgpr gnatcoll-projects libadalang templates-parser vss-extra xdiff libadalang-tools lal-refactor gnatformat ada-markdown gnatdoc fswatch ada-libfswatch ada_language_server afl++}"

# The signing key lives on the host in ~/.config/abuild (Alpine's standard abuild
# key location), not in this repo, so every checkout and every machine signs with
# the same key.  bind-mount it into the container below as /keys.
KEYDIR="${KEYDIR:-$HOME/.config/abuild}"
# CI builds other architectures through these: DOCKER_PLATFORM selects the
# container platform (e.g. linux/386), BUILD_IMAGE the base image.  Unset, this
# is the usual native alpine:edge build.
BUILD_IMAGE="${BUILD_IMAGE:-alpine:edge}"
# CASCADE=1 (set by CI, which reuses .work across runs): a package is also
# rebuilt when any aport it depends on (depends/makedepends) was rebuilt in this
# run, since the per-aport content hash below only sees an aport's own files and
# would keep a stale static consumer.  RUN_TAG identifies the run, so a rerun of
# a failed stage does not redo packages it already rebuilt.
mkdir -p "$KEYDIR"

docker run -i --rm ${DOCKER_PLATFORM:+--platform "$DOCKER_PLATFORM"} -e PKGS="$PKGS" -e CASCADE="${CASCADE:-}" -e RUN_TAG="${RUN_TAG:-}" -v "$ROOT":/repo -v "$KEYDIR":/keys -w /repo "$BUILD_IMAGE" sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk gcc-gnat which gawk bash python3 rsync sqlite-dev zlib-dev zlib-static libsodium-dev libsodium-static openssl-dev openssl-libs-static gmp-dev linux-headers gettext py3-setuptools py3-build py3-installer py3-wheel python3-dev py3-pip py3-mako py3-yaml py3-funcy py3-docutils py3-defusedxml py3-colorama py3-dateutil py3-requests py3-requests-cache py3-requests-toolbelt py3-tqdm py3-stevedore py3-resolvelib py3-psutil py3-distro >/dev/null 2>&1
adduser -D -u 1000 build >/dev/null 2>&1

# Signing key: /keys is a bind-mount of the host's ~/.config/abuild, so the same
# key signs every build and every checkout.  Generate it once (a plain RSA
# keypair; apk wants raw RSA, not OpenPGP) under a stable, URL-safe name, then
# hand a copy + abuild.conf to the build user and trust the public key so this
# build's own apk add accepts the packages it just built.
if ! ls /keys/*.rsa >/dev/null 2>&1; then
	openssl genrsa -out /keys/ada-on-alpine.rsa 4096 >/dev/null 2>&1
	openssl rsa -in /keys/ada-on-alpine.rsa -pubout \
		-out /keys/ada-on-alpine.rsa.pub >/dev/null 2>&1
fi
mkdir -p /home/build/.config/abuild
cp /keys/ada-on-alpine.rsa /keys/ada-on-alpine.rsa.pub /home/build/.config/abuild/
printf 'PACKAGER="David Walther <david@clearbrookdistillery.com>"\n' \
	> /home/build/.config/abuild/abuild.conf
printf 'PACKAGER_PRIVKEY="/home/build/.config/abuild/ada-on-alpine.rsa"\n' \
	>> /home/build/.config/abuild/abuild.conf
cp /keys/ada-on-alpine.rsa.pub /etc/apk/keys/
chown -R build:build /home/build /keys /repo

run_abuild() {
    su build -s /bin/sh -c "export HOME=/home/build SRCDEST=/home/build/distfiles; cd /repo/testing/$1; abuild"
}

# Install a package's main .apk plus any subpackages from a directory. The
# version-precise glob (`${pkg}-${pkgver}-*`, not `${pkg}-[0-9]*`) both stops
# prefix-sharing packages from over-matching (`libadalang` vs `libadalang-tools`,
# `vss` vs `vss-extra`, `gnatcoll` vs `gnatcoll-*`) and stops a stale older
# version from being installed after a pkgver bump; subpackage names come from
# the APKBUILD's `subpackages=` line (e.g. `py3-langkit` -> `py3-langkit-pyc`).
install_apks() {
    _pkg="$1" _ver="$2" _dir="$3"
    # A failed install is fatal: this is a dependency-ordered build, so a
    # swallowed apk failure would surface much later as a confusing compiler
    # or linker error. Keep apk's output visible for diagnosis.
    if ! apk add --allow-untrusted "$_dir"/"$_pkg"-"$_ver"-*.apk; then
        echo "error: failed to install $_pkg" >&2
        exit 1
    fi
    for _sub in $(sed -n 's/^subpackages="\(.*\)"$/\1/p' "/repo/testing/$_pkg/APKBUILD" 2>/dev/null); do
        _sub=${_sub%%:*}
        _sub=$(echo "$_sub" | sed "s/\$pkgname/$_pkg/")
        if ! apk add --allow-untrusted "$_dir"/"$_sub"-"$_ver"-*.apk; then
            echo "error: failed to install $_sub (subpackage of $_pkg)" >&2
            exit 1
        fi
    done
}

# Does this aport's `arch=` include the architecture we are building on?  Same
# rules as abuild: `noarch`/`all` match everything, a bare name matches itself,
# `!name` excludes, and an empty arch="" means the aport is disabled.
arch_ok() {
    _cur=$(apk --print-arch)
    _ok=0
    for _w in $(sed -n 's/^arch=//p' "/repo/testing/$1/APKBUILD" | head -1 | tr -d "\"'"); do
        case "$_w" in
            "!$_cur") return 1 ;;
            noarch|all|"$_cur") _ok=1 ;;
        esac
    done
    [ "$_ok" = 1 ]
}

# Map a package name (an aport or one of its subpackages, e.g. vss-static) to the
# aport that builds it, by longest aport-name prefix; empty if it is not ours.
ALL_APORTS=$(ls /repo/testing)
aport_of() {
    _best=""
    for _a in $ALL_APORTS; do
        case "$1" in
            "$_a"|"$_a"-*) [ ${#_a} -gt ${#_best} ] && _best=$_a ;;
        esac
    done
    echo "$_best"
}

# Did any aport that $1 depends on get rebuilt in this run (CASCADE only)?
deps_dirty() {
    [ -s /repo/.work/dirty ] || return 1
    for _d in $( cd "/repo/testing/$1" && ( set +eu; . ./APKBUILD >/dev/null 2>&1; echo "$depends $makedepends" ) ); do
        _d=${_d%%[<>=~]*}
        case "$_d" in *:*|"") continue ;; esac
        _a=$(aport_of "$_d")
        [ -n "$_a" ] && [ "$_a" != "$1" ] && grep -qx "$_a" /repo/.work/dirty && return 0
    done
    return 1
}

mkdir -p /repo/.work/hashes /repo/.work/runs
for pkg in $PKGS; do
    echo "===== BUILDING $pkg ====="
    if ! arch_ok "$pkg"; then
        echo "  (skipped: not built for $(apk --print-arch))"
        continue
    fi
    pkgver=$(sed -n 's/^pkgver=//p' "/repo/testing/$pkg/APKBUILD" | head -1)
    #  Content hash of the a port's inputs: everything under testing/<pkg>/
    #  except abuild's scratch (src/, tmp/).  Catches an upstream commit bump
    #  (via _commit/pkgver/source in the APKBUILD) and a local change (patches,
    #  APKBUILD edits) alike, so only genuinely-changed packages rebuild -- no
    #  reliance on the pkgrel convention.  Hashes contents, not mtimes.
    cur_hash=$(cd "/repo/testing/$pkg" && \
        find . \( -name src -o -name tmp \) -prune -o -type f \
            -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    prev_hash=$(cat "/repo/.work/hashes/$pkg" 2>/dev/null || true)
    force=0
    if [ -n "${CASCADE:-}" ] && deps_dirty "$pkg" \
        && [ "$(cat "/repo/.work/runs/$pkg" 2>/dev/null)" != "${RUN_TAG:-}" ]; then
        echo "  (a dependency was rebuilt this run)"
        force=1
    fi
    if [ "$force" = 0 ] && [ -n "$prev_hash" ] && [ "$prev_hash" = "$cur_hash" ] \
        && ls "/repo/.work/packages/${pkg}-${pkgver}-"*.apk >/dev/null 2>&1; then
        echo "  (cached, installing)"
        install_apks "$pkg" "$pkgver" /repo/.work/packages
        continue
    fi
    run_abuild "$pkg"
    # Persist the just-built package(s) for reuse across runs, then install them
    # so the next package's makedepends resolve (main apk + subpackages). abuild
    # drops them under a repo subdir, so copy into the flat cache first. Clear
    # any older version of this package (and its subpackages) from the cache so
    # build-image.sh's `apk add *.apk` never sees two versions of one package.
    rm -f /repo/.work/packages/${pkg}-[0-9]*.apk
    for _sub in $(sed -n 's/^subpackages="\(.*\)"$/\1/p' "/repo/testing/$pkg/APKBUILD" 2>/dev/null); do
        _sub=${_sub%%:*}
        _sub=$(echo "$_sub" | sed "s/\$pkgname/$pkg/")
        rm -f /repo/.work/packages/${_sub}-[0-9]*.apk
    done
    for apk_file in $(find /home/build/.local/share/abuild -name "${pkg}-*.apk" 2>/dev/null); do
        cp "$apk_file" /repo/.work/packages/
    done
    install_apks "$pkg" "$pkgver" /repo/.work/packages
    printf '%s\n' "$cur_hash" > "/repo/.work/hashes/$pkg"
    printf '%s\n' "${RUN_TAG:-}" > "/repo/.work/runs/$pkg"
    [ -n "${CASCADE:-}" ] && echo "$pkg" >> /repo/.work/dirty
    true
done

find / -name '*.apk' -not -path '/repo/*' -exec cp {} /repo/.work/packages/ \;
SCRIPT

echo "==> packages written to $OUT"
ls -la "$OUT"/*.apk 2>/dev/null || echo "(no .apk produced)"
