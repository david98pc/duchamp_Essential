#!/usr/bin/env bash
set -euo pipefail

RODIN_FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"

[ -n "$RODIN_FLUTTER_BIN" ] || {
    echo "Flutter is not in PATH" >&2
    exit 1
}

RODIN_FLUTTER_BIN="$(readlink -f "$RODIN_FLUTTER_BIN")"
RODIN_FLUTTER_ROOT="$(cd "$(dirname "$RODIN_FLUTTER_BIN")/.." && pwd)"
RODIN_ENGINE_REVISION="$(tr -d '[:space:]' <"$RODIN_FLUTTER_ROOT/bin/internal/engine.version")"
echo "Refusing the published android-arm64 embedder because it is a debug engine and cannot run the AOT release bundle." >&2
echo "Required release engine revision: $RODIN_ENGINE_REVISION" >&2
echo "Build the matching release embedder with tools/build-flutter-engine.sh instead." >&2
exit 1
