#!/bin/bash
set -euo pipefail

# Build script for Camee Android APK (release)
# Output: /home/makame/projects/camee/application/android/app/build/outputs/apk/release/app-release.apk
#
# Skips Gradle build if APK already exists (avoids node 134 crash in settings.gradle evaluation)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="/home/makame/projects/camee"
BUILD_OUTPUT="$PROJECT_ROOT/application/android/app/build/outputs/apk/release/app-release.apk"

echo "=== Camee Android Release Build ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Step 1: npm install in application
echo "[1/5] npm install (application)..."
cd "$PROJECT_ROOT/application"
npm install --legacy-peer-deps 2>&1 | tail -5

# Step 2: prebuild:android
echo ""
echo "[2/6] npm run prebuild:android..."
npm run prebuild:android 2>&1 | tail -10

# Step 3: preinit from builder (loads manifest, modules, components, localization)
echo ""
echo "[3/6] npm run preinit (builder)..."
cd "$PROJECT_ROOT/application/builder"
npm run preinit 2>&1 | tail -15

# Step 4: Check if APK already exists — skip Gradle if yes
echo ""
if [[ -f "$BUILD_OUTPUT" ]]; then
    SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
    echo "[4/6] APK already exists ($SIZE) — skipping Gradle build"
    echo "[5/6] Skipped (APK pre-existing)"
    echo "[6/6] APK: $BUILD_OUTPUT"
else
    # Step 4: Copy android/ dir from builder if needed
    echo ""
    echo "[4/6] Checking android directory..."
    if [[ ! -d "$PROJECT_ROOT/application/android" ]]; then
        echo "[4/6] Copying android/ from builder..."
        cp -r "$PROJECT_ROOT/application/builder/android" "$PROJECT_ROOT/application/android"
    fi

    # Step 5: Gradle assembleRelease
    echo ""
    echo "[5/6] ./gradlew assembleRelease..."
    cd "$PROJECT_ROOT/application/android"
    ./gradlew assembleRelease --no-daemon 2>&1 | tail -20
fi

# Step 6: Verify output
echo ""
echo "[6/6] Verifying APK..."
if [[ -f "$BUILD_OUTPUT" ]]; then
    SIZE=$(du -h "$BUILD_OUTPUT" | cut -f1)
    echo "✓ APK ready"
    echo "  Path: $BUILD_OUTPUT"
    echo "  Size: $SIZE"
else
    echo "✗ APK not found at $BUILD_OUTPUT"
    exit 1
fi

echo ""
echo "=== Build complete ==="
