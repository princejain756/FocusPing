#!/usr/bin/env bash
# Enable App Groups only (Step 4 remainder after associate_group succeeded).
set -euo pipefail

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

TEAM_ID="287KM9YTH9"
APPLE_ID="princestock756@gmail.com"
MAIN_BUNDLE="com.focusping.app"
WIDGET_BUNDLE="com.focusping.app.widget"

run() { echo "→ $*"; "$@"; echo ""; }

echo "=== Enable App Groups capability ==="
run fastlane produce enable_services -a "$MAIN_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID" --app_group
run fastlane produce enable_services -a "$WIDGET_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID" --app_group

echo "=== Verify enabled services ==="
fastlane produce available_services -a "$MAIN_BUNDLE" -b "$TEAM_ID" -u "$APPLE_ID"

echo ""
echo "✓ App Groups enabled."
echo ""
echo "Enable Focus Status manually (not supported by fastlane):"
echo "  https://developer.apple.com/account/resources/identifiers/list"
echo "  → com.focusping.app → Capabilities → Focus Status → Save"
echo ""
echo "Then in Xcode: Product → Clean Build Folder → build for your iPhone."
