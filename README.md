# ada-on-alpine

Alpine `aports` overlay for the Ada/GNAT build toolchain, targeting **edge**
(gcc 15). Layout mirrors `aports`, so each package copies straight into an
aports fork for a Merge Request. The end goal is the Ada Language Server
(`ada_language_server`).

## Packages

38 source packages, all into aports `testing/`, plus three `pyc` subpackages
and 19 `-static` subpackages.

| Path | Package | Status |
| --- | --- | --- |
| `testing/gprbuild/` | `gprbuild` | Built: upgrade of the existing aport (maintainer Ian Douglas Scott) to 26.0.0 |
| `testing/bracke-cryptolib/` | `bracke-cryptolib` | Built: pure-Ada cryptography (checksums, ciphers, MACs) (static + shared) |
| `testing/bracke-zlib/` | `bracke-zlib` | Built: pure-Ada zlib/gzip/deflate (static + shared) |
| `testing/libsodium-ada/` | `libsodium-ada` | Built: thin Ada binding to libsodium (ChaCha20-Poly1305, HMAC-SHA256) (static + shared) |
| `testing/hbnf/` | `hbnf` | Built: OpenBSD-style config parser + `hbnf` schema engine (C/Ada/Rust/Zig parser generators) |
| `testing/imsg/` | `imsg` | New: OpenBSD imsg message-passing protocol in Ada — static + shared, self-referential source |
| `testing/xmlada/` | `xmlada` | Built: XML/Ada (static + shared) |
| `testing/aunit/` | `aunit` | Built: Ada unit testing framework (static + shared) |
| `testing/gnatcoll/` | `gnatcoll` | Built: GNAT Components Collection core (static + shared) |
| `testing/gnatcoll-db/` | `gnatcoll-db` | Built: GNATcoll SQL + SQLite (static + shared) |
| `testing/gnatcoll-gmp/` | `gnatcoll-gmp` | Built: GMP (arbitrary precision) bindings (static + shared) |
| `testing/gnatcoll-iconv/` | `gnatcoll-iconv` | Built: iconv charset-conversion bindings (static + shared) |
| `testing/spawn/` | `spawn` | Built: process-spawning library (static + shared) |
| `testing/vss/` | `vss` | Built: vector/string abstractions (static + shared) |
| `testing/aws/` | `aws` | Built: Ada Web Server (+ templates-parser, static + shared) |
| `testing/adasat/` | `adasat` | Built: SAT-solving library (static + shared) |
| `testing/py3-e3-core/` | `py3-e3-core` | Built: E3 core Python tooling |
| `testing/py3-e3-testsuite/` | `py3-e3-testsuite` | Built: E3 testsuite framework (driver for AdaCore test suites) |
| `testing/prettier-ada/` | `prettier-ada` | Built: Prettier formatter core (static + shared) |
| `testing/py3-langkit/` | `py3-langkit` | Built: Langkit Python parser framework |
| `testing/langkit/` | `langkit` | Built: parser framework (static + shared) + lkt tools |
| `testing/gpr/` | `gpr` | Built: GPR2 project parser library (static) |
| `testing/gpr2-tools/` | `gpr2-tools` | Built: next-gen GPR tools (gprbuild, gprclean, …) — replaces gprbuild |
| `testing/libgpr/` | `libgpr` | Built: gprbuild's project parser library (static + shared) |
| `testing/gnatcoll-projects/` | `gnatcoll-projects` | Built: GNATcoll project-file support (static + shared) |
| `testing/libadalang/` | `libadalang` | Built: Ada semantic analysis (needs ≥8 GB RAM) + lal_parse/lal_unparse |
| `testing/templates-parser/` | `templates-parser` | Built: AWS templates-parser engine (static + shared; aws builds it in-tree but doesn't install it) |
| `testing/vss-extra/` | `vss-extra` | Built: VSS extras — JSON/Regexp/XML/OS (split out of VSS) |
| `testing/xdiff/` | `xdiff` | Built: Ada bindings for the xdiff diff library (static + shared) |
| `testing/libadalang-tools/` | `libadalang-tools` | Built: gnatpp, gnatmetric, gnatstub + libraries |
| `testing/lal-refactor/` | `lal-refactor` | Built: source-code refactoring library (static) |
| `testing/gnatformat/` | `gnatformat` | Built: source-code formatter library (static) |
| `testing/gnatdoc/` | `gnatdoc` | Built: documentation generation (library + gnatdoc CLI) |
| `testing/fswatch/` | `fswatch` | Built: libfswatch C/C++ library + CLI (static; dep of ada-libfswatch) |
| `testing/ada-libfswatch/` | `ada-libfswatch` | Built: filesystem-change notification bindings (static) |
| `testing/ada-markdown/` | `ada-markdown` | Built: Markdown parser library for Ada (static) |
| `testing/ada_language_server/` | `ada_language_server` | Built: LSP server for Ada (static-linked) |
| `testing/afl++/` | `afl++` | Built: coverage-guided fuzzer (GCC mode) — fixes upstream's broken `clang22-rtlib` dep |

`imsg` is a complete aport whose source lives in this repo (`sources/imsg/`,
same self-referential tarball trick as `hbnf`).

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

## Library layout

Alpine's convention is a shared package (`libfoo.so` + project files) plus a
`libfoo-static` subpackage carrying the `.a` archive. The overlay now follows
that shape: 19 libraries build `static + shared` and ship their archive in a
`<name>-static` subpackage —

    adasat, aws, bracke-cryptolib, bracke-zlib, gnatcoll, gnatcoll-db,
    gnatcoll-gmp, gnatcoll-iconv, gnatcoll-projects, imsg, langkit, libgpr,
    libsodium-ada, prettier-ada, spawn, templates-parser, vss, xdiff, xmlada

Consumers that link statically declare the matching `-static` package in their
`makedepends`; everyone else links the shared library. Shared variants are
required under the langkit spine: langkit's ctypes Python bindings load a
shared `liblktlang.so`, so every Ada dependency beneath it must be relocatable.

The rest stay static-only because they exist to be pulled into one static
binary — `gpr` (GPR2), `libadalang` (links `langkit_support`),
`libadalang-tools`, `lal-refactor`, `gnatformat`, `gnatdoc`, `ada-markdown`,
`vss-extra`, `ada-libfswatch`, and the C `fswatch` — plus the statically-linked
`ada_language_server` and `gpr2-tools`. (`aunit` ships `static + shared` from
upstream's `make all` and predates the `-static` convention.)

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
