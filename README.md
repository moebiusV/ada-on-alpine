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
| `testing/gnatcoll/` | `gnatcoll` | New aport: GNAT Components Collection core |
| `testing/gnatcoll-db/` | `gnatcoll-db` | New aport: GNATcoll SQL + SQLite |
| `testing/spawn/` | `spawn` | New aport: process-spawning library |
| `testing/vss/` | `vss` | New aport: vector/string abstractions |
| `testing/aws/` | `aws` | New aport: Ada Web Server (+ templates-parser) |
| `testing/gpr/` | `gpr` | Scaffold: new-generation project library (blocks on langkit) |
| `testing/langkit/` | `langkit` | Scaffold: parser framework (self-hosting; needs dedicated work) |
| `testing/libadalang/` | `libadalang` | Scaffold: Ada semantic analysis (blocks on langkit + gpr) |
| `testing/ada_language_server/` | `ada_language_server` | Scaffold: LSP server for Ada (blocks on libadalang + gpr) |

The eight packages above the fold build cleanly with `./build.sh`. The four
below are scaffolds — correct metadata and dependency wiring, but their `build()`
needs dedicated work; the whole tier is gated on `langkit`, a self-hosting
parser-generator framework with a Python toolchain.

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

gprbuild is GPL-3.0-or-later. The libraries (xmlada, aunit, gnatcoll,
gnatcoll-db, spawn, vss, aws) are GPL-3.0-or-later WITH the GCC Runtime
Library Exception (GCC-exception-3.1). Neither imposes a license on software
built with or linked against it.

## Build

    ./build.sh            # builds the .apk files in an alpine:edge container
