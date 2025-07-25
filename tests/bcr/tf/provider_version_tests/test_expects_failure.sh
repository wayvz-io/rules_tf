#!/usr/bin/env bash
# Test wrapper that expects the inner test to fail with a specific error
set -euo pipefail

# The target is provided as a test dependency, not as an argument
# This allows us to run the test in the same Bazel invocation
TEST_BINARY="$1"
EXPECTED_ERROR="$2"

echo "Running test that's expected to fail..."

# Run the test and capture output
if OUTPUT=$("$TEST_BINARY" 2>&1); then
    echo "ERROR: Expected test to fail, but it passed!"
    exit 1
fi

# Check for expected error message
if echo "$OUTPUT" | grep -q "$EXPECTED_ERROR"; then
    echo "✓ Test correctly failed with expected error: $EXPECTED_ERROR"
    exit 0
else
    echo "ERROR: Test failed but without expected error message"
    echo "Expected: $EXPECTED_ERROR"
    echo "Got:"
    echo "$OUTPUT"
    exit 1
fi