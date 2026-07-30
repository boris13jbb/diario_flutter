#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.2}"
FLUTTER_ROOT="${HOME}/flutter"

if [ ! -x "${FLUTTER_ROOT}/bin/flutter" ]; then
  echo ">> Installing Flutter ${FLUTTER_VERSION}"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${FLUTTER_ROOT}"
fi

export PATH="${FLUTTER_ROOT}/bin:${PATH}"
flutter --version
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release

echo ">> Web build ready at build/web"
