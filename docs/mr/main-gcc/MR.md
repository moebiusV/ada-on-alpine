# main/gcc: fix the GNAT runtime's time functions on 32-bit targets (time64)

Target: alpine/aports, `main/gcc` (15.2.0-r9 -> r10).  NOT POSTED.  Files to
add to the aport are in `aports-main-gcc/`: the two patches and the `APKBUILD`
change (pkgrel 9 -> 10, two `source=` lines, two checksums).

Suggested commit message:

    main/gcc: fix GNAT time functions on 32-bit (x86, armhf, armv7)

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

## What it changes

`0044` (9 files, `gcc/ada/` only): `s-oscons-tmplt.c`, `adaint.c`,
`libgnarl/{s-linux.ads,s-osinte__linux.ads,a-exetim__posix.adb}`,
`libgnat/{s-osprim__posix.adb,g-socthi.ads,g-sothco.ads,g-calend.ads}`.
`0045`: `Makefile.rtl` (three Linux blocks).

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

## Not done / caveats

* Only x86 has been built as a real gcc; armv7 and armhf (and the rest) were
  tested with a private runtime copy, a cross build is next.
* Related: GCC trunk (GCC 16) reworked these types (System.C_Time,
  PR ada/114065, commit 41974d6ed3) and still imports the plain names on
  musl; an upstream patch has to be rebased onto it.  GCC Bugzilla was not
  searched (bot check).
* The aport used `--disable-bootstrap` for the test build; the MR's
  APKBUILD does not change that.
