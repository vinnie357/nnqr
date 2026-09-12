#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT_VERSION="${GODOT_VERSION:-4.6.3-stable}"
VERSION_NUMBER="${GODOT_VERSION%-stable}"
CACHED_MAC="${HOME}/.cache/nnqr-godot/${GODOT_VERSION}/Godot.app/Contents/MacOS/Godot"
export ASTRA_DATA_DIR="${ASTRA_DATA_DIR:-$ASTRA_DIR/.userdata}"
mkdir -p "$ASTRA_DATA_DIR"

EXPECT_LOG_PATH=false
for argument in "$@"; do
  if [[ "$EXPECT_LOG_PATH" == true ]]; then
    export ASTRA_LOG_FILE="$argument"
    EXPECT_LOG_PATH=false
  elif [[ "$argument" == "--log-file" ]]; then
    EXPECT_LOG_PATH=true
  fi
done

fail() {
  printf 'Astra Godot launcher: %s\n' "$*" >&2
  exit 1
}

verify_version() {
  local binary="$1"
  local actual
  actual="$("$binary" --version 2>/dev/null || true)"
  [[ "$actual" == "$VERSION_NUMBER"* ]] || fail "'$binary' is $actual; expected $GODOT_VERSION. Set GODOT_BIN or GODOT_VERSION explicitly."
}

if [[ -n "${GODOT_BIN:-}" ]]; then
  [[ -x "$GODOT_BIN" ]] || fail "GODOT_BIN is not executable: $GODOT_BIN"
  verify_version "$GODOT_BIN"
  exec "$GODOT_BIN" "$@"
fi

if [[ -x "$CACHED_MAC" ]]; then
  verify_version "$CACHED_MAC"
  exec "$CACHED_MAC" "$@"
fi

TOOLS_DIR="$ASTRA_DIR/.tools"
case "$(uname -s):$(uname -m)" in
  Darwin:arm64|Darwin:x86_64)
    ARCHIVE="Godot_v${GODOT_VERSION}_macos.universal.zip"
    DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${ARCHIVE}"
    BINARY="$TOOLS_DIR/Godot.app/Contents/MacOS/Godot"
    ;;
  Linux:x86_64)
    ARCHIVE="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
    DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${ARCHIVE}"
    BINARY="$TOOLS_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"
    ;;
  *) fail "unsupported host $(uname -s) $(uname -m); set GODOT_BIN to a Godot $GODOT_VERSION executable" ;;
esac

if [[ ! -x "$BINARY" ]]; then
  command -v curl >/dev/null || fail "curl is required to download Godot; alternatively set GODOT_BIN"
  command -v unzip >/dev/null || fail "unzip is required to install Godot; alternatively set GODOT_BIN"
  mkdir -p "$TOOLS_DIR"
  TEMP_ARCHIVE="$TOOLS_DIR/${ARCHIVE}.partial"
  printf 'Downloading Godot %s into %s\n' "$GODOT_VERSION" "$TOOLS_DIR" >&2
  if ! curl --fail --location --retry 2 --output "$TEMP_ARCHIVE" "$DOWNLOAD_URL"; then
    rm -f "$TEMP_ARCHIVE"
    fail "download failed ($DOWNLOAD_URL). Network access may be unavailable; set GODOT_BIN to an existing executable"
  fi
  unzip -q -o "$TEMP_ARCHIVE" -d "$TOOLS_DIR"
  rm -f "$TEMP_ARCHIVE"
  chmod +x "$BINARY"
fi

verify_version "$BINARY"
exec "$BINARY" "$@"
