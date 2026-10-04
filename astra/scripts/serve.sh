#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PORT="${PORT:-8060}"
WEB_DIR="$ASTRA_DIR/build/web"
[[ -f "$WEB_DIR/index.html" ]] || { printf 'No browser build found. Run scripts/export.sh web first.\n' >&2; exit 1; }
printf 'Serving Astra at http://127.0.0.1:%s\n' "$PORT"
exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$WEB_DIR"

