#!/bin/sh
# Build the Ada toolchain aports inside the Alpine musl image (no cross-
# compilation), in dependency order. Requires Docker. Produces the .apk files
# under .work/packages/. The build runs abuild as a non-root user, bootstraps
# gprbuild, installs it, then builds the rest against it in order.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT/.work/packages"
mkdir -p "$OUT"

# abuild comes first: it carries the patch that drops -fstack-clash-protection on
# 32-bit ARM (docs/mr/abuild/), and every later build then uses the patched one.
# Dependency order: each package's build deps must precede it. libadalang OOMs
# on <8GB (built -j1). gpr2-tools (installs as gprbuild2 etc., alongside classic
# gprbuild) is disabled/WIP and not in the default list: gprbuild2 crashes on
# library projects. afl++ (a C/C++ fuzzing tool) builds against neither gprbuild
# nor gpr2-tools, so it sits after the spine.
PKGS="${PKGS:-abuild gprbuild bracke-cryptolib bracke-zlib libsodium-ada mustache-ada hbnf imsg-ada xmlada aunit buildabook gnatcoll gnatcoll-db gnatcoll-gmp gnatcoll-iconv spawn vss aws adasat py3-e3-core py3-e3-testsuite prettier-ada py3-langkit langkit libadagpr2 libadagpr gnatcoll-projects libadalang templates-parser vss-extra xdiff libadalang-tools lal-refactor gnatformat ada-markdown gnatdoc fswatch ada-libfswatch ada_language_server afl++ newlisp}"

# The signing key lives on the host in ~/.config/abuild (Alpine's standard abuild
# key location), not in this repo, so every checkout and every machine signs with
# the same key.  bind-mount it into the container below as /keys.
KEYDIR="${KEYDIR:-$HOME/.config/abuild}"
# JOBS (if set) is passed to abuild; without it abuild uses one job per CPU.
# CI sets JOBS=1 on emulated architectures, where parallel compilers only fight over
# the emulated memory (OOM kills).
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

docker run -i --rm ${DOCKER_PLATFORM:+--platform "$DOCKER_PLATFORM"} ${DOCKER_CPUSET:+--cpuset-cpus "$DOCKER_CPUSET"} ${DOCKER_EXTRA:-} -e PKGS="$PKGS" -e CASCADE="${CASCADE:-}" -e RUN_TAG="${RUN_TAG:-}" -e DEADLINE_EPOCH="${DEADLINE_EPOCH:-}" -e HARD_EPOCH="${HARD_EPOCH:-}" -e PARTIAL_DEADLINE_EPOCH="${PARTIAL_DEADLINE_EPOCH:-}" -e PARTIAL_AFTER_SECONDS="${PARTIAL_AFTER_SECONDS:-}" ${JOBS:+-e JOBS="$JOBS"} -v "$ROOT":/repo -v "$KEYDIR":/keys -w /repo "$BUILD_IMAGE" sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk zstd gcc-gnat which gawk bash python3 rsync sqlite-dev zlib-dev zlib-static libsodium-dev libsodium-static openssl-dev readline-dev libffi-dev openssl-libs-static gmp-dev linux-headers gettext py3-setuptools py3-build py3-installer py3-wheel python3-dev py3-pip py3-mako py3-yaml py3-funcy py3-docutils py3-defusedxml py3-colorama py3-dateutil py3-requests py3-requests-cache py3-requests-toolbelt py3-tqdm py3-stevedore py3-resolvelib py3-psutil py3-distro scdoc kyua libcap-utils git pkgconf >/tmp/setup.log 2>&1 || { cat /tmp/setup.log >&2; echo "error: build-tool setup failed" >&2; exit 1; }
adduser -D -u 1000 build >/dev/null 2>&1 || true

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

