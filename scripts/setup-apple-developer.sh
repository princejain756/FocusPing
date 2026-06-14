#!/usr/bin/env bash
# Register FocusPing App IDs, App Group, and capabilities on Apple Developer Portal.
# Run once in Terminal (interactive — prompts for Apple ID password if needed):
#   ./scripts/setup-apple-developer.sh
set -euo pipefail

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

TEAM_ID="287KM9YTH9"
APPLE_ID="princestock756@gmail.com"
APP_GROUP="group.com.focusping.shared"
MAIN_BUNDLE="com.focusping.app"
WIDGET_BUNDLE="com.focusping.app.widget"

echo "FocusPing — Apple Developer Portal setup"
echo "Team: Prince Jain ($TEAM_ID)"
echo "Apple ID: $APPLE_ID"
echo ""

run() {
  echo "→ $*"
  "$@"
  echo ""
}

echo "=== Step 1: App Group ==="
run fastlane produce group \
  -g "$APP_GROUP" \
  -n "FocusPing Shared" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID"

echo "=== Step 2: App IDs (Developer Portal only, skip App Store Connect record) ==="
run fastlane produce create \
  -a "$MAIN_BUNDLE" \
  -q "FocusPing" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID" \
  --skip_itc true

run fastlane produce create \
  -a "$WIDGET_BUNDLE" \
  -q "FocusPing Widget Extension" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID" \
  --skip_itc true

echo "=== Step 3: Link App Group to both targets ==="
run fastlane produce associate_group \
  -a "$MAIN_BUNDLE" \
  -g "$APP_GROUP" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID"

run fastlane produce associate_group \
  -a "$WIDGET_BUNDLE" \
  -g "$APP_GROUP" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID"

echo "=== Step 4: Enable capabilities ==="
run fastlane produce enable_services \
  -a "$MAIN_BUNDLE" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID" \
  --app_group \
  --focus_status

run fastlane produce enable_services \
  -a "$WIDGET_BUNDLE" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID" \
  --app_group

echo "=== Step 5: Verify ==="
fastlane produce available_services \
  -a "$MAIN_BUNDLE" \
  -b "$TEAM_ID" \
  -u "$APPLE_ID"

echo ""
echo "✓ Portal setup complete."
echo ""
echo "Next in Xcode:"
echo "  1. Open FocusPing.xcodeproj"
echo "  2. FocusPing target → Signing & Capabilities → confirm Team + App Groups + Focus Status"
echo "  3. FocusPingWidgetExtension → confirm Team + App Groups"
echo "  4. Product → Archive (or build for a connected iPhone)"
echo ""
echo "If Focus Status fails to enable via CLI, enable it manually:"
echo "  https://developer.apple.com/account/resources/identifiers/list"
echo "  → com.focusping.app → Capabilities → Focus Status"
