#!/usr/bin/env bash
# Resolve a working Godot binary and exec it. mise/aqua's macOS install is broken
# (case-insensitive FS self-symlink clobbers the binary), so we resolve in order:
#   1. $GODOT_BIN if set + executable
#   2. a cached direct download under ~/.cache/nnqr-godot/<ver>
#   3. download the official release zip for this OS, extract, cache, run
set -euo pipefail
VER="${GODOT_VERSION:-4.6.3-stable}"
CACHE="$HOME/.cache/nnqr-godot/$VER"

if [ -n "${GODOT_BIN:-}" ] && [ -x "${GODOT_BIN}" ]; then exec "$GODOT_BIN" "$@"; fi

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  BIN="$CACHE/Godot.app/Contents/MacOS/Godot"
  ASSET="Godot_v${VER}_macos.universal.zip"
else
  BIN="$(ls "$CACHE"/Godot_v*_linux.x86_64 2>/dev/null | head -1 || true)"
  ASSET="Godot_v${VER}_linux.x86_64.zip"
fi

if [ -z "${BIN:-}" ] || [ ! -x "${BIN:-/nonexistent}" ]; then
  mkdir -p "$CACHE"
  URL="https://github.com/godotengine/godot/releases/download/${VER}/${ASSET}"
  echo "godot.sh: downloading $URL" >&2
  curl -sL -o "$CACHE/godot.zip" "$URL"
  unzip -qo "$CACHE/godot.zip" -d "$CACHE"
  if [ "$OS" = "Darwin" ]; then
    xattr -dr com.apple.quarantine "$CACHE/Godot.app" 2>/dev/null || true
    BIN="$CACHE/Godot.app/Contents/MacOS/Godot"
  else
    BIN="$(ls "$CACHE"/Godot_v*_linux.x86_64 | head -1)"
  fi
  chmod +x "$BIN" 2>/dev/null || true
fi
exec "$BIN" "$@"
