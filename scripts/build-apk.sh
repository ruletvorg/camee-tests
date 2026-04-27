#!/bin/bash
set -euo pipefail

# Build script for Camee Android APK (release)
# Output: /home/makame/projects/camee/application/android/app/build/outputs/apk/release/app-release.apk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_OUTPUT="$PROJECT_ROOT/application/android/app/build/outputs/apk/release/app-release.apk"

echo "=== Camee Android Release Build ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Step 1: npm install in application
echo "[1/6] npm install (application)..."
cd "$PROJECT_ROOT/application"
npm install --legacy-peer-deps 2>&1 | tail -5

# Step 2: prebuild:android
echo ""
echo "[2/6] npm run prebuild:android..."
npm run prebuild:android 2>&1 | tail -10

# Step 3: npm install in builder
echo ""
echo "[3/6] npm install (builder)..."
cd "$PROJECT_ROOT/application/builder"
npm install 2>&1 | tail -5

# Step 4: prebuild in builder
echo ""
echo "[4/6] npm run prebuild (builder)..."
npm run prebuild 2>&1 | tail -10

# Step 5: Gradle assembleRelease
echo ""
echo "[5/6] ./gradlew assembleRelease..."
cd "$PROJECT_ROOT/application/android"
./gradlew assembleRelease --no-daemon --warning-mode=all 2>&1 | tail -20

# Step 6: Verify output
echo ""
echo "[6/6] Verifying APK..."
if [[ -f "$BUILD_OUTPUT" ]]; then
    SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
    echo "✓ APK built successfully!"
    echo "  Path: $BUILD_OUTPUT"
    echo "  Size: $SIZE"
else
    echo "✗ APK not found at $BUILD_OUTPUT"
    exit 1
fi

echo ""
echo "=== Build complete ==="
