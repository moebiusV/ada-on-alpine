# ada-on-alpine

Alpine `aports` overlay for the Ada/GNAT build toolchain, targeting **edge**
(gcc 15). Layout mirrors `aports`, so each package copies straight into an
aports fork for a Merge Request. The end goal is the Ada Language Server
(`ada_language_server`).

## Packages

38 packages, all into aports `testing/` (plus three `pyc` subpackages).

| Path | Package | Status |
| --- | --- | --- |
| `testing/gprbuild/` | `gprbuild` | Built: upgrade of the existing aport (maintainer Ian Douglas Scott) to 26.0.0 |
| `testing/bracke-cryptolib/` | `bracke-cryptolib` | Built: pure-Ada cryptography (checksums, ciphers, MACs) |
| `testing/bracke-zlib/` | `bracke-zlib` | Built: pure-Ada zlib/gzip/deflate |
| `testing/libsodium-ada/` | `libsodium-ada` | Built: thin Ada binding to libsodium (ChaCha20-Poly1305, HMAC-SHA256) |
| `testing/hbnf/` | `hbnf` | Built: OpenBSD-style config parser + `hbnf` schema engine (C/Ada/Rust/Zig parser generators) |
| `testing/imsg/` | `imsg` | New: OpenBSD imsg message-passing protocol in Ada — static, self-referential source; not yet in `build.sh`'s default order |
| `testing/xmlada/` | `xmlada` | Built: XML/Ada |
| `testing/aunit/` | `aunit` | Built: Ada unit testing framework |
| `testing/gnatcoll/` | `gnatcoll` | Built: GNAT Components Collection core (static + shared) |
| `testing/gnatcoll-db/` | `gnatcoll-db` | Built: GNATcoll SQL + SQLite (static) |
| `testing/gnatcoll-gmp/` | `gnatcoll-gmp` | Built: GMP (arbitrary precision) bindings (static + shared) |
| `testing/gnatcoll-iconv/` | `gnatcoll-iconv` | Built: iconv charset-conversion bindings (static + shared) |
| `testing/spawn/` | `spawn` | Built: process-spawning library (static) |
| `testing/vss/` | `vss` | Built: vector/string abstractions (static + shared) |
| `testing/aws/` | `aws` | Built: Ada Web Server (+ templates-parser, static) |
| `testing/adasat/` | `adasat` | Built: SAT-solving library (static + shared) |
| `testing/py3-e3-core/` | `py3-e3-core` | Built: E3 core Python tooling |
| `testing/py3-e3-testsuite/` | `py3-e3-testsuite` | Built: E3 testsuite framework (driver for AdaCore test suites) |
| `testing/prettier-ada/` | `prettier-ada` | Built: Prettier formatter core (static + shared) |
| `testing/py3-langkit/` | `py3-langkit` | Built: Langkit Python parser framework |
| `testing/langkit/` | `langkit` | Built: parser framework (static + shared) + lkt tools |
| `testing/gpr/` | `gpr` | Built: GPR2 project parser library (static) |
| `testing/gpr2-tools/` | `gpr2-tools` | Built: next-gen GPR tools (gprbuild, gprclean, …) — replaces gprbuild |
| `testing/libgpr/` | `libgpr` | Built: gprbuild's project parser library (static) |
| `testing/gnatcoll-projects/` | `gnatcoll-projects` | Built: GNATcoll project-file support (static) |
| `testing/libadalang/` | `libadalang` | Built: Ada semantic analysis (needs ≥8 GB RAM) + lal_parse/lal_unparse |
| `testing/templates-parser/` | `templates-parser` | Built: AWS templates-parser engine (static; aws builds it in-tree but doesn't install it) |
| `testing/vss-extra/` | `vss-extra` | Built: VSS extras — JSON/Regexp/XML/OS (split out of VSS) |
| `testing/xdiff/` | `xdiff` | Built: Ada bindings for the xdiff diff library (static) |
| `testing/libadalang-tools/` | `libadalang-tools` | Built: gnatpp, gnatmetric, gnatstub + libraries |
| `testing/lal-refactor/` | `lal-refactor` | Built: source-code refactoring library (static) |
| `testing/gnatformat/` | `gnatformat` | Built: source-code formatter library (static) |
| `testing/gnatdoc/` | `gnatdoc` | Built: documentation generation (library + gnatdoc CLI) |
| `testing/fswatch/` | `fswatch` | Built: libfswatch C/C++ library + CLI (static; dep of ada-libfswatch) |
| `testing/ada-libfswatch/` | `ada-libfswatch` | Built: filesystem-change notification bindings |
| `testing/ada-markdown/` | `ada-markdown` | Built: Markdown parser library for Ada (static) |
| `testing/ada_language_server/` | `ada_language_server` | Built: LSP server for Ada (static-linked) |
| `testing/afl++/` | `afl++` | Built: coverage-guided fuzzer (GCC mode) — fixes upstream's broken `clang22-rtlib` dep |

`imsg` is a complete static aport whose source lives in this repo
(`sources/imsg/`, same self-referential tarball trick as `hbnf`), but it is not
yet wired into `build.sh`'s default `PKGS` order.

The full set builds with `./build.sh` (`libadalang` needs ≥8 GB RAM for its
generated parser). `langkit`'s `check()` runs its upstream e3-testsuite on the
LKT subset (114 pass). The `ada_language_server` binary links every Ada
dependency statically (only libc/libgnat/libgmp stay dynamic), so the overlay's
end goal is met.

`hbnf` ships a self-contained RFC 5234 schema engine whose four code generators
(C, Ada, Rust, Zig) each emit a recursive-descent parser that reports errors
classic-unix style — `expected a number, found oops` with line/col and a caret
under the offending token.

## Dependency graph

Build-time order (what `./build.sh` follows). `gcc-gnat` is the only Ada
package pulled from Alpine; everything else is built by this overlay.

```
gcc-gnat ──► gprbuild ──┬─► xmlada ──┬─► gnatcoll ──┬─► gnatcoll-db
                        │            │              ├─► gnatcoll-gmp
                        │            │              ├─► gnatcoll-iconv
                        │            │              └─► aws
                        │            └─► libgpr ───► gnatcoll-projects
                        │            └─► templates-parser
                        ├─► aunit
                        ├─► spawn
                        ├─► vss ──► vss-extra
                        ├─► adasat
                        ├─► bracke-cryptolib ──► bracke-zlib
                        ├─► libsodium-ada
                        ├─► hbnf          (self-referential source)
                        └─► imsg          (self-referential source)
```

The langkit / GPR2 spine:

```
gnatcoll + vss ──► prettier-ada
gnatcoll + gnatcoll-gmp/iconv + adasat + prettier-ada ──► langkit
gnatcoll + gnatcoll-gmp/iconv + xmlada ──► gpr            (GPR2 library)
langkit + gpr + gnatcoll-projects ──► libadalang
```

The tool / endpoint layer:

```
libadalang + templates-parser + vss ──► libadalang-tools ──► lal-refactor
libadalang + prettier-ada + vss + vss-extra ──► gnatformat
vss + vss-extra ──► ada-markdown
libadalang + vss/vss-extra + gpr + ada-markdown ──► gnatdoc
gnatcoll + fswatch ──► ada-libfswatch      (fswatch is pure C: build-base/gettext)

gpr + libadalang + libadalang-tools + lal-refactor + gnatdoc + gnatformat
  + spawn + vss + vss-extra + ada-libfswatch + xdiff
      ──► ada_language_server              (the end goal)

gnatcoll + gnatcoll-gmp/iconv + xmlada ──► gpr2-tools   (last — replaces gprbuild)

afl++   (standalone — no Ada; gmp-dev/linux-headers)
```

Python tooling sits off to the side of the langkit spine:

```
py3-e3-core ──► py3-e3-testsuite   (langkit's check() driver)
py3-langkit                         (langkit build dep)
```

## Work in progress

Two packaging items are in flight. Neither blocks the current build.

### Shared libraries

Only the langkit spine currently ships a relocatable (`.so`) variant, because
langkit's ctypes Python bindings load a shared `liblktlang.so` and every Ada
dependency under it must be relocatable too:

    gnatcoll, gnatcoll-gmp, gnatcoll-iconv, vss (gnat + text), adasat,
    prettier-ada, langkit

Everything else builds static-only — `gpr`, `libgpr`, `gnatcoll-projects`,
`libadalang`, `libadalang-tools`, `lal-refactor`, `gnatformat`, `ada-markdown`,
`xdiff`, `gnatcoll-db`, `spawn`, `aws`, `templates-parser`, `fswatch`,
`gnatdoc`, `ada-libfswatch`, `imsg`, `hbnf`, `bracke-cryptolib`, `bracke-zlib`.
The WIP is to build shared variants of these so the stack can be consumed
dynamically as well as pulled into a static binary.

### `-static` split

Alpine's convention is to ship a static archive (`.a`) in a `<name>-static`
subpackage and let the main package carry the shared library. This overlay
currently puts the static artifacts straight into the main package, because the
whole tree exists to construct a statically-linked `ada_language_server`.

The WIP is to move each library's static archive into a `-static` subpackage
(`gpr-static`, `libadalang-static`, …) once the shared variant builds, so the
layout converges on Alpine's normal `libfoo` / `libfoo-static` / `libfoo-dev`
shape for the MR.

## Why bootstrap gprbuild

gprbuild is built with upstream's `bootstrap.sh`, which compiles gprbuild plus
the XML/Ada sources with `gnatmake` and ships the gprconfig knowledge base. It
does not link a separately-built xmlada, so there is no gprbuild <-> xmlada
build cycle. A future gcc soname bump (`libgnat-15.so` -> `libgnat-16.so`) is
then an ordinary pkgrel rebuild in order; nothing needs an old gprbuild to
build a new one.

## License

- GPL-3.0-or-later: gprbuild, libgpr, fswatch, ada_language_server, gpr2-tools.
- GPL-3.0-or-later WITH GCC-exception-3.1: xmlada, aunit, gnatcoll,
  gnatcoll-db, gnatcoll-gmp, gnatcoll-iconv, gnatcoll-projects, gnatdoc,
  libadalang-tools, spawn, templates-parser, ada-libfswatch, aws.
- Apache-2.0 WITH LLVM-exception: prettier-ada, langkit, py3-langkit, gpr,
  libadalang, ada-markdown, vss, vss-extra, gnatformat, lal-refactor.
- Apache-2.0: adasat.
- MIT: bracke-cryptolib, bracke-zlib.
- ISC: libsodium-ada, hbnf, imsg.
- GPL-3.0: xdiff.
- GPL-3.0-only: py3-e3-core, py3-e3-testsuite.
- AGPL-3.0-or-later AND Apache-2.0: afl++.

None imposes a license on software built with or linked against it.

## Build

    ./build.sh            # builds the .apk files in an alpine:edge container
