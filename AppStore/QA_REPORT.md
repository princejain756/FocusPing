# FocusPing QA Report — Simulator

**Run date:** 2026-06-14  
**Device:** iPhone 16 Simulator (iOS 18.6)  
**App version:** 1.5  
**Script:** `scripts/simulator-qa.sh`

## Verdict: PASS (simulator)

15 checks passed, 0 failed, 3 warnings (website domain).

---

## What was tested

### Build & install
- Clean build via `xcodebuild` — **PASS**
- Fresh install on simulator — **PASS**

### UI screens (launch + screenshot, no crash)
| Screen | Result |
|--------|--------|
| Onboarding | PASS — first-run carousel renders |
| Home | PASS — 3 active pings, Deep Work toggle, tab bar |
| Queue | PASS — 3 held pings, "I'm ready" button, badge count |
| Settings | PASS — delivery window, links section |

All four screenshots are visually distinct (not duplicates).

### Fresh onboarding
- Cold launch after uninstall — **PASS** (no crash in console log)
- Onboarding page 1 visible with Continue button — **PASS**

### Runtime stability
- 10 seconds idle on Home screen — **PASS** (no crash in FocusPing logs)

### Delivery logic (`-QATest` harness)
| Test | Result |
|------|--------|
| Future scheduled ping does NOT queue immediately | PASS |
| Immediate ping during Deep Work queues | PASS |
| "I'm ready" / releaseAll clears queue | PASS |
| Snooze removes from queue + schedules future dueAt | PASS |

---

## What could NOT be tested (limitations)

### Physical iPhone
Both connected devices show **offline/unavailable** in `devicectl`:
- Prince Jain's iPhone (iPhone 11)
- prince's iPhone (iPhone 17,2)

**Action needed:** Plug in your iPhone, trust the Mac, and run TestFlight build for real-device notification + Focus Status testing.

### Tap-through UI automation
macOS accessibility tools (Peekaboo) only see the **Simulator chrome** (Volume, Sleep buttons), not buttons inside the simulated app. iOS Simulator does not expose in-app UI to external automation without XCTest/idb.

Logic tests use an in-app `-QATest` harness instead of manual taps.

### Not covered on simulator
- System Focus mode integration (requires real Focus Status entitlement + device)
- Notification delivery while app is killed
- Live Activity on lock screen
- Widget on home screen
- Reminders import permission flow
- Settings → Privacy/Support links (need live website)

---

## Website warnings

| URL | Status |
|-----|--------|
| https://focusping.prince.sh | 404 — domain not linked to Vercel project |
| https://focusping.prince.sh/privacy | 404 |
| https://focusping.prince.sh/support | 404 |

Add `focusping.prince.sh` in Vercel → website project → Domains.

---

## How to re-run

```bash
./scripts/simulator-qa.sh
```

Results written to `AppStore/QA_REPORT.md` and screenshots to `.qa-logs/`.

---

## Recommended before App Store submit

1. Link `focusping.prince.sh` on Vercel
2. Install TestFlight build on a **physical iPhone**
3. Manual checklist on device:
   - Complete onboarding + grant notifications
   - Add ping due in 2 minutes → enable Deep Work → verify it queues
   - Tap "I'm ready" → notification delivers
   - Tap notification → opens Queue tab
   - Settings → Privacy Policy opens in Safari
