#!/bin/bash
# Script to permanently disable Huawei security prompts and install APKs without approval
# Run: bash fix-huawei-security.sh

ADB="/home/makame/Android/Sdk/platform-tools/adb"
DEVICE="5VLBB21819200104"
APK_SERVER="/tmp/maestro-app.apk"  # dev.mobile.maestro (SERVER)
APK_TEST="/tmp/maestro-test.apk"    # dev.mobile.maestro.test (TEST)

echo "=== Huawei Security Disabler v2 ==="
echo "Device: $DEVICE"

# Step 1: Kill all security prompts
echo ""
echo "[1/6] Stopping security services..."
$ADB -s $DEVICE shell am force-stop com.huawei.securitymgr 2>/dev/null
$ADB -s $DEVICE shell am force-stop com.huawei.securityserver 2>/dev/null
$ADB -s $DEVICE shell am force-stop com.huawei.security.privacycenter 2>/dev/null
$ADB -s $DEVICE shell am force-stop com.huawei.trustagent 2>/dev/null
$ADB -s $DEVICE shell am force-stop com.huawei.trustcircle 2>/dev/null
$ADB -s $DEVICE shell am force-stop com.huawei.trustedthingsauth 2>/dev/null

# Step 2: Disable verification settings
echo "[2/6] Setting verification to OFF..."
$ADB -s $DEVICE shell settings put global package_verifier_enable 0
$ADB -s $DEVICE shell settings put global verify_adb_installs 0
$ADB -s $DEVICE shell settings put global install_non_market_apps 1
$ADB -s $DEVICE shell settings put global unknown_sources_default_reversed 1
$ADB -s $DEVICE shell settings put global permission_manager_enabled 0

# Step 3: Disable security packages
echo "[3/6] Disabling security packages..."
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.securitymgr 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.securityserver 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.security.privacycenter 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.trustagent 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.trustcircle 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.trustedthingsauth 2>/dev/null
$ADB -s $DEVICE shell pm disable-user --user 0 com.huawei.securitypluginbase 2>/dev/null

# Step 4: Push APKs
echo "[4/6] Pushing APKs to device..."
$ADB -s $DEVICE push $APK_SERVER /data/local/tmp/maestro-app.apk 2>/dev/null
$ADB -s $DEVICE push $APK_TEST /data/local/tmp/maestro-test.apk 2>/dev/null

# Step 5: Install using pm (bypassing ADB install dialog)
echo "[5/6] Installing via pm (no prompts)..."
$ADB -s $DEVICE shell pm install -r -g /data/local/tmp/maestro-app.apk 2>&1 &
PM_PID=$!
sleep 15
kill $PM_PID 2>/dev/null

# Fallback: try standard install
echo "[6/6] Fallback: standard adb install..."
$ADB -s $DEVICE install -r -g $APK_SERVER 2>&1 &
INSTALL_PID=$!
sleep 20
kill $INSTALL_PID 2>/dev/null

# Verify
echo ""
echo "=== VERIFICATION ==="
echo "Maestro packages:"
$ADB -s $DEVICE shell "pm path dev.mobile.maestro" 2>/dev/null || echo "  NOT installed"
$ADB -s $DEVICE shell "pm path dev.mobile.maestro.test" 2>/dev/null || echo "  NOT installed"

echo ""
echo "Security packages (should be disabled):"
$ADB -s $DEVICE shell pm list packages -d --user 0 | grep -i security || echo "  None found"

echo ""
echo "Done. Check device screen for any remaining prompts."