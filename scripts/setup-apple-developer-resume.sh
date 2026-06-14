#!/usr/bin/env bash
# Resume Apple Developer setup from Step 3 (after App IDs already exist).
set -euo pipefail

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

TEAM_ID="287KM9YTH9"
APPLE_ID="princestock756@gmail.com"
APP_GROUP="group.com.focusping.shared"
MAIN_BUNDLE="com.focusping.app"
WIDGET_BUNDLE="com.focusping.app.widget"

run() {
  echo "→ $*"
  "$@"
  echo ""
}

echo "=== Step 3: Link App Group ==="
run fastlane produce associate_group -a "$MAIN_BUNDLE" "$APP_GROUP" -b "$TEAM_ID" -u "$APPLE_ID"
run fastlane produce associate_group -a "$WIDGET_BUNDLE" "$APP_GROUP" -b "$TEAM_ID" -u "$APPLE_ID"

echo "=== Step 4: Enable capabilities ==="
run fastlane produce enable_services -a "$MAIN_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID" --app_group
run fastlane produce enable_services -a "$WIDGET_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID" --app_group

echo ""
echo "NOTE: Focus Status is not available via fastlane CLI."
echo "Enable it manually for com.focusping.app:"
echo "  https://developer.apple.com/account/resources/identifiers/list"
echo "  → com.focusping.app → Capabilities → Focus Status → Save"
echo ""

echo "=== Step 5: Verify ==="
fastlane produce available_services -a "$MAIN_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID"

echo "✓ Done. Build for device in Xcode to refresh provisioning profiles."
