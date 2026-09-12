#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$ASTRA_DIR/.logs"
export ASTRA_DATA_DIR="${ASTRA_TEST_DATA_DIR:-$ASTRA_DIR/.testdata/diagnostics}"

run_suite() {
  local script="$1"
  local label="$2"
  shift 2
  local output
  set +e
  output="$("$SCRIPT_DIR/godot.sh" --headless --log-file "$ASTRA_DIR/.logs/$label.log" --path "$ASTRA_DIR" --script "$script" "$@" 2>&1)"
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ $status -ne 0 ]] || printf '%s\n' "$output" | grep -q 'SCRIPT ERROR'; then
    return 1
  fi
}

run_suite res://tests/run.gd tests "$@"
run_suite res://tests/ui_test.gd ui-tests "$@"
