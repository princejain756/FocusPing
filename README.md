# FocusPing

**Wrong-time notifications stop here.** Context-aware reminders for ADHD adults — a delivery gate, not a day planner.

## Market positioning (research-backed)

Planner apps like Tiimo get praise for visuals but frustrate ADHD users when:
- Reminders fire when you **can't act** (hyperfocus, wrong context)
- Tasks **vanish at midnight** instead of waiting patiently
- **Red overdue badges** and timers feel punishing, not supportive
- Rescheduling incomplete tasks is tedious one-by-one

**FocusPing's wedge:** deliver when you can act. Hold during Focus. Queue without guilt. **"I'm ready"** when *you* choose.

## What's in v1.4

- **App icon & launch screen** — placeholder brand icon installed (replace anytime)
- **Share FocusPing** from Settings
- **Duplicate ping** from long-press menu
- **App Store review prompt** after 8 completed pings (Apple HIG timing)
- **App Store metadata draft** in `AppStore/metadata.md`

## What's in v1.3

### Core differentiator
- **"I'm ready" card** — prominent when pings are queued; one tap delivers all
- **Queue never expires** — held pings stay until you release them

### UX & HIG patterns
- **Search pings** on home tab
- **Undo delete** (5-second banner, no "Are you sure?" dialogs)
- **Delivery window visual** in Settings
- **Help & Tips** sheet explaining the wedge vs planners
- **Onboarding copy** aligned with real user language from App Store reviews

### Previously shipped
- Focus hold, Deep Work, queue, widget, Live Activity
- Siri Shortcuts + home screen quick actions
- Edit pings, snooze (15m–3h), Reminders import
- History (Today / This week / Earlier), privacy manifest

## Website

Marketing site lives in **`website/`** (Astro, static, SEO-optimized).

```bash
cd website && npm run dev    # local preview
cd website && npm run build  # production build
```

Live URLs (after deploy):
- https://focusping.app
- https://focusping.app/privacy
- https://focusping.app/support

## Open in Xcode

1. Open **`FocusPing.xcodeproj`**
2. Set **Development Team** on FocusPing + FocusPingWidgetExtension
3. Enable **App Groups**: `group.com.focusping.shared`
4. Run (⌘R)

## Try the wedge

1. Add a ping → turn on **Deep Work** → ping queues
2. Tap **I'm ready — deliver now** on home screen
3. Delete a ping → tap **Undo** on the banner
4. Settings → **How FocusPing works**

## App Store keywords (suggested)

`ADHD reminders`, `focus mode`, `context aware`, `gentle reminders`, `no guilt`, `hyperfocus`, `delivery window`, `reminder gate`

## App icon

Placeholder icon is installed at `FocusPing/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024×1024).

**To replace with your final logo:** drop a 1024×1024 PNG with the same filename in Xcode's AppIcon asset, and update `LaunchBrand.imageset/LaunchBrand.png` to match.

## Before launch

- [ ] Replace placeholder icon with final logo (optional — placeholder works for TestFlight)
- [ ] Privacy policy URL — live at focusping.app/privacy after deploy
- [ ] Development Team + App Group in Developer portal
- [ ] Dogfood 30 days on real device