# Install an aport's own build dependencies (makedepends, makedepends_build and
# _host, checkdepends) before building it, so a new aport needs no edit to the
# fixed tool list above.  The APKBUILD is sourced the way abuild sources it;
# `!conflicts` and version operators are stripped.  Packages that are not in the
# repositories (aports of ours that come later) fail the install harmlessly:
# abuild then reports what is really missing.
install_makedepends() {
    # abuild's own variables: aports branch on CTARGET_ARCH, CBUILD, CHOST, CTARGET.
    _arch=$(apk --print-arch)
    _deps=$(cd "/repo/testing/$1" && CARCH=$_arch CTARGET_ARCH=$_arch CBUILD=$_arch CHOST=$_arch CTARGET=$_arch sh -c '
        . ./APKBUILD >/dev/null 2>&1
        for d in $makedepends $makedepends_build $makedepends_host $checkdepends; do
            case "$d" in "!"*) ;; *) echo "${d%%[<>=~]*}" ;; esac
        done' | sort -u)
    [ -n "$_deps" ] || return 0
    # shellcheck disable=SC2086
    if ! apk add --no-cache $_deps >/tmp/makedepends.log 2>&1; then
        # one unknown name fails the whole batch: retry one by one
        for _d in $_deps; do
            apk add --no-cache "$_d" >/tmp/makedepends.log 2>&1 \
                || echo "  (makedepend $_d of $1 not installable here)"
        done
    fi
}

# After a failed build, show what e3-testsuite recorded for the tests that
# failed (out/new/<test>.yaml + .log under the kept src/): CI keeps only the
# tail of the log, so end with the failing names and the first outputs.
dump_testsuite_failures() {
    # e3-testsuite writes <output-dir>/<test>.yaml and <test>.log; the output
    # dir defaults to ./out under the directory the suite was started from.
    _bad=$(find "/repo/testing/$1/src" -path '*/out/*' -name '*.yaml' 2>/dev/null \
        | while read -r _y; do grep -qE '(^|[: ])(FAIL|ERROR|XPASS)([^A-Za-z]|$)' "$_y" && echo "$_y"; done)
    [ -n "$_bad" ] || return 1
    echo "===== failing tests of $1 (e3-testsuite results) ====="
    echo "$_bad" | head -4 | while read -r _y; do
        echo "--- ${_y%.yaml}"
        # the diff of expected and actual output, when the log has one
        grep -E '^[-+@]' "${_y%.yaml}.log" 2>/dev/null | head -9 | cut -c1-150
    done
    echo "$_bad" | sed 's|.*/out/||; s|\.yaml$||' | sed 's/^/FAILED TEST: /'
}

# After any failed build: which gcc family is installed and whether the runtime's
# .ali files match its sources (a mix of gcc versions shows up here).
dump_ada_runtime_state() {
    echo "===== installed gcc family ====="
    apk list -I 2>/dev/null | grep -E '^(gcc|g\+\+|libgnat|libgcc|libstdc\+\+|libatomic|libgomp)[a-z+-]*-[0-9]' | cut -d' ' -f1 | tr '\n' ' '
    echo
    # Does the shipped source still have the checksum recorded in its .ali?
    for _u in a-strunb s-tpoben; do
        _inc=$(ls -d /usr/lib/gcc/*/*/adainclude | head -1)
        _t=$(mktemp -d); cp "$_inc/$_u.ads" "$_inc/$_u.adb" "$_t/" 2>/dev/null
        ( cd "$_t" && gcc -c -gnatg -gnatc -gnatws "$_u.adb" >/dev/null 2>&1; \
          echo "recompiled now:  $(grep -h "^D $_u.adb" "$_u.ali" 2>/dev/null | cut -f1,3,4)"; \
          echo "installed .ali:  $(grep -h "^D $_u.adb" "$_inc"/../adalib/"$_u".ali | cut -f1,3,4)" )
    done
    # Reproduce a stand-alone-library bind in miniature against this runtime.
    command -v gprbuild >/dev/null 2>&1 && for _v in "-O2 -gnatn" "-O2"; do
        _d=$(mktemp -d); cd "$_d" || continue
        cat > sal_pkg.ads <<'ADS'
with Ada.Strings.Unbounded;
package Sal_Pkg is
   protected type P is
      procedure Inc;
      function Get return Natural;
   private
      N : Natural := 0;
   end P;
   function Name return Ada.Strings.Unbounded.Unbounded_String;
end Sal_Pkg;
ADS
        cat > sal_pkg.adb <<'ADB'
package body Sal_Pkg is
   protected body P is
      procedure Inc is begin N := N + 1; end Inc;
      function Get return Natural is begin return N; end Get;
   end P;
   function Name return Ada.Strings.Unbounded.Unbounded_String is
   begin
      return Ada.Strings.Unbounded.To_Unbounded_String ("x");
   end Name;
end Sal_Pkg;
ADB
        cat > sal.gpr <<GPR
library project Sal is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Library_Name use "sal";
   for Library_Dir use "lib";
   for Library_Kind use "relocatable";
   for Library_Interface use ("sal_pkg");
   for Library_Standalone use "standard";
   package Compiler is for Default_Switches ("Ada") use ("$(echo $_v | sed 's/ /","/g')"); end Compiler;
end Sal;
GPR
        mkdir -p obj lib
        echo "--- mini SAL ($_v): $(gprbuild -q -p -P sal.gpr >bind.log 2>&1 && echo OK || { echo FAILED; grep -c 'must be compiled' bind.log; head -4 bind.log | cut -c1-140; })"
        cd /
    done
    for _u in s-tpoben s-oscons; do
        ls -l --full-time /usr/lib/gcc/*/*/adalib/$_u.ali /usr/lib/gcc/*/*/adainclude/$_u.ad[sb] 2>/dev/null | awk '{print $6, $7, $9}'
    done
}

