#!/usr/bin/env bash
# Genera las carpetas nativas (android, ios, web, windows) y aplica los ajustes de la app.
# Uso: bash tools/setup_platforms.sh
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --project-name verdadero_ingeniero --org com.verdaderoingeniero \
  --platforms=android,ios,web,windows

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i.bak 's#<manifest xmlns:android="http://schemas.android.com/apk/res/android">#<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
  rm -f "$MANIFEST.bak"
fi
sed -i.bak 's#android:label="verdadero_ingeniero"#android:label="Verdadero Ingeniero"#' "$MANIFEST" && rm -f "$MANIFEST.bak"

# Título de la pestaña en la versión web
if [ -f web/index.html ]; then
  sed -i.bak 's#<title>verdadero_ingeniero</title>#<title>Verdadero Ingeniero</title>#' web/index.html && rm -f web/index.html.bak
fi

flutter pub get
echo "✔ Plataformas listas. Ejecuta: flutter run"
