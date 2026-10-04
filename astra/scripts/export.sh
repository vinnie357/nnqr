#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="${1:-}"

case "$TARGET" in
  web)
    PRESET="Web"
    OUTPUT="$ASTRA_DIR/build/web/index.html"
    ;;
  native)
    case "$(uname -s)" in
      Darwin) PRESET="macOS"; OUTPUT="$ASTRA_DIR/build/native/Astra.zip" ;;
      *) printf 'Native export is currently configured for macOS; use the Web target on this host.\n' >&2; exit 2 ;;
    esac
    ;;
  *) printf 'Usage: %s {web|native}\n' "$0" >&2; exit 2 ;;
esac

mkdir -p "$(dirname "$OUTPUT")" "$ASTRA_DIR/.logs"
if ! "$SCRIPT_DIR/godot.sh" --headless --log-file "$ASTRA_DIR/.logs/export.log" --path "$ASTRA_DIR" --export-release "$PRESET" "$OUTPUT"; then
  printf 'Export failed. Install Godot 4.6.3 export templates that match the engine, then retry.\n' >&2
  exit 1
fi
printf 'Exported %s to %s\n' "$TARGET" "$OUTPUT"
