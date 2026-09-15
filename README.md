# ada-on-alpine

Alpine `aports` overlay for the Ada/GNAT build toolchain, targeting **edge**
(gcc 15). Layout mirrors `aports`, so each package copies straight into an
aports fork for a Merge Request.

## Packages

| Path | Package | Status |
| --- | --- | --- |
| `testing/gprbuild/` | `gprbuild` | Upgrade of the existing aport (maintainer Ian Douglas Scott) to 26.0.0 |
| `testing/xmlada/` | `xmlada` | New aport: XML/Ada (no aport exists yet) |

## Why bootstrap gprbuild

gprbuild is built with upstream's `bootstrap.sh`, which compiles gprbuild plus
the XML/Ada sources with `gnatmake` and ships the gprconfig knowledge base. It
does not link a separately-built xmlada, so there is no gprbuild <-> xmlada
build cycle. Dependency order is a straight line:

    gcc-gnat -> gprbuild -> xmlada

A future gcc soname bump (`libgnat-15.so` -> `libgnat-16.so`) is then an
ordinary pkgrel rebuild in order; nothing needs an old gprbuild to build a new
one.

## License

gprbuild is GPL-3.0-or-later. xmlada is GPL-3.0-or-later WITH the GCC Runtime
Library Exception (GCC-exception-3.1). Neither imposes a license on software
built with or linked against it.

## Build

    ./build.sh            # builds both .apk files in an alpine:edge container
