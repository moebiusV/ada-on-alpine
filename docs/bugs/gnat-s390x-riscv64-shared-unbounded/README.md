# s390x and riscv64 Linux: GNAT runtime without the shared Unbounded strings

`gcc/ada/Makefile.rtl` compiles the "shared" (reference counted, atomic counters)
implementation of `Ada.Strings.[Wide_[Wide_]]Unbounded`, `Ada.Containers.Indefinite_Holders`
and `Ada.Text_IO.Unbounded_IO` only for the targets that list `ATOMICS_TARGET_PAIRS`.
On Linux those are x86, x86_64, arm, aarch64, powerpc, loongarch, alpha, ia64, sparc, ...
but **not s390x and riscv64**, in GCC 15.2/15.3, 16.2 and master (17).  Both targets have
the instructions (z196+ interlocked access, RV64GC "A").

AdaCore's VSS (`vss_gnat`, `Ada.Strings.Wide_Wide_Unbounded.VSS_Aux`) uses
`Shared_Wide_Wide_String` and so fails to compile there:
`a-szuvau.adb:18:21: error: "Shared_Wide_Wide_String_Access" is undefined`.

* `0046-...patch` - the fix, for the `main/gcc` MR next to 0044/0045 (and GCC).
  Verified: toolchains built from the patched source run a shared-string test under qemu-user.
* `vss-fallback-nonshared-unbounded.patch` - a second VSS body for runtimes without the shared
  strings.  Not used: the runtime is the right place to fix it.
