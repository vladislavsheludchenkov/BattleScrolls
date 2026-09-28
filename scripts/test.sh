#!/bin/bash
# Runs the offline test suite (tests/*_test.lua) on plain Lua.
# Requires a Lua 5.3+ interpreter (brew install lua).

set -u

BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

cd "$(dirname "$0")/.."

LUA="$(command -v lua || command -v lua5.4 || command -v lua5.3 || true)"
if [ -z "$LUA" ]; then
    echo -e "${RED}No Lua interpreter found. Install one with: brew install lua${NC}"
    exit 1
fi

for dependency in \
    esoui/esoui/libraries/utility/baseobject.lua \
    esoui/esoui/libraries/zo_parametricscrolllist/zo_parametricscrolllist.lua \
    LibGroupBroadcast/protocol/Protocol.lua; do
    if [ ! -f "$dependency" ]; then
        echo -e "${RED}Missing test dependency: $dependency${NC}" >&2
        echo "Set up the ESO UI and LibGroupBroadcast sources described in CONTRIBUTING.md." >&2
        exit 1
    fi
done

echo -e "${BLUE}=== Offline Test Suite ($("$LUA" -v 2>&1 | head -1)) ===${NC}"
"$LUA" tests/run.lua tests/*_test.lua
