#!/bin/bash
set -euo pipefail

APP_NAME="TextCraft"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy Info.plist and app icon
cp Resources/Info.plist "$CONTENTS/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# Compile all Swift sources into the executable
# -parse-as-library is needed because TextCraftApp.swift uses @main instead of main.swift
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -parse-as-library \
    -target arm64-apple-macosx14.0 \
    -sdk $(xcrun --show-sdk-path) \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -framework ApplicationServices \
    -framework Security \
    -swift-version 6 \
    Sources/*.swift

echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
