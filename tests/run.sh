#!/usr/bin/env bash
# Run the Echo Codex test suite.
# Uses Lua 5.1 to match the 3.3.5 client; falls back to whatever `lua` is
# on PATH, which will still run the tests but won't catch 5.1-only syntax.
set -e
cd "$(dirname "$0")"
LUA=$(command -v lua5.1 || command -v lua)
echo "Using $LUA"

echo "--- syntax check (Lua 5.1 dialect) ---"
LUAC=$(command -v luac5.1 || command -v luac)
for f in ../*.lua *.lua; do "$LUAC" -p "$f" && echo "  ok  $f"; done

echo "--- test suite ---"
exec "$LUA" run.lua
