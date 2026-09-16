#!/bin/sh
# Build the Ada toolchain aports inside the Alpine musl image (no cross-
# compilation), in dependency order. Requires Docker. Produces the .apk files
# under .work/packages/. The build runs abuild as a non-root user, bootstraps
# gprbuild, installs it, then builds the rest against it in order.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT/.work/packages"
mkdir -p "$OUT"

# Dependency order: each package's build deps must precede it. The langkit tier
# (adasat .. langkit) is new and still needs Docker validation; gpr / libadalang
# / ada_language_server remain scaffolds (unbuilt).
PKGS="${PKGS:-gprbuild xmlada aunit gnatcoll gnatcoll-db gnatcoll-gmp gnatcoll-iconv spawn vss aws adasat prettier-ada py3-langkit langkit}"

docker run -i --rm -e PKGS="$PKGS" -v "$ROOT":/repo -w /repo alpine:edge sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk gcc-gnat which gawk python3 rsync sqlite-dev zlib-dev >/dev/null 2>&1
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

for pkg in $PKGS; do
    echo "===== BUILDING $pkg ====="
    run_abuild "$pkg"
    # Install the just-built package so the next one's makedepends resolve.
    apk_file=$(find /home/build/.local/share/abuild -name "${pkg}-*.apk" | head -1)
    if [ -n "$apk_file" ]; then
        apk add --allow-untrusted "$apk_file" >/dev/null 2>&1 || true
    fi
done

find / -name '*.apk' -not -path '/repo/*' -exec cp {} /repo/.work/packages/ \;
SCRIPT

echo "==> packages written to $OUT"
ls -la "$OUT"/*.apk 2>/dev/null || echo "(no .apk produced)"
