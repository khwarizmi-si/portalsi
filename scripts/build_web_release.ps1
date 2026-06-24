param(
  [string]$ApiBaseUrl = "https://api.portalsi.com"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $Root
Write-Host "Building Flutter web for $ApiBaseUrl"
flutter build web --release --dart-define "API_BASE_URL=$ApiBaseUrl"

Write-Host ""
Write-Host "Done: $Root\build\web"
Write-Host "Upload/copy the contents of build\web to the VPS frontend directory."