# Run abuild for $1 (content hash $2).  A big package can take longer than one CI
# job, so the build is resumable across jobs: at PARTIAL_DEADLINE_EPOCH abuild is
# interrupted (SIGINT stops make cleanly), the kept build tree is packed into
# .work/partial/ with the content hash, and 75 is returned so the stage is marked
# incomplete.  The next job unpacks the tree (if the hash still matches) and runs
# the build, check, package and index steps on it, instead of starting over
# ("abuild" alone would clean src/ and re-apply the patches).
run_abuild() {
    _p=$1 _h=$2 _dir=/repo/testing/$1 _part=/repo/.work/partial
    install_makedepends "$_p"
    mkdir -p "$_part"
    _cmd="abuild -K -k"
    if [ "$(cat "$_part/$_p.hash" 2>/dev/null)" = "$_h" ] \
        && { [ -d "$_dir/src" ] || [ -s "$_part/$_p.tar.zst" ]; }; then
        echo "===== $_p: resuming the saved build tree ====="
        # In CI the stage action has already unpacked the tree (natively: this
        # script may run under emulation); unpack here only if it has not.
        [ -d "$_dir/src" ] || zstd -dc "$_part/$_p.tar.zst" | tar -C "$_dir" -xf -
        chown -R build:build "$_dir"
        # Generators (langkit's, for one) rewrite their output on every run, so
        # every source looks newer than its object and gprbuild would recompile
        # everything.  "gprbuild -m" (minimal recompilation) skips a unit whose
        # source changed only in timestamp: put a wrapper first in PATH.
        mkdir -p /opt/gprbuild-m
        printf '#!/bin/sh\nexec %s -m "$@"\n' "$(command -v gprbuild)" > /opt/gprbuild-m/gprbuild
        chmod 755 /opt/gprbuild-m/gprbuild
        _cmd="export PATH=/opt/gprbuild-m:\$PATH; abuild -d -K -k build && abuild -d -K -k check && abuild -d -K -k rootpkg && abuild -d -K -k index"
    fi
    setsid su build -s /bin/sh -c "export HOME=/home/build SRCDEST=/home/build/distfiles; cd $_dir; $_cmd" &
    _pid=$!
    # (PARTIAL_AFTER_SECONDS: test hook, stop this build that many seconds after it started)
    _stop_at=${PARTIAL_DEADLINE_EPOCH:-}
    [ -n "${PARTIAL_AFTER_SECONDS:-}" ] && _stop_at=$(( $(date +%s) + PARTIAL_AFTER_SECONDS ))
    while kill -0 "$_pid" 2>/dev/null; do
        if [ -n "$_stop_at" ] && [ "$(date +%s)" -ge "$_stop_at" ]; then
            echo "===== $_p: out of time; interrupting and saving the build tree ====="
            kill -s INT -- "-$_pid" 2>/dev/null || true
            _i=0
            while kill -0 "$_pid" 2>/dev/null && [ "$_i" -lt 12 ]; do sleep 5; _i=$((_i + 1)); done
            kill -s KILL -- "-$_pid" 2>/dev/null || true
            wait "$_pid" 2>/dev/null || true
            # The tree stays in $_dir.  The hash says what it was built from;
            # the .pending marker tells the stage action (on the runner, at
            # native speed) to pack it into .work/partial/$_p.tar.zst.
            printf '%s\n' "$_h" > "$_part/$_p.hash"
            : > "$_part/$_p.pending"
            echo "  build tree kept in $_dir for the next job"
            return 75
        fi
        sleep 10
    done
    wait "$_pid" && _rc=0 || _rc=$?
    if [ "$_rc" != 0 ]; then
        dump_testsuite_failures "$_p" || dump_ada_runtime_state
        return "$_rc"
    fi
    # built: drop the saved tree and the kept build dirs
    rm -f "$_part/$_p.tar.zst" "$_part/$_p.hash" "$_part/$_p.pending"
    rm -rf "$_dir/src" "$_dir/pkg" "$_dir/tmp"
}

