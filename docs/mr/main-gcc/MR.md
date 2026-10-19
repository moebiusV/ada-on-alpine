# main/gcc: GNAT runtime fixes: time64 on 32-bit musl, shared strings on s390x and riscv64

Target: alpine/aports, `main/gcc` (15.2.0-r9 -> r10).  NOT POSTED.  Files to
add to the aport are in `aports-main-gcc/`: the three patches and the `APKBUILD`
change (pkgrel 9 -> 10, three `source=` lines, three checksums).  Verified:
all 48 patches of the aport (Alpine's 45 and these three, in `source=` order)
apply to the gcc-15.2.0 tarball with no rejects.

Suggested commit message:

    main/gcc: GNAT runtime fixes: time64 on 32-bit, atomics on s390x/riscv64

    The GNAT runtime declares a 64-bit time_t on musl (0034) but still
    imports clock_gettime, nanosleep, pthread_cond_timedwait and select by
    their plain names.  On 32-bit musl these are the legacy entry points
    taking a 32-bit time_t; the headers redirect C calls to *_time64 with
    an asm label that an Ada pragma Import cannot see.  The legacy
    functions read the 64-bit timespec/timeval as two 32-bit fields:
    Ada.Real_Time.Clock and Ada.Calendar.Clock return garbage, delays
    measure years, and a timed wait (any timed entry call, or gprconfig at
    exit) spins forever on EINVAL.

    0044: let the C compiler say what the target does.  s-oscons-tmplt.c
    reports the sizes of timespec and its fields and whether the C library
    redirects the plain time functions (TIME64_REDIRECTED); adaint.c has six
    thin __gnat_ wrappers, compiled against the same headers, which the Ada
    units import when it is set.  time_t/timespec in the Linux units take
    their widths from System.OS_Constants.  Nothing changes where the flag
    is 0 (every 64-bit target).

    0045: enable Ada.Execution_Time on arm, riscv and s390 Linux (the POSIX
    implementation was only selected for the other Linux targets).

    0046: use the shared Ada.Strings.Unbounded family on s390x and riscv64.
    Makefile.rtl selects the reference counted implementation (and
    Indefinite_Holders, Text_IO.Unbounded_IO) for the targets with atomic
    primitives; on Linux it lists aarch64 but not s390x nor riscv64, which
    have them, so those two get the plain implementation.  Code written
    against the shared one, such as AdaCore's VSS, then fails to compile:
    a-szuvau.adb: "Shared_Wide_Wide_String_Access" is undefined.  GCC 15
    branch, 16 branch and trunk have the same gap.  Unbounded strings change
    layout on those two targets, so the runtime and what is built with it
    must agree.

## What it changes

`0044` (9 files, `gcc/ada/` only): `s-oscons-tmplt.c`, `adaint.c`,
`libgnarl/{s-linux.ads,s-osinte__linux.ads,a-exetim__posix.adb}`,
`libgnat/{s-osprim__posix.adb,g-socthi.ads,g-sothco.ads,g-calend.ads}`.
`0045`: `Makefile.rtl` (three Linux blocks).
`0046`: `Makefile.rtl` (the s390x and riscv64 Linux blocks).

## Evidence (all Alpine edge, musl 1.2.6, gcc 15.2.0)

* Real build, x86 (native 32-bit): the aport with both patches builds in 10
  minutes (languages c,c++,ada, no bootstrap) and produces the 13 normal
  packages.  With them installed, using the stock gnatmake and no private
  runtime: clock equals uptime, `delay 0.3` takes 0.300 s, a timed entry call
  0.300 s, `GNAT.Sockets.Check_Selector` with a 0.3 s timeout 0.300 s,
  `Ada.Execution_Time.Clock` works; `libgnat-15.so` exports
  `__gnat_clock_gettime`, `__gnat_nanosleep`, `__gnat_select`.
* Unpatched control: garbage clock (year 2310 / 2256), negative delays, the
  timed entry call hangs.
* Private-runtime tests on all nine architectures (see
  `docs/bugs/gnat-32bit-musl-time64-mismatch/report.txt`): the 32-bit ones
  go from broken to correct, the 64-bit ones are unchanged
  (`TIME64_REDIRECTED` = 0, no wrapper symbols).
* glibc: on Debian armhf (glibc 2.41, GNAT 14.2 with the PR 114065 backport)
  the same flag and sizes come out of GNAT's own pipeline, and importing
  `__gnat_select` fixes a bug in Debian's runtime (GNAT.Sockets select
  timeouts return immediately); not built against glibc.

