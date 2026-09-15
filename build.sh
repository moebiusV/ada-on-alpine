#!/bin/sh
# Build both packages inside the Alpine musl image (no cross-compilation).
#
# Requires Docker. Produces the .apk files under .work/packages/. The build
# runs abuild as a non-root user (abuild refuses root), bootstraps gprbuild,
# installs it, then builds xmlada against it.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT/.work/packages"
mkdir -p "$OUT"

docker run -i --rm -v "$ROOT":/repo -w /repo alpine:edge sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk gcc-gnat which gawk >/dev/null 2>&1
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
    su build -s /bin/sh -c "export HOME=/home/build SRCDEST=/home/build/distfiles; cd /repo/$1; abuild"
}

run_abuild testing/gprbuild

# Install the just-built gprbuild so libxmlada's makedepends resolves.
GPRBUILD_APK=$(find / -name 'gprbuild-*.apk' | head -1)
apk add --allow-untrusted "$GPRBUILD_APK" >/dev/null 2>&1

run_abuild testing/xmlada

find / -name '*.apk' -exec cp {} /repo/.work/packages/ \;
SCRIPT

echo "==> packages written to $OUT"
ls -la "$OUT"/*.apk 2>/dev/null || echo "(no .apk produced)"
