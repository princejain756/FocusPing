# FocusPing — Launch Checklist

Preflight audit as of v1.4. **Code is feature-complete for a v1 TestFlight wedge.** What remains is mostly Apple account setup, legal pages, assets, and validation — not app logic.

---

## Preflight summary

| Status | Count | Meaning |
|--------|-------|---------|
| ✅ Shipped in code | 28 | Ready in the build |
| ⚠️ You must do (Apple account) | 8 | Blocks TestFlight / App Store |
| ⚠️ You must do (content/legal) | 5 | Blocks App Store review |
| 🔮 v2 (optional, post-launch) | 12 | Not required for v1 |

---

## ✅ Done — in the codebase

### Product (Focus Gate wedge)
- [x] Hold pings during system Focus + manual Deep Work
- [x] Queue (pings never expire at midnight)
- [x] **I'm ready** — deliver all when user chooses
- [x] No streaks, no red overdue, guilt-free copy
- [x] Quick templates (meds, water, leave, message, etc.)
- [x] Add / edit / duplicate / search / undo delete
- [x] Snooze 15m → 3h
- [x] Import from Apple Reminders (one-way)
- [x] History grouped (Today / This week / Earlier)
- [x] Delivery window + visual timeline

### System integration
- [x] Local notifications + Done / Snooze actions
- [x] Focus Status API
- [x] Background refresh (BGTaskScheduler)
- [x] Home screen widget (small / medium / lock screen)
- [x] Live Activity + Dynamic Island
- [x] Siri App Shortcuts (Deep Work, Add Ping)
- [x] Home screen quick actions (long-press icon)
- [x] App Group sync (app ↔ widget)

### UX / HIG
- [x] Onboarding (3 screens, skip, inline permission CTAs)
- [x] Help & Tips sheet
- [x] In-app banners + undo delete
- [x] Share FocusPing
- [x] Review prompt after 8 completions (SKStoreReviewController)
- [x] Dark mode adaptive colors
- [x] 44pt touch targets, swipe actions, thumb-zone FAB

### App Store prep (in repo)
- [x] Privacy manifest — main app (`PrivacyInfo.xcprivacy`)
- [x] Privacy manifest — widget extension
- [x] Export compliance flag (`ITSAppUsesNonExemptEncryption = false`)
- [x] Placeholder app icon 1024×1024 + launch brand
- [x] Metadata draft (`AppStore/metadata.md`)
- [x] Usage strings: Focus Status, Reminders, Live Activities

### Build
- [x] Xcode project builds (iOS 17+, iPhone + iPad targets)
- [x] Version 1.4 (`MARKETING_VERSION`)

---

## ⚠️ Blockers — you must do (Apple Developer)

These cannot be done in code. **Required before TestFlight on a real device.**