# Install a package's main .apk plus any subpackages from a directory. The
# version-precise glob (`${pkg}-${pkgver}-*`, not `${pkg}-[0-9]*`) both stops
# prefix-sharing packages from over-matching (`libadalang` vs `libadalang-tools`,
# `vss` vs `vss-extra`, `gnatcoll` vs `gnatcoll-*`) and stops a stale older
# version from being installed after a pkgver bump; subpackage names come from
# the APKBUILD's `subpackages=` line (e.g. `py3-langkit` -> `py3-langkit-pyc`).
install_apks() {
    _pkg="$1" _ver="$2" _dir="$3"
    # What the aport really built is in its manifest (every package whose origin
    # is this aport, subpackages that depend on the architecture or on options
    # included).  Install them in ONE transaction: a family such as gcc must
    # move to the new version together or apk refuses (libgomp=..., gcc=...).
    if [ -s "/repo/.work/manifest/$_pkg" ]; then
        _files=""
        while read -r _f; do
            case "$_f" in apkbuild-*|abuild-rootbld-*) continue ;; esac
            _files="$_files $_dir/$_f"
        done < "/repo/.work/manifest/$_pkg"
        # shellcheck disable=SC2086
        if ! apk add --allow-untrusted $_files; then
            echo "error: failed to install the packages of $_pkg" >&2
            exit 1
        fi
        return 0
    fi
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
        # abuild's perl/ruby helper tools are built and published but not installed here
        case "$_sub" in apkbuild-*|abuild-rootbld) continue ;; esac
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

