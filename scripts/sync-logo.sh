#!/usr/bin/env bash
# Sync focuspinglogo.png → iOS assets + website public files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGO="$ROOT/focuspinglogo.png"

if [[ ! -f "$LOGO" ]]; then
  echo "Missing logo: $LOGO"
  exit 1
fi

echo "→ Syncing from focuspinglogo.png"

# iOS
cp "$LOGO" "$ROOT/FocusPing/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
sips -z 1024 1024 "$ROOT/FocusPing/Assets.xcassets/AppIcon.appiconset/AppIcon.png" >/dev/null
cp "$LOGO" "$ROOT/FocusPing/Assets.xcassets/LaunchBrand.imageset/LaunchBrand.png"
sips -z 1024 1024 "$ROOT/FocusPing/Assets.xcassets/LaunchBrand.imageset/LaunchBrand.png" >/dev/null

# Website — canonical paths
PUBLIC="$ROOT/website/public"
mkdir -p "$PUBLIC"

cp "$LOGO" "$PUBLIC/logo.png"
sips -z 512 512 "$PUBLIC/logo.png" >/dev/null

cp "$LOGO" "$PUBLIC/app-icon.png"
sips -z 512 512 "$PUBLIC/app-icon.png" >/dev/null

cp "$LOGO" "$PUBLIC/favicon.png"
sips -z 32 32 "$PUBLIC/favicon.png" >/dev/null

cp "$LOGO" "$PUBLIC/apple-touch-icon.png"
sips -z 180 180 "$PUBLIC/apple-touch-icon.png" >/dev/null

# OG card: logo centered on brand background
TMP="$PUBLIC/.og-tmp.png"
sips -z 520 520 "$LOGO" --out "$TMP" >/dev/null
sips --padToHeightWidth 630 1200 --padColor 0c0b0f "$TMP" --out "$PUBLIC/og-image.png" >/dev/null
rm -f "$TMP"

# Remove stale Astro default favicons that override our logo in browsers
rm -f "$PUBLIC/favicon.svg" "$PUBLIC/favicon.ico"

echo "✓ Logo synced to app + website/public (logo.png, app-icon.png, favicon.png, og-image.png)"
