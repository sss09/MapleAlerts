# 01 — MVP Definition (V1)

**Goal:** Ship a useful, focused app in ~4 weeks that nails the date-based alerts requiring no API and minimal content risk — in time to ride the **RRSP/tax-season search spike (Feb–Apr)**.

## The launch alerts (8)

All are date-based, simple, and need no real-time data. Seven were the original set; **Tax Filing Deadline is added** (highest-traffic seasonal keyword, hardcoded-simple, zero extra tech).

| # | Alert | Why it's V1 | Tier |
|---|-------|-------------|------|
| 1 | **RRSP contribution deadline** (~Mar 1) | Hardcoded date; flagship seasonal driver | Free |
| 2 | **TFSA new room** (Jan 1) | Simple math, no API | Free |
| 3 | **Tax filing deadline** (Apr 30 / Jun 15) | ⭐ Added — top search volume, hardcoded | Free |
| 4 | **Bank of Canada rate dates** | Hardcoded schedule (8/yr, announced ahead) | Free |
| 5 | **Canada Child Benefit payment dates** | Hardcoded payment schedule | Free |
| 6 | **GIC maturity reminder** | User enters date → done | Premium |
| 7 | **Mortgage renewal reminder** | User enters date → done | Premium |
| 8 | **OSAP grace-period end** | User enters grad date → done | Premium |

> **Anything to add/remove?** Recommendation: keep it at these 8. Resist adding more — discipline protects the 4-week timeline. FHSA annual room is the top candidate for a fast-follow (Phase 1.5) since it's simple and low-competition.

## Free vs Paid split (recommended)

The source brief contradicted itself ("5 free categories" vs "RRSP+TFSA only"). Recommended model gates **personalization and data-entry value**, not public information:

**Free**
- Broad date-based alerts everyone Googles: RRSP, TFSA room, Tax deadline, BoC dates, CCB/benefit payment dates
- Basic notifications
- *Drives habit, retention, and keyword ranking — the SEO flywheel*

**Premium — $2.99/mo or $19.99/yr**
- Personal trackers: GIC maturity, mortgage renewal, OSAP repayment
- Contribution-room calculators (RRSP/TFSA), HBP/FHSA tracking
- Life-events setup, historical alerts, personalized lead-times
- Calendar export, home-screen widget, **no ads**

**Family — $8.99/mo** (later)
- 2–5 members; shared RESP, spousal RRSP, joint mortgage renewal

> **Why not "RRSP+TFSA free only":** too stingy — it starves the SEO/retention flywheel that feeds the whole funnel. Gate stickier *personalized* features instead.

## Ads at launch: NO (recommendation)
The moat is **trust**. Banner ads cheapen a finance app and compete with higher-value, more-relevant affiliate placements. Lead with **affiliate + subscription**. Revisit ads only later, only non-intrusive. (See [03 — Monetization](03-monetization.md).)

## Tech for V1 (almost no backend)
- **Flutter** (already the codebase) — iOS/Android/Web from one source
- **flutter_local_notifications** — all date-based alerts work fully offline, no server
- **Local-first storage (SQLite)** — per the [architecture spec](../superpowers/specs/2026-05-31-maplealerts-architecture-design.md)
- **RevenueCat** — subscriptions/paywall (already integrated)
- **Affiliate links** = plain URLs via `url_launcher` (already a dependency)
- Firebase Auth/Firestore/FCM/Cloud Functions are **deferred to V2** (rate-tracking, sync, push)

## 4-week build plan
- **Week 1 — Onboarding + Profile:** province, situation, accounts (see [04](04-onboarding.md)); optional auth deferred (local-first).
- **Week 2 — Notification engine:** hardcoded Canadian financial calendar; local notifications; per-alert settings (which, how-far-ahead).
- **Week 3 — Alert screens + monetization:** tap notification → detail screen answering *What is this? Why does it matter? What should I do?*; affiliate CTAs; RevenueCat paywall for premium categories.
- **Week 4 — Polish + launch:** bug fixes, store screenshots, simple landing page, submit to stores.

## Success metrics (first 90 days)
- **Activation:** % who set ≥1 alert in first session (target > 70%)
- **Retention:** D30 retention (target > 25% — high for utility apps, driven by recurring alerts)
- **Conversion:** free→premium (target 2–4%)
- **SEO traction:** ranking movement on "RRSP/tax deadline Canada" keywords
- **Affiliate:** first referral conversions during RRSP/tax season

## Definition of done (V1)
- [ ] Onboarding personalizes the alert set
- [ ] All 8 alerts schedule correctly with configurable lead-times
- [ ] Each alert has a detail screen with a clear next action
- [ ] Premium paywall gates the 3 tracker alerts
- [ ] Affiliate CTAs present on relevant detail screens
- [ ] Shipped to App Store + Google Play
