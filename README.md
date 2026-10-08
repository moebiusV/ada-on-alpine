# ada-on-alpine

Modern Ada projects build with gprbuild. Packaging it for Alpine showed that
much of the rest of a common Ada development environment was also missing:
the GNATcoll libraries, XML/Ada, AUnit, the Ada Web Server, Libadalang and its
tools, and the language server. Their dependencies were slow to work out; this
repository records the result as a set of packages that build in dependency
order, pass their checks on x86_64, and install cleanly on Alpine **edge**
(gcc 15). The
intent is to add the toolchain packages to Alpine's `main` or `community`
repository.

Separately, security work produced Ada packages for a number of security-related
libraries (cryptography, libsodium, zlib, imsg) and a few tools of my own. They
are listed apart from the toolchain.

It is distributed as a signed `apk` repository and as an `aports` overlay. The
overlay mirrors the `aports` layout, so each package copies into an aports fork
unchanged, and the same package definitions back the published repository and
the upstream proposals.

## Use as an Alpine repository

The overlay is published as a signed `apk` repository (x86_64 / musl, Alpine
**edge**):

    wget -O /etc/apk/keys/ada-on-alpine.rsa.pub \
      https://moebiusv.github.io/ada-on-alpine/ada-on-alpine.rsa.pub
    echo "https://moebiusv.github.io/ada-on-alpine" >> /etc/apk/repositories
    apk update
    apk add gprbuild aunit aws gnatcoll libadalang ada_language_server ...

The repository carries only the packages this overlay builds; base
dependencies (`gcc-gnat`, `musl-dev`, `sqlite`, `libsodium`, …) resolve from
Alpine's own `edge/main` and `edge/community`, which must also be present.
Everything is signed with the `ada-on-alpine` key, and `apk` verifies both the
repository index and every package against it.

## Packages

40 source packages, all into aports `testing/`, plus three `pyc` subpackages,
20 `-static` subpackages, and two `-doc` subpackages.

### Toolchain

The Ada toolchain itself: compiler support, build system, libraries, code
tooling and the language server. This is the set proposed for Alpine.

