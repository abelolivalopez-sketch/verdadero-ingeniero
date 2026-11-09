# Genera las carpetas nativas (android, ios, web, windows) y aplica los ajustes de la app.
# Uso (PowerShell, desde la carpeta del proyecto):  ./tools/setup_platforms.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

flutter create . --project-name verdadero_ingeniero --org com.verdaderoingeniero --platforms=android,ios,web,windows

$manifest = "android/app/src/main/AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "android.permission.INTERNET") {
  $xml = $xml -replace '<manifest xmlns:android="http://schemas.android.com/apk/res/android">', "<manifest xmlns:android=`"http://schemas.android.com/apk/res/android`">`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
}
$xml = $xml -replace 'android:label="verdadero_ingeniero"', 'android:label="Verdadero Ingeniero"'
[System.IO.File]::WriteAllText((Resolve-Path $manifest), $xml)

if (Test-Path "web/index.html") {
  $html = Get-Content "web/index.html" -Raw
  $html = $html -replace '<title>verdadero_ingeniero</title>', '<title>Verdadero Ingeniero</title>'
  $html = $html -replace 'content="verdadero_ingeniero"', 'content="Verdadero Ingeniero"'
  [System.IO.File]::WriteAllText((Resolve-Path "web/index.html"), $html)
}
if (Test-Path "web/manifest.json") {
  $mf = Get-Content "web/manifest.json" -Raw
  $mf = $mf -replace '"name": "verdadero_ingeniero"', '"name": "Verdadero Ingeniero"'
  $mf = $mf -replace '"short_name": "verdadero_ingeniero"', '"short_name": "Ingeniero"'
  [System.IO.File]::WriteAllText((Resolve-Path "web/manifest.json"), $mf)
}

# flutter create genera un test de ejemplo que no aplica a esta app
if ((Test-Path "test/widget_test.dart") -and (Select-String -Path "test/widget_test.dart" -Pattern "MyApp" -Quiet)) {
  Remove-Item "test/widget_test.dart"
}

flutter pub get
Write-Host "Plataformas listas. Ejecuta: flutter run" -ForegroundColor Green