* 0046, s390x and riscv64: cross compilers built from the patched source
  (plain configure/make, languages c and ada) have the shared
  Ada.Strings.Unbounded and Wide_Wide_Unbounded in their runtime; a test
  program that copies, appends to and measures both kinds of unbounded string
  prints the expected result under qemu-user on each.  AdaCore's VSS (which
  does not compile without it) then builds on both.
* The aport itself (the three patches, as in this MR) was also cross-built as
  packages for armv7, armhf, s390x and riscv64 (all `check()` runs pass; these
  are test builds only, not published).  Each was unpacked over Alpine's
  stock gcc-gnat in an Alpine edge container for that architecture under
  QEMU, and a self-checking Ada program (Real_Time and Calendar clocks,
  `delay`, `delay until`, timed entry calls, `GNAT.Sockets` Check_Selector and
  SO_RCVTIMEO timeouts, `Ada.Execution_Time`, Unbounded_String copy and
  append, 40 delays and 10 timed entry calls after deliberately dirtying the
  stack) was compiled with the stock `gnatmake` and run: 13/13 checks pass
  on all four.  `libgnat-15.so` exports the six `__gnat_*` wrappers on armv7
  and armhf and none on s390x and riscv64 (64-bit long, flag 0).  With the
  stock r9 packages the same program does not even compile on any of the four
  ("Execution_Time is not supported in this configuration").
* The cross compilers of all seven non-x86 architectures, configured like the
  aport (--enable-default-pie --enable-default-ssp, --with-mode=thumb on
  armv7, the aport's per-arch options), built from the patched source, are
  what the overlay's Ada aports are being built with on armv7, armhf, aarch64,
  ppc64le, s390x, riscv64 and loongarch64; the sweep is in progress.

## Not done / caveats

* 0046 changes the layout of Unbounded_String, Wide_Unbounded_String and
  Wide_Wide_Unbounded_String on s390x and riscv64.  Ada code compiled against
  the old libgnat there must be rebuilt.  The only packages in Alpine edge's
  repositories that depend on libgnat on those architectures are gcc-gnat and
  testing/gprbuild (checked against the APKINDEX of main, community and
  testing on 2026-10-19); the pkgrel bump rebuilds the former, and gprbuild
  needs a rebuild.
* Only x86 has been built natively as a real gcc package; armv7, armhf, s390x
  and riscv64 were cross-built from the aport (see Evidence), the other
  architectures only with plain configure/make cross builds.  The aport needs
  a CI run on every architecture.
* 0046 has not been reported or searched in GCC's Bugzilla (bot check) and
  has not been looked at against GCC 16/17 beyond Makefile.rtl having the
  same gap.
* Other GCC versions (checked 2026-10-19 against the git branches, applying
  the three patches in order to the files they touch):
  - gcc-15 branch (15.3.1): 0044, 0045 and 0046 apply cleanly.  The 15
    branch has no System.C_Time (Debian's 15.3.0-4 carries it as a backport
    of PR ada/114065), so the aport keeps working when Alpine goes to 15.3.
  - gcc-16 branch (16.2.1) and trunk (17): 0045 and 0046 apply cleanly, but
    0044 does not (4 of its 9 files conflict: s-linux.ads, s-osinte__linux.ads,
    s-osprim__posix.adb, g-calend.ads), because System.C_Time now defines
    time_t and timespec from System.OS_Constants.  The bug itself is still
    there: both still import the plain "clock_gettime", "pthread_cond_timedwait"
    and "select" (musl keeps the 32-bit time_t entry points under those
    names, and C_Time only mentions the glibc __TIME_BITS=64 case).  So an
    upstream submission needs 0044 rebased onto C_Time (the same
    __gnat_ wrappers, driven by the TIME64_REDIRECTED flag); not done.
  GCC Bugzilla (PR ada/114065 and others) was not searched (bot check).
* The aport used `--disable-bootstrap` for the test build; the MR's
  APKBUILD does not change that.
