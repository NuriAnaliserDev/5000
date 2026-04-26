# Firebase Android google-services.json ni qayta yuklab olish (token: firebase login).
$ErrorActionPreference = "Stop"
$AppId = "1:36261437268:android:3c161d7c50a494a136f2c1"
$Out = Join-Path $PSScriptRoot "app\google-services.json"
$Tmp = "$Out.new"
Push-Location $PSScriptRoot\..
try {
  npx --yes firebase-tools@14.0.0 apps:sdkconfig ANDROID $AppId --out $Tmp
  if (-not (Test-Path $Tmp)) { throw "Yuklab olinmadi: $Tmp" }
  Copy-Item -Force $Tmp $Out
  Remove-Item $Tmp
  Write-Host "OK: $Out yangilandi."
} finally {
  Pop-Location
}
