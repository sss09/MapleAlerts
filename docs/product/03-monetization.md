# 03 — Monetization

The app can earn through several streams simultaneously. **Recommended sequencing matters** — lead with the streams that protect trust and compound the moat.

## Recommended priority order
1. **Affiliate referrals** — highest value, most relevant, reinforces "useful" positioning. Start day 1 (links are just URLs).
2. **Freemium subscription** — predictable MRR; gate personalization, not public info.
3. **B2B licensing** — high-margin, but needs traction first (Month 7+).
4. **Premium content/courses** — email-gated funnel; opportunistic.
5. **Ads** — ⚠️ **deferred / optional.** Only if needed, only non-intrusive. See warning below.

---

## Stream 1 — Freemium subscription
- **Free:** broad date-based alerts (RRSP, TFSA, tax, BoC, benefit dates), basic notifications.
- **Premium ($4.99/mo or $34.99/yr):** all categories, personalization, life events, historical alerts, calendar export, home-screen widget, no ads.
- **Family ($8.99/mo):** 2–5 members; shared RESP, spousal RRSP, joint mortgage renewal.
- Handled by **RevenueCat** (App Store + Google Play; ~1% vs building own billing).
- *Illustrative:* 10,000 subscribers × $5 ≈ $50,000/mo.

## Stream 2 — Affiliate referrals (passive, high value)
Triggered contextually by alerts. Examples:
- *"Your GIC matures in 30 days"* → best current GIC/HISA rates (EQ Bank, Oaken, Wealthsimple…) — **$25–100 / opened account**.
- *"RRSP deadline in 30 days"* → low-fee RRSP providers (Wealthsimple, TD e-Series, Questrade) — **$25–75**.
- *"Your mortgage renews in 4 months"* → rate comparison / broker referral (Ratehub, brokers) — **$200–800 / closed mortgage**.
- Credit cards, newcomer bank accounts — **$50–200**.

*Illustrative (per 10,000 users/mo):* GIC/HISA $15k + RRSP $7.5k + mortgage $20k + cards $7.5k ≈ **$50k/mo from affiliates alone.**

**Principles:** only surface affiliates where they're genuinely useful and timely; label clearly; never let affiliate placement override the user's best interest (trust = moat).

## Stream 3 — In-app advertising ⚠️ (deferred)
Financial audiences command high CPMs ($15–40 vs $2–5). **But:** ads cheapen a trust-based finance app and compete with higher-value affiliate slots.
- **Recommendation: do NOT launch with ads.** Revisit only after subscription + affiliate are established, and only with non-intrusive, clearly-separated placements. The "no ads" benefit is also a premium upsell.

## Stream 4 — B2B licensing (Month 7+)
Once there's traction and a proven engine:
- **Financial advisors:** white-label, $99–299/mo per advisor.
- **Credit unions:** license the alert engine, branded, $500–2,000/mo each.
- **HR / employer financial wellness:** $2–5/employee/mo.
- **Immigration settlement agencies:** newcomer clients, $50–200/mo each.

*Note:* B2B (white-label, multi-tenant) has real architectural implications — keep the alert engine cleanly separated (the repository + category-registry design already supports this) so licensing doesn't require a rebuild.

## Stream 5 — Premium content / courses (opportunistic)
- Alert-triggered education: *"Don't know what to invest your RRSP in? 20-min course $19.99."*
- Free email-gated mini-guides (*"RRSP vs TFSA: which first?"*) → build list → sell courses + relevant affiliates.

---

## Illustrative revenue potential
> Founder projections — directional, not committed targets.

**Conservative (Year 1, ~10K users):** subscription $15k + affiliate $20k + (ads $5k if enabled) ≈ **$40k/mo → ~$480k/yr**
**Optimistic (Year 2, ~50K users):** subscription $75k + affiliate $100k + B2B $25k + ads $20k ≈ **$220k/mo → ~$2.6M/yr**

## Guardrails
- **Trust first.** Any monetization that erodes perceived objectivity costs more than it earns.
- **Relevance over volume.** A timely, relevant affiliate beats five banner ads.
- **Transparency.** Disclose affiliate relationships.
