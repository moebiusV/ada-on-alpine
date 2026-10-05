#!/bin/sh
# Build a signed apk repository from .work/packages/ and publish it to GitHub
# Pages (the gh-pages branch), so bare-Alpine consumers can `apk add` the
# ada-on-alpine packages over plain HTTPS.
#
# Run ./build.sh first (which also generates the signing key in ~/.config/abuild/).
#
# Why Pages and not Releases: apk always fetches the index from
#   <repo-url>/<arch>/APKINDEX.tar.gz
# (verified: it appends /x86_64/ even to a bare URL).  GitHub Releases serve
# assets flat -- no subdirectories -- so they cannot express that layout.
# Pages serves a real directory tree, and every .apk here is under the 100 MB
# per-file limit.  The repo therefore lives at
#   https://<owner>.github.io/<repo>/x86_64/APKINDEX.tar.gz
#
# Usage:
#   ./publish-repo.sh           build repo/ AND force-push it to gh-pages
#   ./publish-repo.sh --no-push build repo/ only (inspect before publishing)
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
PKGS="$ROOT/.work/packages"
KEYS="$HOME/.config/abuild"
REPO="$ROOT/repo"

[ -d "$PKGS" ] || { echo "error: $PKGS missing; run ./build.sh first" >&2; exit 1; }
KEY=$(ls "$KEYS"/*.rsa 2>/dev/null | head -1) \
  || { echo "error: no signing key in $KEYS; run ./build.sh once to generate it" >&2; exit 1; }
PUB=$(ls "$KEYS"/*.rsa.pub 2>/dev/null | head -1) \
  || { echo "error: no public key in $KEYS" >&2; exit 1; }
PUB_NAME=$(basename "$PUB")

# Build the index in an Alpine container: apk index and abuild-sign are Alpine
# tools, not present on this Debian host.  --rewrite-arch keeps every package
# in the index declaring x86_64, matching the x86_64/ directory apk will look in.
docker run -i --rm -v "$ROOT":/repo -v "$KEYS":/keys -w /repo alpine:edge sh -s <<'SCRIPT'
set -eu
apk add --no-cache alpine-sdk >/dev/null 2>&1
#  Trust the package-signing key so apk index accepts (verifies) the packages;
#  a package signed by anything else fails the build rather than shipping stale.
cp /keys/*.rsa.pub /etc/apk/keys/
rm -rf /repo/repo/x86_64
mkdir -p /repo/repo/x86_64
cp /repo/.work/packages/*.apk /repo/repo/x86_64/
apk index -o /repo/repo/x86_64/APKINDEX.tar.gz --rewrite-arch x86_64 \
	/repo/repo/x86_64/*.apk
KEY=$(ls /keys/*.rsa | head -1)
PUB=$(basename "$(ls /keys/*.rsa.pub | head -1)")
abuild-sign -k "$KEY" -p "$PUB" /repo/repo/x86_64/APKINDEX.tar.gz
SCRIPT

echo "==> repo built under $REPO/x86_64 (index signed with $PUB_NAME)"

if [ "${1:-}" = "--no-push" ]; then
	echo "==> --no-push: leaving $REPO on disk"
	exit 0
fi

# Publish to GitHub Pages: a single commit over main (so the branch is non-orphan
# and reliably listed by GitHub's Pages UI), holding only the apk repo files.  A
# .nojekyll file disables Jekyll — it cannot build a ~462 MB tree of binary .apks
# in the Pages build window — and the README is rendered to index.html locally.
# Each run force-replaces the branch, so no .apk history accumulates.
origin=$(git -C "$ROOT" remote get-url origin)
#  owner/repo for the Pages URL, from either remote spelling
#  (https://github.com/O/R or git@github.com:O/R).  Normalize the SSH form to
#  HTTPS, strip scheme/host and any trailing .git, then split on the slash.
url=$(printf '%s\n' "$origin" | sed -E 's#^git@github.com:#https://github.com/#')
path=$(printf '%s\n' "$url" | sed -E 's#^https?://github.com/##; s#\.git$##')
owner=${path%%/*}
repo_name=${path#*/}
pages_url="https://${owner}.github.io/${repo_name}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

#  Render the README to index.html (Jekyll is off, so Pages will not do it).
python3 "$ROOT"/tools/md2html.py < "$ROOT"/README.md > "$tmp/index.html"

( cd "$tmp" && \
	git init -q && \
	git remote add origin "$origin" && \
	git fetch -q origin main && \
	git checkout -q -b gh-pages FETCH_HEAD && \
	git rm -q -rf . && \
	mkdir -p x86_64 && \
	cp "$REPO"/x86_64/* x86_64/ && \
	cp "$PUB" . && \
	cp "$ROOT"/README.md . && \
	: > .nojekyll && \
	git add -A && \
	git -c user.name=apk-repo -c user.email=apk-repo@users.noreply.github.com \
		commit -q -m "apk repo: $(date -u +%Y-%m-%d)" && \
	git push -q -f origin gh-pages )

echo "==> pushed gh-pages to $origin"
echo
echo "Consumers (on a bare alpine:edge host):"
echo "  wget -O /etc/apk/keys/$PUB_NAME $pages_url/$PUB_NAME"
echo "  echo \"$pages_url\" >> /etc/apk/repositories"
echo "  apk update"
echo "  apk add gprbuild hbnf aunit buildabook ..."
echo
echo "Note: enable GitHub Pages (Settings -> Pages -> Deploy from branch ->"
echo "gh-pages) the first time; the site is $pages_url"
