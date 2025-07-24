"""Test infrastructure for validating versions_check behavior."""

def _versions_check_failure_test_impl(ctx):
    """Test that verifies a versions_check test fails with expected error."""
    
    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    
    # Script that runs the target test and verifies it fails with expected error
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Run the versions_check test and capture output
echo "Running {target}_check test (expecting it to fail)..."
OUTPUT=$(bazel test {target}_check --test_output=errors 2>&1 || true)

# Check if the test failed (it should)
if bazel test {target}_check --test_output=errors >/dev/null 2>&1; then
    echo "ERROR: Expected {target}_check to fail, but it passed!"
    exit 1
fi

# Check if the expected error message is in the output
if echo "$OUTPUT" | grep -q "{expected_error}"; then
    echo "✓ Test correctly failed with expected error: '{expected_error}'"
    exit 0
else
    echo "ERROR: Test failed but without the expected error message"
    echo "Expected to find: '{expected_error}'"
    echo "Actual output:"
    echo "$OUTPUT"
    exit 1
fi
""".format(
        target = ctx.attr.target.label,
        expected_error = ctx.attr.expected_error,
    )
    
    ctx.actions.write(
        output = test_script,
        content = script_content,
        is_executable = True,
    )
    
    return [DefaultInfo(executable = test_script)]

versions_check_failure_test = rule(
    implementation = _versions_check_failure_test_impl,
    attrs = {
        "target": attr.label(
            doc = "The tf_module target whose versions_check should fail",
            mandatory = True,
        ),
        "expected_error": attr.string(
            doc = "Expected error message substring",
            mandatory = True,
        ),
    },
    test = True,
)