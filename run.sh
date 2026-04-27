#!/bin/bash
set -euo pipefail

# Test runner for Camee E2E tests
# 1. Builds the Android APK
# 2. Launches app on device
# 3. Runs Maestro tests
# 4. Saves artifacts (screenshots, reports) to ./artefacts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_APK="$PROJECT_ROOT/application/android/app/build/outputs/apk/release/app-release.apk"
MAESTRO_BIN="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"
ARTIFACTS_DIR="$SCRIPT_DIR/artefacts"

# Device config
ADB="/home/makame/Android/Sdk/platform-tools/adb"
DEVICE_ID="5VLBB21819200104"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Prep ────────────────────────────────────────────────────────────────────

log_info "Preparing artifacts directory..."
mkdir -p "$ARTIFACTS_DIR"/{screenshots,reports,flows}

# ── Step 1: Build APK ────────────────────────────────────────────────────────

log_info "=== Step 1/3: Building APK ==="

if [[ ! -f "$APP_APK" ]]; then
    log_info "APK not found, running build..."
    bash "$SCRIPT_DIR/scripts/build-apk.sh"
else
    SIZE=$(du -h "$APP_APK" | cut -f1)
    log_info "APK already exists ($SIZE): $APP_APK"
fi

# ── Step 2: Install + Launch on device ────────────────────────────────────────

log_info "=== Step 2/3: Installing and launching app ==="

log_info "Checking ADB connection..."
if ! $ADB -s $DEVICE_ID get-state 2>/dev/null | grep -q device; then
    log_error "Device $DEVICE_ID not found or offline"
    exit 1
fi

# Kill existing app
log_info "Stopping app..."
$ADB -s $DEVICE_ID shell "am force-stop com.rulettv.app" 2>/dev/null || true

# Uninstall old APK and install fresh
log_info "Installing APK..."
$ADB -s $DEVICE_ID install -r -g "$APP_APK" 2>&1 | tail -3

# Launch app
log_info "Launching app..."
$ADB -s $DEVICE_ID shell "am start -n com.rulettv.app/.MainActivity" 2>&1 | tail -3

# Wait for app to stabilise
sleep 5

# ── Step 3: Run Maestro tests ────────────────────────────────────────────────

log_info "=== Step 3/3: Running Maestro tests ==="

if [[ ! -f "$MAESTRO_BIN" ]]; then
    log_error "Maestro not found at $MAESTRO_BIN"
    log_info "Install: https://maestro.mobile.dev/getting-started"
    exit 1
fi

# Pull latest Maestro server (re-install each time — Huawei removes it)
log_info "Ensuring Maestro server is installed..."
MAESTRO_SERVER_APK="/tmp/maestro-app.apk"
if [[ -f "$MAESTRO_SERVER_APK" ]]; then
    $ADB -s $DEVICE_ID install -r -g "$MAESTRO_SERVER_APK" 2>&1 | grep -E "Success|Failure|Error" || true
fi

# Take initial screenshot (before tests)
log_info "Capturing baseline screenshot..."
$ADB -s $DEVICE_ID shell screencap -p /sdcard/baseline.png
$ADB -s $DEVICE_ID pull /sdcard/baseline.png "$ARTIFACTS_DIR/screenshots/" 2>/dev/null || true

# Run Maestro flows
log_info "Running Maestro flows..."
FLOW_DIR="$SCRIPT_DIR/flows"
ARTIFACTS_DIR="$ARTIFACTS_DIR" \
    MAESTRO_BIN="$MAESTRO_BIN" \
    DEVICE_ID="$DEVICE_ID" \
    ADB="$ADB" \
    bash -c '
MAESTRO_BIN="${MAESTRO_BIN:-$HOME/.maestro/bin/maestro}"
ADB="${ADB:-/home/makame/Android/Sdk/platform-tools/adb}"
DEVICE_ID="${DEVICE_ID:-5VLBB21819200104}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$SCRIPT_DIR/artefacts}"
FLOW_DIR="$SCRIPT_DIR/flows"

for flow in "$FLOW_DIR"/*.yaml; do
    [[ -e "$flow" ]] || continue
    flow_name=$(basename "$flow" .yaml)
    echo ""
    echo ">>> Running flow: $flow_name"
    "$MAESTRO_BIN" test \
        --device-spec /dev/stdin \
        --var deviceId="$DEVICE_ID" \
        --var artifactsDir="$ARTIFACTS_DIR" \
        "$flow" 2>&1 || true

    # Capture screenshot after each flow
    $ADB -s "$DEVICE_ID" shell screencap -p /sdcard/"$flow_name".png
    $ADB -s "$DEVICE_ID" pull /sdcard/"$flow_name".png "$ARTIFACTS_DIR/screenshots/" 2>/dev/null || true
done
'

# Capture final screenshot
log_info "Capturing final screenshot..."
$ADB -s $DEVICE_ID shell screencap -p /sdcard/final.png
$ADB -s $DEVICE_ID pull /sdcard/final.png "$ARTIFACTS_DIR/screenshots/" 2>/dev/null || true

# Copy report if generated
if [[ -d "$SCRIPT_DIR/reports" ]]; then
    cp -r "$SCRIPT_DIR/reports/"* "$ARTIFACTS_DIR/reports/" 2>/dev/null || true
fi

# ── Summary ───────────────────────────────────────────────────────────────────

log_info ""
log_info "=== Test run complete ==="
log_info "Artifacts: $ARTIFACTS_DIR"
echo ""
log_info "Screenshots:"
ls -lh "$ARTIFACTS_DIR/screenshots/" 2>/dev/null | tail -10 || log_warn "No screenshots captured"

echo ""
log_info "Done."
