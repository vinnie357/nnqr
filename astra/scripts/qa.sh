#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export ASTRA_DATA_DIR="${ASTRA_QA_DATA_DIR:-$ASTRA_DIR/.testdata/qa}"
exec "$SCRIPT_DIR/run.sh" -- --qa
