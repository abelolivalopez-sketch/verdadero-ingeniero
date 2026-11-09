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

# Título y nombre de la app web (PWA)
if [ -f web/index.html ]; then
  sed -i.bak 's#<title>verdadero_ingeniero</title>#<title>Verdadero Ingeniero</title>#' web/index.html && rm -f web/index.html.bak
  sed -i.bak 's#content="verdadero_ingeniero"#content="Verdadero Ingeniero"#g' web/index.html && rm -f web/index.html.bak
fi
if [ -f web/manifest.json ]; then
  sed -i.bak -e 's#"name": "verdadero_ingeniero"#"name": "Verdadero Ingeniero"#' \
             -e 's#"short_name": "verdadero_ingeniero"#"short_name": "Ingeniero"#' \
             -e 's#"background_color": "[^"]*"#"background_color": "\#070B16"#' \
             -e 's#"theme_color": "[^"]*"#"theme_color": "\#4FD1FF"#' web/manifest.json && rm -f web/manifest.json.bak
fi

# flutter create genera un test de ejemplo que no aplica a esta app
if grep -qs "MyApp" test/widget_test.dart; then rm -f test/widget_test.dart; fi

flutter pub get
echo "✔ Plataformas listas. Ejecuta: flutter run"
