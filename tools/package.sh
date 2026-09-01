#!/usr/bin/env bash
#
# Build a release zip for Echo Codex.
#
#   ./tools/package.sh [output-dir]     (default: ~/Downloads)
#
# The file list comes from EchoCodex.toc, never from a glob -- a glob silently
# drops files when the layout changes (e.g. moving sources into Data/ and
# Tabs/), producing a zip that looks fine but fails to load in game. Anything
# the .toc references is shipped; anything it doesn't is not.
#
# Ships the addon only: no .git, no tests/, no tools/.
set -euo pipefail

cd "$(dirname "$0")/.."
ADDON_DIR="$PWD"
ADDON_NAME="$(basename "$ADDON_DIR")"
OUT_DIR="${1:-$HOME/Downloads}"

TOC="$ADDON_DIR/EchoCodex.toc"
[ -f "$TOC" ] || { echo "ERROR: no EchoCodex.toc in $ADDON_DIR"; exit 1; }

VERSION="$(grep -i '^## Version:' "$TOC" | head -1 | sed 's/^## *[Vv]ersion: *//' | tr -d '\r[:space:]')"
[ -n "$VERSION" ] || { echo "ERROR: no '## Version:' line in the .toc"; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
DEST="$STAGE/$ADDON_NAME"
mkdir -p "$DEST"

# The .toc itself, plus docs that aren't referenced by it.
cp "$TOC" "$DEST/"
[ -f README.txt ] && cp README.txt "$DEST/"

# Every .lua the .toc lists, preserving its subdirectory.
count=0
while IFS= read -r entry; do
  rel="${entry//\\//}"                       # Data\Foo.lua -> Data/Foo.lua
  if [ ! -f "$rel" ]; then
    echo "ERROR: .toc references a missing file: $entry"; exit 1
  fi
  mkdir -p "$DEST/$(dirname "$rel")"
  cp "$rel" "$DEST/$rel"
  count=$((count + 1))
done < <(grep -E '^[^#[:space:]].*\.lua[[:space:]]*$' "$TOC" | tr -d '\r')

mkdir -p "$OUT_DIR"
ZIP="$OUT_DIR/$ADDON_NAME-$VERSION.zip"
rm -f "$ZIP"
( cd "$STAGE" && zip -rq "$ZIP" "$ADDON_NAME" )

echo "Packaged $count Lua files -> $ZIP"
echo
unzip -l "$ZIP" | tail -n +2
