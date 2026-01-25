#!/bin/bash
# EmmyLua type checker script using lua-language-server
# Usage: ./scripts/typecheck.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDON_DIR="$PROJECT_ROOT/BattleScrolls"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== EmmyLua Type Checker ===${NC}"
echo "Project root: $PROJECT_ROOT"
echo "Addon directory: $ADDON_DIR"
echo ""

# Check if lua-language-server is installed
if ! command -v lua-language-server &> /dev/null; then
    echo -e "${RED}Error: lua-language-server is not installed${NC}"
    echo "Install it with: brew install lua-language-server"
    exit 1
fi

# Create a temporary directory for the check results
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/check.json"

echo -e "${BLUE}Running type checker...${NC}"

# Run lua-language-server in check mode from project root (for relative library paths)
cd "$PROJECT_ROOT"
lua-language-server --check "$ADDON_DIR" \
    --configpath "$PROJECT_ROOT/.luarc.json" \
    --logpath "$TEMP_DIR" \
    --checklevel "Warning" \
    --check_format "json" \
    2>&1 | tee "$TEMP_DIR/output.txt"

# Check for the results file
if [ -f "$TEMP_DIR/check.json" ]; then
    echo ""
    echo -e "${BLUE}=== Diagnostic Results ===${NC}"

    # Count errors and warnings (handle both "severity":1 and "severity": 1 formats)
    ERROR_COUNT=$(grep -oE '"severity":\s*1' "$TEMP_DIR/check.json" | wc -l | tr -d ' ')
    WARNING_COUNT=$(grep -oE '"severity":\s*2' "$TEMP_DIR/check.json" | wc -l | tr -d ' ')
    INFO_COUNT=$(grep -oE '"severity":\s*3' "$TEMP_DIR/check.json" | wc -l | tr -d ' ')

    echo -e "${RED}Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    echo -e "${BLUE}Info: $INFO_COUNT${NC}"

    # Pretty print the JSON if jq is available
    if command -v jq &> /dev/null; then
        echo ""
        echo -e "${BLUE}=== Detailed Diagnostics ===${NC}"
        cat "$TEMP_DIR/check.json" | jq -r '
            to_entries[] |
            .key as $file |
            .value[] |
            "\($file):\(.range.start.line + 1):\(.range.start.character + 1): \(if .severity == 1 then "ERROR" elif .severity == 2 then "WARNING" else "INFO" end): \(.message)"
        ' 2>/dev/null || cat "$TEMP_DIR/check.json"
    else
        cat "$TEMP_DIR/check.json"
    fi

    # Exit with error code if there are errors
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo ""
        echo -e "${RED}Type checking failed with $ERROR_COUNT error(s)${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    elif [ "$WARNING_COUNT" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Type checking passed with $WARNING_COUNT warning(s)${NC}"
    else
        echo ""
        echo -e "${GREEN}Type checking passed with no issues!${NC}"
    fi
else
    echo -e "${GREEN}No diagnostics found - code looks clean!${NC}"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}Done!${NC}"
