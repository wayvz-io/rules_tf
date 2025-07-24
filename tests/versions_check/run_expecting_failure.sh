#!/usr/bin/env bash
# Test runner that expects a bazel test to fail with specific error
set -euo pipefail

TARGET="$1"
EXPECTED_ERROR="$2"

echo "Running $TARGET (expecting it to fail with: $EXPECTED_ERROR)..."

# Capture both stdout and stderr
OUTPUT=$(bazel test "$TARGET" --test_output=errors 2>&1 || true)

# Check if test failed (it should)
if bazel test "$TARGET" --test_output=errors &>/dev/null; then
    echo "ERROR: Expected $TARGET to fail, but it passed!"
    exit 1
fi

# Check for expected error message
if echo "$OUTPUT" | grep -q "$EXPECTED_ERROR"; then
    echo "✓ Test correctly failed with expected error"
    exit 0
else
    echo "ERROR: Test failed but without expected error message"
    echo "Expected: $EXPECTED_ERROR"
    echo "Got:"
    echo "$OUTPUT" | tail -20
    exit 1
fi