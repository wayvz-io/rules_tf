#!/usr/bin/env bash
# Test that verifies a versions_check test passes
set -euo pipefail

TARGET="$1"

echo "Testing that $TARGET passes..."
if bazel test "$TARGET" --test_output=errors; then
    echo "✓ Test passed as expected"
    exit 0
else
    echo "✗ Test failed unexpectedly"
    exit 1
fi