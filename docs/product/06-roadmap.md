# 06 — Roadmap

## Phased build

### V1 (≈4 weeks) — Ship the date-based core
The 8 MVP alerts (see [01](01-mvp.md)): RRSP deadline, TFSA room, **Tax filing deadline**, BoC dates, CCB dates, + GIC/mortgage/OSAP trackers. Local notifications, no backend. RevenueCat paywall. Affiliate CTAs.
**Why first:** simple, no API, rides the RRSP/tax-season search spike.

### V2 (Weeks 5–8) — Rates & more trackers
- Rate tracking (BoC + HISA rates) — *first real backend*: a daily Cloud Function scrapes public rate pages; push via FCM to opted-in users. (BoC *dates* stay hardcoded — announced a year ahead.)
- Expand trackers + benefits content: GST/HST credit, Trillium, Climate Action Incentive, Canada Workers Benefit, OAS/CPP windows, BC/AB child benefits, RESP CESG.
- **FHSA** annual room (fast-follow candidate from V1.5).

### V3 (Weeks 9–12) — Personalization depth
- **Life-events flow** ("I had a baby" → bundle of alerts) — see [catalog §11](02-alert-catalog.md).
- RESP CESG calculator · home-screen widget · optional Q&A ("What does this mean?") via a cheap LLM (Gemini Flash / Groq free tier).
- Optional account + cloud sync (architecture already supports a `SyncedReminderRepository`).

## Backend evolution
| Phase | Backend |
|-------|---------|
| V1 | None — local notifications + SQLite; affiliate = URLs; RevenueCat |
| V2 | Firebase: Firestore (prefs/profile sync), Cloud Functions (daily rate scrape + scheduled push), FCM |
| V3+ | Remote config for content-as-data; B2B multi-tenant considerations |

Cost stays low: Firebase free tiers cover ~10K users (Functions 2M invocations/mo free); est. ~$0–30/mo at that scale.

## Where simple AI helps (optional, later)
- Notification-attached tips · "RRSP vs TFSA?" Q&A · "what does trigger rate mean?"
- Use Gemini Flash / Groq free tier → ~$0. **Not required for core value.**

## Year-1 timeline (founder projection — directional)
| Month | Focus | Downloads | Revenue (sub + affiliate) |
|-------|-------|-----------|---------------------------|
| 1 | Build V1 | — | $0 |
| 2 | Launch · Reddit + Twitter | 0.5–2K | $0.2–1K |
| 3 | **RRSP season spike (Feb–Mar)** ← launch window | 5–15K | $4–10K |
| 4 | Add V2 (GIC, mortgage, rates) | growing | $10–20K |
| 5–6 | **Tax season spike (Apr)** | growing | $10–20K |
| 7–8 | Add B2B (advisors, credit unions) | — | $15–30K |
| 9–10 | BoC rate-cut news cycle | — | $20–40K |
| 11–12 | Build toward 2nd RRSP season | 10× users | $30–60K |
| **Total** | | | **$150–400K** |

## Marketing (free channels)
- **Reddit** (high intent): r/PersonalFinanceCanada, r/CanadianInvestor, r/FirstTimeHomeBuyer, r/OSAP, provincial subs. Lead with genuine value ("every Canadian financial deadline in 2026"), link naturally.
- **Twitter/X:** pre-BoC summaries, RRSP/tax countdowns — shareable.
- **TikTok/Instagram Reels:** "5 TFSA mistakes," "OSAP repayment starts in 6 months."
- **YouTube (long-term SEO):** "TFSA vs RRSP 2026," "OSAP repayment explained."
- **Newsletter (Beehiiv free ≤2,500):** monthly "Canadian financial dates this month" → upgrade + affiliate.
- **Seasonal PR:** pitch journalists during RRSP (Feb–Mar), tax (Apr), OSAP (Aug–Sep), and BoC cycles — be the "what does this mean?" source.

## Moat-building priorities (do early — they take longest)
1. **Content accuracy** (federal + provincial, annually updated)
2. **SEO** (6–12 months to rank)
3. **Affiliate relationships** (3–6 months of approvals)
4. **Trust/reviews** (compounds from day 1 — hence no intrusive ads)
