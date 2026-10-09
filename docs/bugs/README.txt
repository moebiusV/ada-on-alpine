One directory per bug found while bringing the Ada toolchain up on Alpine.
Each holds the detailed write-up (report.txt), a reproducer, and the patch
or workaround, so it can be filed or applied as a unit.

  armv7-gcc-stack-clash-miscompile/
      GCC 15.2 miscompiles the GNAT binder's adainit on armv7 with
      -Os -fstack-clash-protection (local kept below the stack pointer).
      Workaround patch for the gprbuild aport included.

  gnat-32bit-musl-time64-mismatch/
      The GNAT runtime on 32-bit musl uses a 64-bit timespec but imports the
      32-bit-time C entry points: wrong clocks and Timed_Sleep spins on
      EINVAL (gprconfig hangs at exit on x86 and armv7).  Patch for the
      runtime (gcc aport) and reproducer included.
