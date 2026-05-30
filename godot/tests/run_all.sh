#!/usr/bin/env bash
# Run all GDScript tests under godot/tests/*.gd via godot.sh.
# Usage: bash tests/run_all.sh  (from godot/ directory)
# Exit code: total number of failures across all tests (0 = all pass).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_DIR="$(dirname "$SCRIPT_DIR")"
GODOT_SH="$GODOT_DIR/scripts/godot.sh"

total_fails=0
test_count=0
pass_count=0
fail_count=0

echo "=== NNQR GDScript Test Suite ==="

for test_file in "$SCRIPT_DIR"/*_test.gd; do
	test_name="$(basename "$test_file" .gd)"
	test_count=$((test_count + 1))
	# Run test; capture exit code without aborting (set -e is in effect, use || true)
	exit_code=0
	"$GODOT_SH" --headless --path "$GODOT_DIR" -s "res://tests/${test_name}.gd" 2>&1 || exit_code=$?
	if [ "$exit_code" -eq 0 ]; then
		pass_count=$((pass_count + 1))
	else
		fail_count=$((fail_count + 1))
		total_fails=$((total_fails + exit_code))
		echo "FAIL: $test_name (exit $exit_code)"
	fi
done

echo ""
echo "=== Results: $pass_count/$test_count passed, $fail_count failed ==="

exit $total_fails
