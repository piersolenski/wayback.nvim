#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

passed=0
failed=0

for test_file in "$SCRIPT_DIR"/test_*.lua; do
    name="$(basename "$test_file")"
    echo "--- Running $name ---"
    if nvim --headless --noplugin -u NONE \
        --cmd "set rtp+=$ROOT_DIR" \
        -l "$test_file" 2>&1; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    echo ""
done

echo "Results: $passed passed, $failed failed"
[ "$failed" -eq 0 ] || exit 1
