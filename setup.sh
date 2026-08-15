#!/usr/bin/env bash
# One-time setup for the Personal Tracker Flutter app.
# Run this from the project root (the folder this script is in):
#   chmod +x setup.sh && ./setup.sh
#
# What it does:
#   1. Cleans any previous build artifacts / lockfile (flutter clean) so a
#      stale pubspec.lock can't override the pinned package versions below.
#   2. Runs `flutter create .` to generate android/ios/web platform folders
#      around the existing lib/ and pubspec.yaml (safe -- never touches lib/).
#   3. Runs `flutter pub get`.

set -e

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found on PATH. Install it first: https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "Step 1/3: Cleaning any previous build state..."
rm -f pubspec.lock
flutter clean || true

echo "Step 2/3: Generating platform folders (flutter create .)..."
flutter create .

echo "Step 3/3: Installing packages (flutter pub get)..."
flutter pub get

echo ""
echo "Setup complete! Run: flutter run"
