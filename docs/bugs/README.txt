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

  vss-ucd-big-endian/
      VSS decodes its Unicode property table through a packed-record overlay
      that is only right on little-endian: on s390x Display_Width of "(" is 2.
      Patch (shifts and masks in Extract_Core_Data) included.

  adasat-descriptor-size-riscv64/
      AdaSAT.Vectors asserts the array descriptor is exactly the two bounds;
      GNAT pads it to 16 bytes for 16-byte aligned elements (riscv64), so
      elaboration raises Assertion_Error.  Patch included.

  langkit-strict-alignment/
      Langkit_Support and the bootstrap Liblktlang fail -gnatwe alignment
      checks on 32-bit ARM and riscv64.  Three patches included.

  hbnf-libhbnf-sources/
      libhbnf.gpr omits four units, so a clean checkout cannot build hbnf.
      Patch for moebiusV/hbnf (the overlay carries it until then).

  qemu-7.2-s390x-host-crash/
      The intermittent gnat1 segfaults on local s390x are qemu-user 7.2.0
      crashing itself (same address in every core), not gcc; none under
      10.2.3.  Evidence and A/B numbers; no patch.
