#!/usr/bin/env bash
# End-to-end FocusPing simulator QA — build, install, launch, verify screens & logs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_ID="${SIM_ID:-C89D1826-299C-4FE3-94EF-2DDDFAE53B70}"
BUNDLE="com.focusping.app"
DERIVED="$ROOT/.qa-derived"
LOG_DIR="$ROOT/.qa-logs"
REPORT="$ROOT/AppStore/QA_REPORT.md"
PASS=0
FAIL=0
WARN=0

mkdir -p "$LOG_DIR"
: > "$REPORT"

log() { echo "$@" | tee -a "$REPORT"; }
pass() { PASS=$((PASS + 1)); log "✅ PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); log "❌ FAIL: $1"; }
warn() { WARN=$((WARN + 1)); log "⚠️ WARN: $1"; }

log "# FocusPing Simulator QA Report"
log "Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
log "Simulator: iPhone 16 ($SIM_ID)"
log ""

# ── Build ──────────────────────────────────────────────────────────────────
log "## Build"
if xcodebuild -project "$ROOT/FocusPing.xcodeproj" \
  -scheme FocusPing \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED" \
  build CODE_SIGNING_ALLOWED=NO >"$LOG_DIR/build.log" 2>&1; then
  pass "xcodebuild succeeded"
else
  fail "xcodebuild failed — see .qa-logs/build.log"
  tail -20 "$LOG_DIR/build.log" >> "$REPORT"
  exit 1
fi

APP=$(find "$DERIVED" -name "FocusPing.app" -path "*iphonesimulator*" | head -1)
if [[ -z "$APP" ]]; then
  fail "FocusPing.app not found in derived data"
  exit 1
fi
pass "Found app bundle"

# ── Simulator prep ─────────────────────────────────────────────────────────
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_ID" 2>/dev/null || true
sleep 2

xcrun simctl privacy "$SIM_ID" grant notifications "$BUNDLE" 2>/dev/null || true
xcrun simctl privacy "$SIM_ID" grant reminders "$BUNDLE" 2>/dev/null || true

# ── Screen launch tests (MarketingScreenshots seeder) ───────────────────────
log ""
log "## Screen launch (no crash)"

launch_screen() {
  local screen="$1"
  local logfile="$LOG_DIR/launch-$screen.log"
  xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.5
  # Capture stderr for crash reports
  if xcrun simctl launch "$SIM_ID" "$BUNDLE" -MarketingScreenshots "$screen" >"$logfile" 2>&1; then
    sleep 2
    local pid
    pid=$(xcrun simctl spawn "$SIM_ID" launchctl list 2>/dev/null | grep "$BUNDLE" | awk '{print $1}' || true)
    if xcrun simctl io "$SIM_ID" screenshot "$LOG_DIR/screen-$screen.png" 2>/dev/null; then
      local size
      size=$(stat -f%z "$LOG_DIR/screen-$screen.png" 2>/dev/null || stat -c%s "$LOG_DIR/screen-$screen.png" 2>/dev/null || echo 0)
      if [[ "$size" -gt 50000 ]]; then
        pass "Screen '$screen' launched — screenshot ${size} bytes"
      else
        warn "Screen '$screen' — screenshot suspiciously small ($size bytes)"
      fi
    else
      fail "Screen '$screen' — screenshot failed"
    fi
  else
    fail "Screen '$screen' — launch failed"
    cat "$logfile" >> "$REPORT"
  fi
}

xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"
pass "Fresh install complete"

for screen in onboarding home queue settings; do
  launch_screen "$screen"
done

# Verify screenshots are unique
HASHES=$(md5 -q "$LOG_DIR"/screen-*.png 2>/dev/null | sort -u | wc -l | tr -d ' ')
COUNT=$(ls "$LOG_DIR"/screen-*.png 2>/dev/null | wc -l | tr -d ' ')
if [[ "$HASHES" -eq "$COUNT" && "$COUNT" -ge 4 ]]; then
  pass "All $COUNT screen screenshots are visually distinct"
else
  fail "Screenshots may be duplicates ($HASHES unique / $COUNT total)"
fi

# ── Fresh onboarding launch ────────────────────────────────────────────────
log ""
log "## Fresh onboarding flow"

xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl privacy "$SIM_ID" grant notifications "$BUNDLE" 2>/dev/null || true

LOGFILE="$LOG_DIR/fresh-launch.log"
xcrun simctl launch --console "$SIM_ID" "$BUNDLE" >"$LOGFILE" 2>&1 &
LAUNCH_PID=$!
sleep 4
kill "$LAUNCH_PID" 2>/dev/null || true

if grep -qiE "crash|assertion|fatal|SIGABRT|terminated" "$LOGFILE" 2>/dev/null; then
  fail "Crash/error detected in fresh launch log"
  grep -iE "crash|assertion|fatal|error" "$LOGFILE" | head -5 >> "$REPORT"
else
  pass "Fresh launch — no crash signatures in 4s console log"
fi

xcrun simctl io "$SIM_ID" screenshot "$LOG_DIR/fresh-onboarding.png" 2>/dev/null
pass "Fresh onboarding screenshot captured"

# ── Log stream crash check during idle ─────────────────────────────────────
log ""
log "## Runtime stability (10s idle)"

xcrun simctl launch "$SIM_ID" "$BUNDLE" -MarketingScreenshots home >/dev/null 2>&1
sleep 1
STABILITY_LOG="$LOG_DIR/stability.log"
timeout 10 xcrun simctl spawn "$SIM_ID" log stream --predicate 'processImagePath CONTAINS "FocusPing"' --style compact >"$STABILITY_LOG" 2>&1 || true

if grep -qiE "crash|assertion|fatal|SIGABRT|EXC_|terminated due to" "$STABILITY_LOG" 2>/dev/null; then
  fail "Runtime crash detected during 10s idle"
else
  pass "10s idle — no crash in FocusPing logs"
fi

# ── Logic tests (-QATest harness) ──────────────────────────────────────────
log ""
log "## Delivery logic tests (-QATest)"

xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl privacy "$SIM_ID" grant notifications "$BUNDLE" 2>/dev/null || true

QALOG="$LOG_DIR/qatest.log"
xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
sleep 1
xcrun simctl launch "$SIM_ID" "$BUNDLE" -QATest >/dev/null 2>&1
sleep 12
DATA_DIR=$(xcrun simctl get_app_container "$SIM_ID" "$BUNDLE" data 2>/dev/null || true)
QAFILE="$DATA_DIR/Documents/focusping-qa.txt"
if [[ -f "$QAFILE" ]]; then
  cp "$QAFILE" "$QALOG"
else
  echo "complete=0" > "$QALOG"
fi
xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true

if grep -q "^complete=1" "$QALOG" 2>/dev/null; then
  while IFS= read -r line; do
    [[ "$line" == PASS:* ]] && pass "${line#PASS:}"
    [[ "$line" == FAIL:* ]] && fail "${line#FAIL:}"
  done < "$QALOG"
else
  fail "QATest harness did not complete — see .qa-logs/qatest.log"
fi

if grep -q "^pass=" "$QALOG" 2>/dev/null; then
  grep "^pass=" "$QALOG" >> "$REPORT"
  grep "^fail=" "$QALOG" >> "$REPORT"
fi

# ── Website URLs ───────────────────────────────────────────────────────────
log ""
log "## Website URLs"

check_url() {
  local url="$1"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    pass "$url → HTTP $code"
  elif [[ "$code" == "404" ]]; then
    warn "$url → HTTP 404 (domain not linked to Vercel yet)"
  else
    warn "$url → HTTP $code"
  fi
}

check_url "https://focusping.prince.sh"
check_url "https://focusping.prince.sh/privacy"
check_url "https://focusping.prince.sh/support"

# ── Summary ────────────────────────────────────────────────────────────────
log ""
log "## Summary"
log "| Result | Count |"
log "|--------|-------|"
log "| Pass   | $PASS |"
log "| Fail   | $FAIL |"
log "| Warn   | $WARN |"
log ""

if [[ "$FAIL" -gt 0 ]]; then
  log "**Verdict: FAIL** — fix failures before App Store submit."
  exit 1
else
  log "**Verdict: PASS** (with $WARN warnings) — simulator smoke tests OK."
fi