# CI runs the build in stages, each in a fresh container.  A stage's packages
# build against the earlier stages' output, which is in .work/packages but not
# installed here, so install it all up front (a package rebuilt below simply
# upgrades its entry).
# A cache can hold the packages of an aport whose build or install failed half
# way (the hash is written only after both succeeded).  Such leftovers can be an
# inconsistent family (some of gcc's packages at the new version), which apk
# then refuses to install: drop every cached package whose aport has no hash.
if [ -n "${CASCADE:-}" ]; then
    for _f in /repo/.work/packages/*.apk; do
        [ -e "$_f" ] || break
        _origin=$(tar -xzOf "$_f" .PKGINFO 2>/dev/null | sed -n 's/^origin = //p' | head -1)
        if [ -n "$_origin" ] && [ -d "/repo/testing/$_origin" ] && [ ! -s "/repo/.work/hashes/$_origin" ]; then
            echo "  (dropping $(basename "$_f"): $_origin was not completed)"
            rm -f "$_f"
        fi
    done
fi

if [ -n "${CASCADE:-}" ] && ls /repo/.work/packages/*.apk >/dev/null 2>&1; then
    echo "===== installing previously built packages ====="
    if ! apk add --allow-untrusted /repo/.work/packages/*.apk; then
        echo "error: failed to install previously built packages" >&2
        exit 1
    fi
fi

rm -f /repo/.work/incomplete
for pkg in $PKGS; do
    # CI checkpoint: out of time for this job, so stop cleanly between packages
    # (what is built is kept; CI resumes the stage in a new job).
    # DEADLINE_EPOCH: do not start anything after this (soft).  HARD_EPOCH: the
    # job is killed then and loses its work, so do not start a package whose last
    # recorded duration (.work/durations, seconds) would run past it.
    _now=$(date +%s)
    _est=$(cat "/repo/.work/durations/$pkg" 2>/dev/null || echo 0)
    # Never refuse the first package this job builds: a job that builds nothing
    # makes no progress, and CI would resume it forever.
    if [ "${_built_any:-0}" = 1 ] \
        && { { [ -n "${DEADLINE_EPOCH:-}" ] && [ "$_now" -ge "$DEADLINE_EPOCH" ]; } \
        || { [ -n "${HARD_EPOCH:-}" ] && [ $(( _now + _est + _est / 5 )) -ge "$HARD_EPOCH" ]; }; }; then
        echo "===== time budget used up before $pkg (estimate ${_est}s): checkpointing ====="
        touch /repo/.work/incomplete
        break
    fi
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
    # Toolchain stamp: when this run uses a carrier gcc (hashes/gcc, from the
    # gcc stage or its seed), anything built against another gcc, or against none
    # (the stock one), is stale: Ada libraries record the runtime's s-oscons.
    tc=$(cat /repo/.work/hashes/gcc 2>/dev/null || true)
    if [ "$force" = 0 ] && [ "$pkg" != gcc ] && [ -n "$tc" ] \
        && [ "$(cat "/repo/.work/toolchain/$pkg" 2>/dev/null)" != "$tc" ]; then
        echo "  (built with another gcc than $(printf %s "$tc" | cut -c1-12))"
        force=1
    fi
    if [ "$force" = 0 ] && [ -n "$prev_hash" ] && [ "$prev_hash" = "$cur_hash" ] \
        && ls "/repo/.work/packages/${pkg}-${pkgver}-"*.apk >/dev/null 2>&1; then
        echo "  (cached, installing)"
        install_apks "$pkg" "$pkgver" /repo/.work/packages
        continue
    fi
    _t0=$(date +%s)
    _built_any=1
    _rc=0
    run_abuild "$pkg" "$cur_hash" || _rc=$?
    if [ "$_rc" = 75 ]; then
        touch /repo/.work/incomplete
        break
    elif [ "$_rc" != 0 ]; then
        exit "$_rc"
    fi
    mkdir -p /repo/.work/durations
    printf '%s\n' $(( $(date +%s) - _t0 )) > "/repo/.work/durations/$pkg"
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
    # Manifest: every package this aport built (by origin), and drop older
    # versions of each from the cache.
    mkdir -p /repo/.work/manifest
    : > "/repo/.work/manifest/$pkg"
    for apk_file in $(find /home/build/.local/share/abuild -name '*.apk' 2>/dev/null); do
        _info=$(tar -xzOf "$apk_file" .PKGINFO 2>/dev/null) || continue
        printf '%s\n' "$_info" | grep -qx "origin = $pkg" || continue
        _name=$(printf '%s\n' "$_info" | sed -n 's/^pkgname = //p' | head -1)
        _ver_full=$(printf '%s\n' "$_info" | sed -n 's/^pkgver = //p' | head -1)
        case "$_ver_full" in "$pkgver"-r*) ;; *) continue ;; esac
        rm -f /repo/.work/packages/"$_name"-[0-9]*.apk
        cp "$apk_file" /repo/.work/packages/
        basename "$apk_file" >> "/repo/.work/manifest/$pkg"
    done
    install_apks "$pkg" "$pkgver" /repo/.work/packages
    printf '%s\n' "$cur_hash" > "/repo/.work/hashes/$pkg"
    mkdir -p /repo/.work/toolchain
    printf '%s\n' "$tc" > "/repo/.work/toolchain/$pkg"
    printf '%s\n' "${RUN_TAG:-}" > "/repo/.work/runs/$pkg"
    [ -n "${CASCADE:-}" ] && echo "$pkg" >> /repo/.work/dirty
    true
done

find / -name '*.apk' -not -path '/repo/*' -exec cp {} /repo/.work/packages/ \;
SCRIPT

echo "==> packages written to $OUT"
ls -la "$OUT"/*.apk 2>/dev/null || echo "(no .apk produced)"
