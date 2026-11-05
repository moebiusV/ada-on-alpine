#!/bin/sh
# Run by build.sh (as the build user, in testing/ada_language_server) after a step of
# this aport failed.  Not in the aport directory: a file there would change the
# aport's content hash and make build.sh throw away the kept build tree.
#
# `check` runs "ada_language_server --version"; on s390x it died at start-up with
# "CONSTRAINT_ERROR : vss-implementation-utf8_strings-mutable_operations.adb:700
# range check failed" and no traceback.  Relink the server with the binder's -E
# switch (store exception tracebacks), run it again and turn the addresses of the
# call stack into function names.  The linked server is put back afterwards, so the
# step can be repeated on the same tree.
cd /repo/testing/ada_language_server/src/ada_language_server-*/ 2>/dev/null || exit 0
bin=.obj/server/ada_language_server
[ -x "$bin" ] || exit 0
cp -p "$bin" "$bin.orig" || exit 0
export GPR_PROJECT_PATH=/usr/share/gpr
gprbuild -q -j1 -P gnat/lsp_server.gpr -XBUILD_MODE=prod -XLSP_OS=unix \
    -XALS_LIBRARY_TYPE=static -XLIBRARY_TYPE=static -XXMLADA_BUILD=static \
    -XGPR_BUILD=static -XLIBFSWATCH_PREFIX=/usr -XVERSION=diagnose \
    -bargs -E 2>&1 | tail -5
out=$("$bin" --version 2>&1)
echo "--- ada_language_server --version, relinked with the binder's -E switch:"
echo "$out" | head -12
addrs=$(echo "$out" | awk '/Call stack traceback locations/ { getline; print; exit }')
if [ -n "$addrs" ] && command -v addr2line >/dev/null 2>&1; then
    echo "--- call stack:"
    # shellcheck disable=SC2086
    addr2line -f -C -e "$bin" $addrs | paste - - | cut -c1-200
fi
mv -f "$bin.orig" "$bin"
exit 0
