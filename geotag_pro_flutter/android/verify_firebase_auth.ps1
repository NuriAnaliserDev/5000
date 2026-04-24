# Auth backend yoqilganini tekshiradi: export ishlasa — OK.
# Ishlatish: geotag_pro_flutter papkasidan: powershell -File android/verify_firebase_auth.ps1
$ErrorActionPreference = "Stop"
$flutterRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $flutterRoot
$tmp = [System.IO.Path]::GetTempFileName() + ".json"
try {
  npx --yes firebase-tools@14.0.0 auth:export $tmp --format JSON --project geofield-pro-8529f
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Auth sozlamalari OK (export muvaffaqiyatli)."
    exit 0
  }
} finally {
  Remove-Item $tmp -ErrorAction SilentlyContinue
}
Write-Host "Auth hali to'liq yoqilmagan. android/open_firebase_auth.ps1 va FIREBASE_AUTH_RECAPTCHA.txt 0-bo'limi."
exit 1
