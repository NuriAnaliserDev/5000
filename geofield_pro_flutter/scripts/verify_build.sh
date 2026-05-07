#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== flutter analyze =="
flutter analyze
echo "== flutter test =="
flutter test
echo "== flutter build apk --debug =="
flutter build apk --debug
echo "== OK =="
