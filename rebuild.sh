#!/bin/bash
# Full clean rebuild script for Ô Ăn Quan
# Usage: ./rebuild.sh

set -e

echo "=== Regenerating Xcode project ==="
xcodegen generate

echo "=== Cleaning build artifacts ==="
xcodebuild clean -project OAnQuan.xcodeproj -scheme OAnQuan -quiet 2>/dev/null || true

echo "=== Building for simulator ==="
xcodebuild -project OAnQuan.xcodeproj \
    -scheme OAnQuan \
    -destination 'generic/platform=iOS Simulator' \
    -quiet build

echo "=== Building for device (archive) ==="
xcodebuild -project OAnQuan.xcodeproj \
    -scheme OAnQuan \
    -destination 'generic/platform=iOS' \
    -quiet build

echo "=== BUILD SUCCEEDED ==="
echo "To archive for App Store: open Xcode → Product → Archive"
echo "Make sure target is 'Any iOS Device (arm64)'"
