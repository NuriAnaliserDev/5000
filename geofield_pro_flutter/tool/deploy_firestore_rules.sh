#!/usr/bin/env bash
# Firebase Firestore qoidalarini loyiha default projectiga yuboradi.
# Talab: firebase CLI o‘rnatilgan va `firebase login` bajarilgan.
set -euo pipefail
cd "$(dirname "$0")/.."
exec firebase deploy --only firestore:rules
