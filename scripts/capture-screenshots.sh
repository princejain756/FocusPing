#!/usr/bin/env bash
# Capture distinct FocusPing simulator screenshots for the marketing site.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/website/public/screenshots"
SIM_ID="${SIM_ID:-C89D1826-299C-4FE3-94EF-2DDDFAE53B70}"
BUNDLE="com.focusping.app"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData/FocusPingScreenshots"

rm -rf "$OUT"
mkdir -p "$OUT"

echo "→ Building FocusPing..."
xcodebuild -project "$ROOT/FocusPing.xcodeproj" \
  -scheme FocusPing \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED" \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3

APP=$(find "$DERIVED" -name "FocusPing.app" -path "*iphonesimulator*" | head -1)
if [[ -z "$APP" ]]; then
  echo "Could not find FocusPing.app"
  exit 1
fi

echo "→ Preparing simulator $SIM_ID..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_ID" 2>/dev/null || true
sleep 2

xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"

capture() {
  local screen="$1"
  local file="$2"
  echo "→ Capturing $file ($screen)..."
  xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_ID" "$BUNDLE" -MarketingScreenshots "$screen" >/dev/null
  sleep 2.5
  xcrun simctl io "$SIM_ID" screenshot "$OUT/$file"
}

capture onboarding onboarding.png
capture home home.png
capture queue queue.png
capture settings settings.png

echo "→ Done — distinct screenshots:"
ls -la "$OUT"

# Verify files are not identical
HASHES=$(md5 -q "$OUT"/*.png | sort -u | wc -l | tr -d ' ')
COUNT=$(ls "$OUT"/*.png | wc -l | tr -d ' ')
if [[ "$HASHES" -lt "$COUNT" ]]; then
  echo "WARNING: Some screenshots may still be duplicates ($HASHES unique / $COUNT total)"
  exit 1
fi

echo "✓ All $COUNT screenshots are unique"
