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
  [System.IO.File]::WriteAllText((Resolve-Path "web/index.html"), $html)
}

flutter pub get
Write-Host "Plataformas listas. Ejecuta: flutter run" -ForegroundColor Green
