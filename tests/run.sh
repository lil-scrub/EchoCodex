#!/usr/bin/env bash
# Run the Echo Codex test suite.
#
# Uses Lua 5.1 to match the 3.3.5 client. Falls back to whatever `lua` is on
# PATH, which still runs the tests but won't catch 5.1-only syntax issues
# (a newer Lua accepts constructs the client would reject).
set -e
cd "$(dirname "$0")"

LUA=$(command -v lua5.1 || command -v lua)
LUAC=$(command -v luac5.1 || command -v luac)
echo "Using $LUA / $LUAC"

echo "--- syntax check (Lua 5.1 dialect) ---"
# Every .lua in the addon, including subdirectories, plus the tests
# themselves. -not -path excludes nothing today but keeps this correct if a
# build/vendor directory ever appears.
while IFS= read -r f; do
  "$LUAC" -p "$f" && echo "  ok  ${f#../}"
done < <(find .. -name '*.lua' -not -path '*/.git/*' | sort)

echo "--- .toc manifest ---"
# Catches the failure mode where a file is renamed or moved but the .toc
# still points at the old path: in game that is a silent partial load.
missing=0
while IFS= read -r entry; do
  path="../${entry//\\//}"
  if [ ! -f "$path" ]; then echo "  MISSING: $entry"; missing=1; else echo "  ok  $entry"; fi
done < <(grep -E '^[^#[:space:]].*\.lua[[:space:]]*$' ../EchoCodex.toc | tr -d '\r')
[ "$missing" -eq 0 ] || { echo "ERROR: .toc references files that do not exist"; exit 1; }

echo "--- test suite ---"
exec "$LUA" run.lua
