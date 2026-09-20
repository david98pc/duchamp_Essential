#!/usr/bin/env bash
set -euo pipefail

RODIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RODIN_FLUTTER_BIN="$(command -v flutter 2>/dev/null || true)"

[ -n "$RODIN_FLUTTER_BIN" ] || {
    echo "Flutter is not in PATH" >&2
    exit 1
}

for RODIN_TOOL in curl unzip install; do
    command -v "$RODIN_TOOL" >/dev/null 2>&1 || {
        echo "Missing required tool: $RODIN_TOOL" >&2
        exit 1
    }
done

RODIN_FLUTTER_BIN="$(readlink -f "$RODIN_FLUTTER_BIN")"
RODIN_FLUTTER_ROOT="$(cd "$(dirname "$RODIN_FLUTTER_BIN")/.." && pwd)"
RODIN_ENGINE_REVISION="$(tr -d '[:space:]' <"$RODIN_FLUTTER_ROOT/bin/internal/engine.version")"
RODIN_ENGINE_URL="https://storage.googleapis.com/flutter_infra_release/flutter/$RODIN_ENGINE_REVISION/android-arm64/android-arm64-embedder.zip"
RODIN_ICU="$(find "$RODIN_FLUTTER_ROOT/bin/cache/artifacts/engine" -type f -name icudtl.dat -print -quit 2>/dev/null || true)"
RODIN_PREBUILT="$RODIN_ROOT/runtime/flutter-engine/prebuilt/android-arm64"
RODIN_INCLUDE="$RODIN_ROOT/runtime/flutter-engine/include"
RODIN_TMP="$(mktemp -d)"

cleanup() {
    rm -rf -- "$RODIN_TMP"
}
trap cleanup EXIT

if [ -z "$RODIN_ICU" ] || [ ! -f "$RODIN_ICU" ]; then
    echo "Flutter ICU data is missing; downloading engine artifacts..."
    flutter precache --android --linux
    RODIN_ICU="$(find "$RODIN_FLUTTER_ROOT/bin/cache/artifacts/engine" -type f -name icudtl.dat -print -quit 2>/dev/null || true)"
fi

[ -n "$RODIN_ICU" ] && [ -f "$RODIN_ICU" ] || {
    echo "Missing Flutter ICU data after precache under $RODIN_FLUTTER_ROOT/bin/cache/artifacts/engine" >&2
    exit 1
}

echo "Downloading official Flutter ARM64 embedder for $RODIN_ENGINE_REVISION"
curl --fail --location --retry 3 --retry-all-errors \
    --output "$RODIN_TMP/android-arm64-embedder.zip" \
    "$RODIN_ENGINE_URL"
unzip -q "$RODIN_TMP/android-arm64-embedder.zip" -d "$RODIN_TMP/embedder"

for RODIN_ARTIFACT in \
    "$RODIN_TMP/embedder/libflutter_engine.so" \
    "$RODIN_TMP/embedder/flutter_embedder.h"; do
    [ -f "$RODIN_ARTIFACT" ] || {
        echo "Missing file in Flutter embedder archive: $RODIN_ARTIFACT" >&2
        exit 1
    }
done

mkdir -p "$RODIN_PREBUILT" "$RODIN_INCLUDE"
install -m 0644 \
    "$RODIN_TMP/embedder/libflutter_engine.so" \
    "$RODIN_PREBUILT/libflutter_engine.so"
install -m 0644 "$RODIN_ICU" "$RODIN_PREBUILT/icudtl.dat"
install -m 0644 \
    "$RODIN_TMP/embedder/flutter_embedder.h" \
    "$RODIN_INCLUDE/embedder.h"
printf '%s\n' "$RODIN_ENGINE_REVISION" >"$RODIN_PREBUILT/engine.version"

echo "FLUTTER_ENGINE_PREBUILT=PASS"
echo "ENGINE_REVISION=$RODIN_ENGINE_REVISION"
echo "PREBUILT_DIR=$RODIN_PREBUILT"
