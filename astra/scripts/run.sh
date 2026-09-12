#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$ASTRA_DIR/.logs"
exec "$SCRIPT_DIR/godot.sh" --path "$ASTRA_DIR" --log-file "$ASTRA_DIR/.logs/astra.log" "$@"

