#!/usr/bin/env bash
# Capture FocusPing simulator screenshots for the marketing site.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/website/public/screenshots"
SIM_ID="${SIM_ID:-C89D1826-299C-4FE3-94EF-2DDDFAE53B70}"
BUNDLE="com.focusping.app"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"

mkdir -p "$OUT"

echo "→ Building FocusPing for simulator..."
xcodebuild -project "$ROOT/FocusPing.xcodeproj" \
  -scheme FocusPing \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED/FocusPingScreenshots" \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3

APP=$(find "$DERIVED/FocusPingScreenshots" -name "FocusPing.app" -path "*iphonesimulator*" | head -1)
if [[ -z "$APP" ]]; then
  echo "Could not find FocusPing.app"
  exit 1
fi

echo "→ Booting simulator $SIM_ID..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_ID" 2>/dev/null || true
sleep 2

echo "→ Installing app..."
xcrun simctl install "$SIM_ID" "$APP"

# Fresh install for onboarding screenshot
xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl launch "$SIM_ID" "$BUNDLE" >/dev/null
sleep 2
xcrun simctl io "$SIM_ID" screenshot "$OUT/onboarding.png"

# Skip onboarding via defaults (if onboarding uses UserDefaults)
# Complete onboarding by tapping through - use simctl ui tap
tap() {
  if xcrun simctl help ui 2>/dev/null | grep -q tap; then
    xcrun simctl ui "$SIM_ID" tap "$1" "$2" 2>/dev/null || true
  fi
}

# Tap through onboarding: Skip or Continue buttons (approximate iPhone 16 coords)
for _ in 1 2 3; do
  tap 200 750
  sleep 0.8
done
tap 200 700
sleep 1

xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl launch "$SIM_ID" "$BUNDLE" >/dev/null
sleep 2
xcrun simctl io "$SIM_ID" screenshot "$OUT/home.png"

# Queue tab (2nd tab, ~x=150 y=820 on iPhone 16)
tap 150 820
sleep 1
xcrun simctl io "$SIM_ID" screenshot "$OUT/queue.png"

# Settings tab (4th tab)
tap 330 820
sleep 1
xcrun simctl io "$SIM_ID" screenshot "$OUT/settings.png"

echo "→ Screenshots saved to $OUT"
ls -la "$OUT"
