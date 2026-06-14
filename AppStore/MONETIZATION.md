# FocusPing — Monetization Strategy

## Recommendation: Launch free, monetize after retention proof

FocusPing is a **wedge product** (delivery gate for ADHD adults). Monetizing too early kills the trust positioning ("no guilt, no streaks"). Ship v1 **free**, validate 30-day retention, then add **FocusPing Pro**.

---

## Phase 1 — v1.0 launch (now)

**Price:** Free  
**Goal:** Prove the wedge beats Reminders + alarms for ADHD users

| Free forever (core wedge) | Why free |
|---------------------------|----------|
| Hold during Focus / Deep Work | Core promise — must not paywall |
| Queue + I'm ready | Core promise |
| Up to **20 active pings** | Generous enough to dogfood; caps abuse |
| Widget + Live Activity | Discovery / habit |
| Siri shortcuts | Acquisition |
| Reminders import (one-way) | Stack integration hook |

No ads. No data selling. Trust is the product.

---

## Phase 2 — FocusPing Pro (after ~500 weekly actives OR 8 weeks dogfood)

**Model:** Subscription (Apple IAP)  
**Price target:** **$2.99/month** or **$19.99/year** (~44% annual discount)  
**Alternative:** **$4.99 one-time lifetime** for launch promo (simpler, lower LTV)

### Pro features (paywall what power users want, not the wedge)

| Pro feature | Free tier | Pro |
|-------------|-----------|-----|
| Active pings | 20 | Unlimited |
| Delivery windows | 1 global window | Per-ping + multiple windows |
| Reminders sync | Import only | **Bidirectional** sync |
| Apple Watch | — | Complication + glance queue |
| Custom snooze presets | 15m–3h fixed | Custom intervals |
| Ping templates | 5 built-in | Custom template library |
| History retention | 30 days | Unlimited |
| Priority support | Email | WhatsApp priority |

**Never paywall:** Deep Work, queue, I'm ready, Focus hold, undo delete.

---

## Phase 3 — Expansion (6–12 months)

| Revenue line | Notes |
|--------------|-------|
| **Family plan** | $4.99/mo for 5 seats — ADHD households |
| **B2B / coach licenses** | ADHD coaches prescribe FocusPing to clients |
| **Tip jar** | Settings → "Support development" (StoreKit consumable) |
| **Affiliate** | Tiimo/Opal alternative content — careful with brand |

---

## Why subscription over one-time

- Ongoing value: sync, watch, cloud backup (future)
- Apple favors subscription apps in productivity
- ADHD users who rely on the app have high willingness to pay **if** it works

## Why NOT ads or data

- ADHD audience is sensitive to distraction and trust
- Privacy manifest says no collection — keep that true
- Ads destroy "calm delivery gate" positioning

---

## Implementation order (when ready)

1. **StoreKit 2** — `SubscriptionManager`, `ProGate` helper
2. **Paywall screen** — after 20th ping or Settings → Upgrade
3. **App Store Connect** — subscription group "FocusPing Pro"
4. **A/B** — annual default vs monthly default
5. **Review notes** — explain free tier is fully functional wedge

**Do not implement IAP in v1.0 submit** unless you want review delay + pricing decisions before validation.

---

## Revenue math (illustrative)

| Scenario | Paid subs | Monthly revenue |
|----------|-----------|-----------------|
| Conservative | 2% of 1,000 WAU × $2.99 | ~$60/mo |
| Moderate | 5% of 5,000 WAU × $2.99 | ~$750/mo |
| Strong | 8% of 20,000 WAU × $2.99 | ~$4,800/mo |

ADHD productivity niche can support this **if** retention is strong. Tiimo proves people pay for ADHD-friendly tools.

---

## App Store copy (when Pro launches)

**Subtitle:** Remind when you can act  
**Pro line:** "Upgrade for unlimited pings, Watch glance, and Reminders sync."

---

## Decision for today

✅ **Submit v1 free**  
⏳ **Add Pro in v1.5** after TestFlight dogfood confirms retention  
📊 **Track:** D7 retention, pings/week, queue release rate, Pro interest survey in Settings
