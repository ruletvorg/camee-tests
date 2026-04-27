# Camee Testing Environment - Maestro E2E

## Setup

### 1. Install Maestro CLI
```bash
curl -Ls https://get.maestro.mobile.dev | bash
# or
npm install -g @maestro/cli
```

### 2. Android SDK
Make sure Android SDK is configured:
```bash
export ANDROID_HOME=~/.android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools
```

### 3. Connect device/emulator
```bash
# Check connected devices
adb devices
```

## Running Tests

```bash
cd /home/makame/projects/camee/testing

# Run all flows
maestro test flows --config config.yaml

# Run specific flow
maestro test flows/onboarding.yaml

# Run with debug output
maestro test flows --config config.yaml --debug

# Open Maestro Studio (visual test recorder)
maestro studio
```

## Structure

```
testing/
├── config.yaml          # Maestro configuration
├── flows/               # Test flows (*.yaml)
│   ├── onboarding.yaml  # Login/auth tests
│   ├── ruletka.yaml    # Video chat tests
│   └── profile.yaml    # Profile screen tests
├── helpers/             # Reusable helper functions
│   ├── auth-helper.ts
│   └── navigation-helper.ts
├── page-objects/        # Page object patterns (future)
└── reports/            # Test reports output
```

## Environment Variables

Set in `config.yaml` or export before running:
```bash
export TEST_USER_EMAIL="test@example.com"
export TEST_USER_PASSWORD="password123"
```

## Writing New Tests

See Maestro docs: https://maestro.mobile.dev/reference/yaml

### Basic Flow Template
```yaml
appId: com.rulettv.app

---
- launchApp
- waitForAppToIdle: 2000

# Your test steps here
- tapOn:
    id: "element_id"
- inputText:
    id: "input_id"
    text: "some text"
- assertVisible:
    text: "Expected text"
- takeScreenshot: { name: "step_name" }
```

## APK Location
`/home/makame/projects/camee/application/android/app/build/outputs/apk/release/app-release.apk`
