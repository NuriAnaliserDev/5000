#!/usr/bin/env bash
# Tezkor sifat devorgi: analyze + test.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter analyze
flutter test "$@"
echo "OK: analyze va test muvaffaqiyatli. Keyingi qadam: flutter build apk --debug"