| # | Task | Why | How |
|---|------|-----|-----|
| 1 | **Set Development Team** | Signing fails on device | Xcode → FocusPing + FocusPingWidgetExtension → Signing & Capabilities → Team |
| 2 | **Register App Group** | Widget/Live Activity sync breaks on device | [developer.apple.com](https://developer.apple.com) → Identifiers → App Groups → `group.com.focusping.shared` → attach to both bundle IDs |
| 3 | **Create App ID** | Provisioning | `com.focusping.app` + `com.focusping.app.widget` with App Groups + Push (if needed) |
| 4 | **Create app in App Store Connect** | TestFlight / release | App Store Connect → New App → bundle `com.focusping.app` |
| 5 | **Upload first build** | TestFlight | Archive in Xcode → Distribute → App Store Connect |
| 6 | **Internal TestFlight** | Real-device validation | Add yourself as tester; dogfood 2–4 weeks minimum |
| 7 | **Focus Status entitlement** | May need Apple approval for Focus API | Usually automatic with capability; verify on device |
| 8 | **Reminders permission** | Import only works with grant | Test import flow on device after install |

---

## ⚠️ Blockers — content & legal (App Store review)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | **Privacy Policy URL (live)** | ❌ Placeholder | Settings links `focusping.app/privacy` — must be a real page before submission |
| 2 | **Support URL (live)** | ❌ Placeholder | `focusping.app/support` in metadata draft |
| 3 | **App Store screenshots** | ❌ Not created | 6.7", 6.5", 5.5" iPhone + optional iPad. Use captions in `metadata.md` |
| 4 | **Final app icon** | ⚠️ Placeholder OK for TestFlight | Replace `AppIcon.appiconset/AppIcon.png` when your logo is ready |
| 5 | **App Privacy questionnaire** | ❌ Not filled | App Store Connect → App Privacy → "No data collected" (matches privacy manifest) |

### Privacy Nutrition Label (expected answers)
- Data collection: **None**
- Tracking: **No**
- Third-party SDKs: **None**
- Reminders data: stays on device, not uploaded

---

## ⚠️ Warnings — should fix before public launch

| # | Issue | Risk | Fix |
|---|-------|------|-----|
| 1 | **No automated tests** | Regressions on changes | Add unit tests for `PingStore`, `DeliveryWindow`, `shouldHoldDelivery` |
| 2 | **Focus polled every 12s while app open** | Battery (minor) | Acceptable v1; v2 could use Focus Status notifications if Apple adds them |
| 3 | **iPad layout unoptimized** | Looks like stretched iPhone | v1 OK; v2 split view / wider stats row |
| 4 | **No localization** | English only | v1 OK for wedge; add later if targeting EU |
| 5 | **share link `focusping.app`** | 404 until you own domain | Use TestFlight link for beta shares |
| 6 | **Widget dark mode gradient** | Hardcoded light gradient in widget | Cosmetic; update `FocusPingStatusWidget` for dark |
| 7 | **No crash reporting** | Blind to production crashes | Optional: Xcode Organizer or Sentry post-launch |
| 8 | **Accessibility audit** | VoiceOver / Dynamic Type edge cases | Run `swiftui-wcag-accessibility-auditor` pass on device |

---

## 🔮 v2 backlog — not needed for v1 launch

Prioritized by market research (ADHD planner pain vs FocusPing wedge):

| Priority | Feature | Why |
|----------|---------|-----|
| P1 | **30-day dogfood journal** | Validate wedge beats Reminders+alarms before marketing |
| P1 | **App Store screenshots** (automated or manual) | Conversion |
| P2 | **Apple Watch complication** | Glance queue count + Deep Work |
| P2 | **Bidirectional Reminders sync** | High effort; import is enough for v1 |
| P2 | **Notification snooze 1h action** | Second notification category action |
| P3 | **Pin / priority pings** | Power user |
| P3 | **iPad-optimized layout** | Universal app polish |
| P3 | **Localization** (ES, DE) | Growth |
| P3 | **Monetization** (tip jar / Pro) | Only after retention proof |
| P3 | **Onboarding video** | App Preview for App Store |
| P3 | **Control Center toggle** | Deep Work from Control Center |
| P3 | **HealthKit / medication** | Regulatory scope creep — avoid v1 |

---

## Test plan before you submit

Run on a **physical iPhone** (simulator cannot fully test Focus Status, widgets, Live Activity feel):

```
[ ] Fresh install → onboarding → grant Notifications
[ ] Grant Focus Status → verify badge shows "In Focus" when Focus on
[ ] Add ping → Deep Work ON → ping lands in Queue (not notification)
[ ] Deep Work OFF → "I'm ready" → notification fires
[ ] Widget shows queue count; medium widget Deep Work button works
[ ] Live Activity on lock screen when queue > 0
[ ] Siri: "Start Deep Work in FocusPing"
[ ] Long-press icon → Add Ping
[ ] Import 3 Reminders
[ ] Complete ping from notification action "Done"
[ ] Snooze from notification
[ ] Delete ping → Undo banner
[ ] Airplane mode → queue still visible (local data)
[ ] Kill app → reopen → state restored (SwiftData)
```

---

## App Store Connect checklist (submission day)

```
[ ] Version 1.4 build uploaded and processed
[ ] Screenshots uploaded (all required sizes)
[ ] Description + subtitle pasted from AppStore/metadata.md
[ ] Keywords (100 chars max)
[ ] Category: Productivity (+ Health & Fitness secondary)
[ ] Age rating questionnaire completed
[ ] App Privacy = no data collected
[ ] Privacy Policy URL live
[ ] Support URL live
[ ] Review notes: "Focus Status used to hold reminders during Focus. 
    Reminders import is optional. No account required."
[ ] Demo account: N/A (no login)
[ ] Export compliance: No encryption beyond HTTPS (already in Info.plist)
```

---

## Verdict

**Nothing critical is missing from the app code for a v1 TestFlight build.**

What is left is:

1. **Your Apple Developer setup** (team, app group, signing)
2. **Your final logo** (placeholder works until then)
3. **Live privacy + support pages**
4. **Screenshots + App Store Connect listing**
5. **Real-device dogfooding** (~30 days to validate the wedge)

When your logo is ready, send the 1024×1024 PNG. When your domain is ready, update URLs in Settings + metadata. The app itself is **ready to archive**.

---

## File map

| Path | Purpose |
|------|---------|
| `FocusPing.xcodeproj` | Open in Xcode |
| `AppStore/metadata.md` | Copy-paste listing copy |
| `AppStore/LAUNCH_CHECKLIST.md` | This file |
| `FocusPing/Assets.xcassets/AppIcon.appiconset/` | Replace icon here |
| `FocusPing/PrivacyInfo.xcprivacy` | Main app privacy manifest |
| `FocusPingWidget/PrivacyInfo.xcprivacy` | Widget privacy manifest |
