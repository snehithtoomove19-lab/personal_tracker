# One-time setup for the Personal Tracker Flutter app (Windows).
# Run this from the project root in PowerShell:
#   .\setup.ps1
#
# What it does:
#   1. Cleans any previous build artifacts / lockfile (flutter clean) so a
#      stale pubspec.lock can't override the pinned package versions below.
#   2. Runs `flutter create .` to generate android/ios/web platform folders
#      around the existing lib/ and pubspec.yaml (safe -- never touches lib/).
#   3. Runs `flutter pub get`.

$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter SDK not found on PATH. Install it first: https://docs.flutter.dev/get-started/install"
    exit 1
}

Write-Host "Step 1/3: Cleaning any previous build state..."
if (Test-Path "pubspec.lock") { Remove-Item "pubspec.lock" -Force }
try { flutter clean } catch { }

Write-Host "Step 2/3: Generating platform folders (flutter create .)..."
flutter create .

Write-Host "Step 3/3: Installing packages (flutter pub get)..."
flutter pub get

Write-Host ""
Write-Host "Setup complete! Run: flutter run"
