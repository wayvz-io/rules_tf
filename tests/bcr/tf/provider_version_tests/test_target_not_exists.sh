#!/usr/bin/env bash
# Test that verifies a target does not exist
set -euo pipefail

TARGET="$1"

echo "Testing that $TARGET does not exist..."
if bazel query "$TARGET" 2>/dev/null; then
    echo "✗ Target exists but should not!"
    exit 1
else
    echo "✓ Target correctly does not exist"
    exit 0
fi