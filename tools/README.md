# Release tools

Automates the checksum dance: updating an aport's `pkgver` and `sha512sums`
when a new tag is pushed to a package's upstream repo. The tarball is fetched
from GitHub, hashed, and the APKBUILD is rewritten — then the change is shown
(and, optionally, committed and pushed).

## release-checksum.sh

```
./tools/release-checksum.sh <pkgname> <tag> [--commit] [--push]
```

1. Fetches `https://github.com/moebiusV/<pkg>/archive/refs/tags/<tag>.tar.gz`.
2. Computes its sha512.
3. Runs `apkbuild_bump` to rewrite the aport's `pkgver` and `sha512sums`.
4. Shows the `git diff`; with `--commit` / `--push`, commits and pushes it.

The rewrite is done by an Ada program, `apkbuild_bump`, because the text edit
is the part that is easy to get wrong by hand: it must update `pkgver` and
repoint `sha512sums` at the new tarball *name*, and handle both the single-line
and multi-line `sha512sums=` forms without corrupting the file.

Example, wired for mustache-ada:

```
./tools/release-checksum.sh mustache-ada v0.3.0                 # dry run: show the diff
./tools/release-checksum.sh mustache-ada v0.3.0 --commit        # commit the bump
./tools/release-checksum.sh mustache-ada v0.3.0 --commit --push # and push
```

The script is generic: it works for any aport under `testing/`, so hbnf,
libsodium-ada and imsg-ada follow the same invocation with their own name.

Prerequisites: `curl`, `sha512sum`, `git`, and `gprbuild` (to build
`apkbuild_bump` on first use — the binary is gitignored, and if it is already
built the script skips the gprbuild step).

## apkbuild_bump

The Ada program that does the rewrite; not usually run by hand:

```
apkbuild_bump <apkbuild> <version> <sha512-hex>
```

It validates the version (`d.d.d`), the hash (128 hex chars), and that the
APKBUILD has `pkgname=`/`pkgver=`/`sha512sums=`, then updates `pkgver` and
`sha512sums`, writing to a `.tmp` file and renaming it into place. It preserves
whichever `sha512sums=` layout (single- or multi-line) the file already uses.
