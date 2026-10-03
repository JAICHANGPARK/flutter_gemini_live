#!/usr/bin/env bash
# Verifies that test/compat/firebase_ai_portable_sample.dart compiles against
# the real package:firebase_ai, so code written for the gemini_live compat
# layer can move back to firebase_ai by swapping the import.
#
# Usage: tool/check_firebase_ai_compat.sh [firebase_ai version]
set -euo pipefail

VERSION="${1:-4.0.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/lib"
cat > "$WORK/pubspec.yaml" <<EOF
name: firebase_ai_compat_check
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  flutter:
    sdk: flutter
  firebase_ai: $VERSION
EOF

sed 's|package:gemini_live/compat/firebase_ai.dart|package:firebase_ai/firebase_ai.dart|' \
  "$ROOT/test/compat/firebase_ai_portable_sample.dart" > "$WORK/lib/sample.dart"

cd "$WORK"
flutter pub get >/dev/null
dart analyze --fatal-infos lib
echo "Portable sample compiles against firebase_ai $VERSION."
