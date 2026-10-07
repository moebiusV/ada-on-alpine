#!/bin/sh
# CI smoke test, run inside a clean alpine:edge container with the freshly built
# packages mounted at /pkgs: install them all in one solve, build and run an Ada
# program, and check that each tool that was built for this architecture runs.
set -eu

apk add --no-cache --allow-untrusted gcc-gnat musl-dev gmp /pkgs/*.apk
echo "arch: $(apk --print-arch)"

mkdir /w && cd /w
printf 'project Hello is\n   for Main use ("hello.adb");\nend Hello;\n' > hello.gpr
printf 'with Ada.Text_IO;\nprocedure Hello is\nbegin\n   Ada.Text_IO.Put_Line ("ok");\nend Hello;\n' > hello.adb
gprbuild -q -P hello.gpr
[ "$(./hello)" = ok ]
echo "hello: ok"

# Each installed tool must run.  (gnatdoc's --version exits 1, so use --help;
# gnatformat ships as a library only, with no executable.)
for t in ada_language_server gnatpp gnatmetric gnatstub gnatdoc; do
	if command -v "$t" >/dev/null 2>&1; then
		case $t in gnatdoc) flag=--help ;; *) flag=--version ;; esac
		"$t" $flag >/dev/null 2>&1 && echo "$t: ok" || { echo "$t: FAILED" >&2; exit 1; }
	else
		echo "$t: not built for this architecture"
	fi
done
