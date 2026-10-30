#!/bin/bash
set -e

echo "Installing Flutter SDK..."

git clone --depth 1 -b stable https://github.com/flutter/flutter.git /tmp/flutter

export PATH="/tmp/flutter/bin:$PATH"

flutter --version
flutter config --enable-web

echo "Getting Flutter dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release