| Package | Status |
| --- | --- |
| `gprbuild` | Built: upgrade of the existing aport (maintainer Ian Douglas Scott) to 26.0.0 |
| `xmlada` | Built: XML/Ada (static + shared) |
| `aunit` | Built: Ada unit testing framework (static + shared) |
| `gnatcoll` | Built: GNAT Components Collection core (static + shared) |
| `gnatcoll-db` | Built: GNATcoll SQL + SQLite (static + shared) |
| `gnatcoll-gmp` | Built: GMP (arbitrary precision) bindings (static + shared) |
| `gnatcoll-iconv` | Built: iconv charset-conversion bindings (static + shared) |
| `spawn` | Built: process-spawning library (static + shared) |
| `vss` | Built: vector/string abstractions (static + shared) |
| `aws` | Built: Ada Web Server (+ templates-parser, static + shared) |
| `adasat` | Built: SAT-solving library (static + shared) |
| `py3-e3-core` | Built: E3 core Python tooling |
| `py3-e3-testsuite` | Built: E3 testsuite framework (driver for AdaCore test suites) |
| `prettier-ada` | Built: Prettier formatter core (static + shared) |
| `py3-langkit` | Built: Langkit Python parser framework |
| `langkit` | Built: parser framework (static + shared) + lkt tools |
| `gpr` | Built: GPR2 project parser library (static) |
| `gpr2-tools` | **WIP, disabled** (`arch=""`): next-gen GPR tools, installed as `gprbuild2`, … alongside classic gprbuild; `gprbuild2` crashes on library projects |
| `libgpr` | Built: gprbuild's project parser library (static + shared) |
| `gnatcoll-projects` | Built: GNATcoll project-file support (static + shared) |
| `libadalang` | Built: Ada semantic analysis (needs ≥8 GB RAM) + lal_parse/lal_unparse |
| `templates-parser` | Built: AWS templates-parser engine (static + shared; aws builds it in-tree but doesn't install it) |
| `vss-extra` | Built: VSS extras — JSON/Regexp/XML/OS (split out of VSS) |
| `xdiff` | Built: Ada bindings for the xdiff diff library (static + shared) |
| `libadalang-tools` | Built: gnatpp, gnatmetric, gnatstub + libraries |
| `lal-refactor` | Built: source-code refactoring library (static) |
| `gnatformat` | Built: source-code formatter library (static) |
| `gnatdoc` | Built: documentation generation (library + gnatdoc CLI) |
| `fswatch` | Built: libfswatch C/C++ library + CLI (static; dep of ada-libfswatch) |
| `ada-libfswatch` | Built: filesystem-change notification bindings (static) |
| `ada-markdown` | Built: Markdown parser library for Ada (static) |
| `ada_language_server` | Built: LSP server for Ada (static-linked) |

All packages build with `./build.sh` (`libadalang` needs ≥8 GB RAM for its
generated parser). `langkit`'s `check()` runs its upstream e3-testsuite on the
LKT subset (114 pass). The `ada_language_server` binary links every Ada
dependency statically (only libc, libgnat/libgnarl, libgcc and libgmp stay
dynamic), so editor integration works out of the box.

### Add-ons

Optional extras (cryptography, security and fuzzing). Nothing
in the toolchain depends on them.

| Package | Status |
| --- | --- |
| `bracke-cryptolib` | Built: pure-Ada cryptography (checksums, ciphers, MACs) (static + shared) |
| `bracke-zlib` | Built: pure-Ada zlib/gzip/deflate (static + shared) |
| `libsodium-ada` | Built: complete thin Ada binding to libsodium (hashes, HMAC, AEAD, signatures, password hashing, secure memory) (static + shared) |
| `afl++` | Built: coverage-guided fuzzer (GCC mode) — fixes upstream's broken `clang22-rtlib` dep |

### Personal projects

My own tools and libraries. `mustache-ada` is used by `hbnf` and `buildabook`.

| Package | Status |
| --- | --- |
| `mustache-ada` | Built: complete Mustache template engine, passes the official spec suite (static + shared) |
| `imsg-ada` | Built: OpenBSD imsg message-passing protocol in Ada, the protocol used for privilege-separation (privsep) security (static + shared) |
| `hbnf` | Built: ABNF-style parser generator / compiler compiler (C/Ada/Rust/Zig backends) — first use case obconf (OpenBSD-style server configuration) |
| `buildabook` | Built: build tool for long manuscripts (outline + chapter sources → a Typst book) |

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
                        ├─► mustache-ada ──► hbnf ──► buildabook
                        └─► imsg-ada
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
      ──► ada_language_server              (editor integration)

gnatcoll + gnatcoll-gmp/iconv + xmlada ──► gpr2-tools   (WIP, disabled; not in the default build)

afl++   (standalone — no Ada; gmp-dev/linux-headers)
```

Python tooling sits off to the side of the langkit spine:

```
py3-e3-core ──► py3-e3-testsuite   (langkit's check() driver)
py3-langkit                         (langkit build dep)
```

## Library layout

Alpine's convention is a shared package (`libfoo.so` + project files) plus a
`libfoo-static` subpackage carrying the `.a` archive. The overlay follows
that shape: 20 libraries build `static + shared` and ship their archive in a
`<name>-static` subpackage —

    adasat, aws, bracke-cryptolib, bracke-zlib, gnatcoll, gnatcoll-db,
    gnatcoll-gmp, gnatcoll-iconv, gnatcoll-projects, imsg-ada, langkit, libgpr,
    libsodium-ada, mustache-ada, prettier-ada, spawn, templates-parser, vss,
    xdiff, xmlada

Consumers that link statically declare the matching `-static` package in their
`makedepends`; everyone else links the shared library. Shared variants are
required under the langkit spine: langkit's ctypes Python bindings load a
shared `liblktlang.so`, so every Ada dependency beneath it must be relocatable.

The rest stay static-only because they exist to be pulled into one static
binary — `gpr` (GPR2), `libadalang` (links `langkit_support`),
`libadalang-tools`, `lal-refactor`, `gnatformat`, `gnatdoc`, `ada-markdown`,
`vss-extra`, `ada-libfswatch`, and the C `fswatch` — plus the statically-linked
`ada_language_server` (and `gpr2-tools`, once enabled). `aunit` ships
`static + shared` in one package, from upstream's `make all`.

## Why bootstrap gprbuild

gprbuild is built with upstream's `bootstrap.sh`, which compiles gprbuild plus
the XML/Ada sources with `gnatmake` and ships the gprconfig knowledge base. It
does not link a separately-built xmlada, so there is no gprbuild <-> xmlada
build cycle. A gcc soname bump (`libgnat-15.so` -> `libgnat-16.so`) is
an ordinary pkgrel rebuild in order; nothing needs an old gprbuild to build a
new one.

`gpr2-tools`, the GPR2-based `gprbuild`/`gprclean`/`gprconfig`/`gprinstall`, is
AdaCore's next-generation replacement, not a full drop-in: `gprname` has no
GPR2 equivalent, and it lacks classic gprbuild's `gprlib`/`gprbind` and
knowledge base. `gprbuild2` crashes on library projects, so the aport is
disabled (`arch=""`). Its tools install under a `2` suffix (`gprbuild2`,
`gprclean2`, `gprconfig2`, `gprinstall2`, `gprls2`) and coexist with classic
`gprbuild`, which it neither replaces nor provides.

## License

- GPL-3.0-or-later: gprbuild, libgpr, fswatch, ada_language_server, gpr2-tools.
- GPL-3.0-or-later WITH GCC-exception-3.1: xmlada, aunit, gnatcoll,
  gnatcoll-db, gnatcoll-gmp, gnatcoll-iconv, gnatcoll-projects, gnatdoc,
  libadalang-tools, spawn, templates-parser, ada-libfswatch, aws.
- Apache-2.0 WITH LLVM-exception: prettier-ada, langkit, py3-langkit, gpr,
  libadalang, ada-markdown, vss, vss-extra, gnatformat, lal-refactor.
- Apache-2.0: adasat.
- MIT: bracke-cryptolib, bracke-zlib.
- ISC: libsodium-ada, mustache-ada, hbnf, imsg-ada, buildabook.
- GPL-3.0: xdiff.
- GPL-3.0-only: py3-e3-core, py3-e3-testsuite.
- AGPL-3.0-or-later AND Apache-2.0: afl++.

None imposes a license on software built with or linked against it.

## Releasing an upstream package

The four upstream packages — `hbnf`, `libsodium-ada`, `imsg-ada`,
`mustache-ada` — are released by tagging their repo and updating this overlay's
APKBUILD. `tools/release-checksum.sh` automates the tag-tarball checksum dance:
fetch the pushed tag's tarball, hash it, and rewrite `pkgver` + `sha512sums`
(see `tools/release-checksum.1`):

    ./tools/release-checksum.sh mustache-ada v0.3.0                 # dry run: show the diff
    ./tools/release-checksum.sh mustache-ada v0.3.0 --commit --push # commit and push the bump

The rewrite is done by `tools/apkbuild_bump`, a small Ada program that
validates the version and hash and handles both the single- and multi-line
`sha512sums` forms. Never move a pushed tag.

## Building

Clone and build the overlay from source:

    git clone https://github.com/moebiusV/ada-on-alpine.git
    cd ada-on-alpine
    ./build.sh

`./build.sh` needs Docker (`./install-docker.sh` sets it up on Debian). It
builds every package in dependency order inside an `alpine:edge` container with
`abuild`, producing signed `.apk` files under `.work/packages/`. The signing key
is generated once into `~/.config/abuild/` and reused, so every checkout of the
repo signs with the same key.

The build is incremental per package: `build.sh` hashes each aport's directory
(the `APKBUILD` and its patches) and skips any package whose hash matches its
last build. Re-running it therefore rebuilds only what changed — a bumped
upstream commit (`_commit`/`pkgver` in the `APKBUILD`), an edited patch, or a
new package — and reuses everything else from `.work/packages/`.

The same `.apk` files assemble into a Docker image for building Ada against:

    ./build-image.sh       # ada-toolchain:edge — alpine + the whole toolchain

CI (`.github/workflows/install-test.yml`) does not use an image: it starts from
plain `alpine:edge`, adds the published repo as shown above, installs the
toolchain and smoke-tests it, so it checks what users actually install.

`.github/workflows/ci.yml` builds and tests every aport, but only for x86_64 by
default: the freshly built `gprbuild` does not work on the other
architectures. Enable one with `[ci only: aarch64]` in the commit message (or all
with `[ci only: all]`).

### Adding a package

`testing/hbnf/` is the reference Ada aport. A package is a
directory under `testing/` holding an `APKBUILD` (plus any `.patch` files named
in its `source=`). The pieces, as hbnf does them:

- `pkgname`/`pkgver`/`pkgrel`, `pkgdesc`, `url`, `arch="all"`, `license`.
- `depends=` for runtime libraries and `makedepends=` for the build tools
  (`gcc-gnat gprbuild build-base` plus the library build-deps).
- `source=` — a pinned tag tarball (or an `_commit=` archive) with `sha512sums=`.
- `build()` runs `gprbuild -P … -p`, with `-XLIBRARY_TYPE=static` for a static
  library.
- `check()` builds and runs the upstream test suite; hbnf runs its conformance
  drivers over the accept/reject corpus.
- `package()` installs the library with `gprinstall --prefix="$pkgdir/usr"` and,
  for a tool, the binary with `install -Dm755` into `$pkgdir/usr/bin`.

Shared libraries follow Alpine's `<name>-static` subpackage convention (see
*Library layout* above); static-only libraries ship sources, a static `.a`, and
a `.gpr` project.

New Ada packages — and contributions to the existing ones — follow the canonical
Ada functional style guide at <https://moebiusv.github.io/ada-style-guidelines.html>.
Each Ada repo carries a `STYLE.md` that points at it.
