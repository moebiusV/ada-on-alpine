# ada-on-alpine

Alpine `aports` overlay for the Ada/GNAT build toolchain, targeting **edge**
(gcc 15). Layout mirrors `aports`, so each package copies straight into an
aports fork for a Merge Request.

## Packages

| Path | Package | Status |
| --- | --- | --- |
| `testing/gprbuild/` | `gprbuild` | Upgrade of the existing aport (maintainer Ian Douglas Scott) to 26.0.0 |
| `testing/xmlada/` | `xmlada` | New aport: XML/Ada |
| `testing/aunit/` | `aunit` | New aport: Ada unit testing framework |
| `testing/gnatcoll/` | `gnatcoll` | New aport: GNAT Components Collection core (static + shared) |
| `testing/gnatcoll-db/` | `gnatcoll-db` | New aport: GNATcoll SQL + SQLite |
| `testing/gnatcoll-gmp/` | `gnatcoll-gmp` | New aport: GMP (arbitrary precision) bindings (static + shared) |
| `testing/gnatcoll-iconv/` | `gnatcoll-iconv` | New aport: iconv charset-conversion bindings (static + shared) |
| `testing/spawn/` | `spawn` | New aport: process-spawning library |
| `testing/vss/` | `vss` | New aport: vector/string abstractions (static + shared) |
| `testing/aws/` | `aws` | New aport: Ada Web Server (+ templates-parser) |
| `testing/adasat/` | `adasat` | New aport: SAT-solving library (static + shared) |
| `testing/py3-e3-core/` | `py3-e3-core` | New aport: E3 core Python tooling |
| `testing/prettier-ada/` | `prettier-ada` | New aport: Prettier formatter core (static + shared) |
| `testing/py3-langkit/` | `py3-langkit` | New aport: Langkit Python parser framework |
| `testing/langkit/` | `langkit` | New: parser framework (static + shared) |
| `testing/gpr/` | `gpr` | New: GPR2 project parser library (static) |
| `testing/libgpr/` | `libgpr` | New: gprbuild's project parser library (static) |
| `testing/gnatcoll-projects/` | `gnatcoll-projects` | New: GNATcoll project-file support (static) |
| `testing/libadalang/` | `libadalang` | Built: Ada semantic analysis (needs ≥8 GB RAM to compile) |
| `testing/templates-parser/` | `templates-parser` | New: AWS templates-parser engine (aws builds it in-tree but doesn't install it) |
| `testing/vss-extra/` | `vss-extra` | New: VSS extras — JSON/Regexp/XML/OS (split out of VSS) |
| `testing/xdiff/` | `xdiff` | New: Ada bindings for the xdiff diff library |
| `testing/libadalang-tools/` | `libadalang-tools` | New: Libadalang tools library (renamer, formatting support) |
| `testing/lal-refactor/` | `lal-refactor` | New: source-code refactoring library |
| `testing/gnatformat/` | `gnatformat` | New: source-code formatter library |
| `testing/gnatdoc/` | `gnatdoc` | New: documentation-generation library |
| `testing/fswatch/` | `fswatch` | New: libfswatch C/C++ library + CLI (dep of ada-libfswatch) |
| `testing/ada-libfswatch/` | `ada-libfswatch` | New: filesystem-change notification bindings |
| `testing/markdown/` | `markdown` | New: Markdown parser library (only the gnatdoc CLI tool needs it) |
| `testing/ada_language_server/` | `ada_language_server` | Built: LSP server for Ada (static-linked) |

All 29 packages — `gprbuild` through `ada_language_server` — build with
`./build.sh` (`libadalang` needs ≥8 GB RAM for its generated parser). The
`ada_language_server` binary links every Ada dependency statically (only
libc/libgnat/libgmp stay dynamic), so the overlay's end goal is met.

## Why bootstrap gprbuild

gprbuild is built with upstream's `bootstrap.sh`, which compiles gprbuild plus
the XML/Ada sources with `gnatmake` and ships the gprconfig knowledge base. It
does not link a separately-built xmlada, so there is no gprbuild <-> xmlada
build cycle. Dependency order is a straight line:

    gcc-gnat -> gprbuild -> xmlada -> gnatcoll -> gnatcoll-db
                        \-> aunit     \-> aws

A future gcc soname bump (`libgnat-15.so` -> `libgnat-16.so`) is then an
ordinary pkgrel rebuild in order; nothing needs an old gprbuild to build a new
one.

## License

gprbuild, libgpr, fswatch and ada_language_server are GPL-3.0-or-later. Most
libraries (xmlada, aunit, gnatcoll, gnatcoll-db, gnatcoll-gmp, gnatcoll-iconv,
spawn, aws, templates-parser, libadalang-tools, gnatdoc, ada-libfswatch) are
GPL-3.0-or-later WITH the GCC Runtime Library Exception (GCC-exception-3.1).
langkit, prettier-ada, markdown, vss, vss-extra, gnatformat and lal-refactor are
Apache-2.0 WITH LLVM-exception; adasat is Apache-2.0; xdiff is GPL-3.0. None
imposes a license on software built with or linked against it.

## Build

    ./build.sh            # builds the .apk files in an alpine:edge container
