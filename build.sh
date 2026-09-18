#!/bin/sh
# Build the Ada toolchain aports inside the Alpine musl image (no cross-
# compilation), in dependency order. Requires Docker. Produces the .apk files
# under .work/packages/. The build runs abuild as a non-root user, bootstraps
# gprbuild, installs it, then builds the rest against it in order.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT/.work/packages"
mkdir -p "$OUT"

# Dependency order: each package's build deps must precede it. Everything
# through gnatcoll-projects builds; libadalang is next (OOMs on <8GB), then
# the ada_language_server dependency spine (drafted, not yet validated).
PKGS="${PKGS:-gprbuild xmlada aunit gnatcoll gnatcoll-db gnatcoll-gmp gnatcoll-iconv spawn vss aws adasat py3-e3-core prettier-ada py3-langkit langkit gpr libgpr gnatcoll-projects libadalang templates-parser vss-extra xdiff libadalang-tools lal-refactor gnatformat gnatdoc fswatch ada-libfswatch markdown ada_language_server}"

docker run -i --rm -e PKGS="$PKGS" -v "$ROOT":/repo -w /repo alpine:edge sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk gcc-gnat which gawk python3 rsync sqlite-dev zlib-dev zlib-static gmp-dev gettext py3-setuptools py3-build py3-installer py3-wheel python3-dev py3-pip py3-mako py3-yaml py3-funcy py3-docutils py3-defusedxml py3-colorama py3-dateutil py3-requests py3-requests-cache py3-requests-toolbelt py3-tqdm py3-stevedore py3-resolvelib py3-psutil py3-distro >/dev/null 2>&1
adduser -D -u 1000 build >/dev/null 2>&1

# Generate a signing key (keygen -a writes to /root/.config/abuild), trust its
# public key, and hand a copy to the build user.
abuild-keygen -a -n >/dev/null 2>&1
cp /root/.config/abuild/*.rsa.pub /etc/apk/keys/
mkdir -p /home/build/.config/abuild
cp /root/.config/abuild/*.rsa /root/.config/abuild/*.rsa.pub /root/.config/abuild/abuild.conf /home/build/.config/abuild/ 2>/dev/null || true
sed -i "s|/root/.config/abuild|/home/build/.config/abuild|g" /home/build/.config/abuild/abuild.conf
chown -R build:build /home/build /repo

run_abuild() {
    su build -s /bin/sh -c "export HOME=/home/build SRCDEST=/home/build/distfiles; cd /repo/testing/$1; abuild"
}

# Install a package's main .apk plus any subpackages from a directory. The
# version-precise glob (`${pkg}-[0-9]*`) stops prefix-sharing packages from
# over-matching (`libadalang` vs `libadalang-tools`, `vss` vs `vss-extra`,
# `gnatcoll` vs `gnatcoll-*`); subpackage names come from the APKBUILD's
# `subpackages=` line (e.g. `py3-langkit` -> `py3-langkit-pyc`).
install_apks() {
    _pkg="$1" _dir="$2"
    apk add --allow-untrusted "$_dir"/"$_pkg"-[0-9]*.apk >/dev/null 2>&1 || true
    for _sub in $(sed -n 's/^subpackages="\(.*\)"$/\1/p' "/repo/testing/$_pkg/APKBUILD" 2>/dev/null); do
        _sub=${_sub%%:*}
        _sub=$(echo "$_sub" | sed "s/\$pkgname/$_pkg/")
        apk add --allow-untrusted "$_dir"/"$_sub"-[0-9]*.apk >/dev/null 2>&1 || true
    done
}

for pkg in $PKGS; do
    echo "===== BUILDING $pkg ====="
    if ls /repo/.work/packages/${pkg}-[0-9]*.apk >/dev/null 2>&1; then
        echo "  (cached, installing)"
        install_apks "$pkg" /repo/.work/packages
        continue
    fi
    run_abuild "$pkg"
    # Persist the just-built package(s) for reuse across runs, then install them
    # so the next package's makedepends resolve (main apk + subpackages). abuild
    # drops them under a repo subdir, so copy into the flat cache first.
    for apk_file in $(find /home/build/.local/share/abuild -name "${pkg}-*.apk" 2>/dev/null); do
        cp "$apk_file" /repo/.work/packages/
    done
    install_apks "$pkg" /repo/.work/packages
done

find / -name '*.apk' -not -path '/repo/*' -exec cp {} /repo/.work/packages/ \;
SCRIPT

echo "==> packages written to $OUT"
ls -la "$OUT"/*.apk 2>/dev/null || echo "(no .apk produced)"
