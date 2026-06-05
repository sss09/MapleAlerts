# MapleAlerts — "Canadian Money Co-Pilot" Strategy & Reframe

**Date:** 2026-06-01
**Status:** Approved (strategy brainstorm)
**Supersedes/extends:** the deadline-hub framing in [00-vision](../../product/00-vision.md). MapleAlerts is the **foundation of a chain** of Canadian apps (see [CanDoc thesis](#ecosystem-foundation)).

## Problem
A generic reminder app makes the *user* do the work and is undifferentiated. Reminders alone won't win attention or trust. Our unfair advantage: **we know the Canadian rules**, so we can do the work *for* the user — compute, surface money they're owed, prevent costly mistakes, and explain the jargon — all from **free, deterministic data with zero AI token cost**. AI is reserved for premium.

## Positioning (the reframe)
**MapleAlerts is a Canadian *money co-pilot*, not a reminder app.** Reminders are one pillar.
- Promise: *"Know your deadlines, find your money, understand the rules — the Canadian-specific stuff no US app gets."*
- Tagline: **"Your Canadian money, handled."**
- Emotional shift: from *"don't forget"* → *"you're not leaving money on the table, and you won't get penalized."*

## Differentiators (NOT "calculators" — math is invisible plumbing)
Generic TFSA/RRSP calculators are a commodity; we never ship a "calculator screen." Instead:

1. **🛡️ Penalty guardrails (unique + emotional).** Track contributions vs. room → warn *before* the CRA penalizes: *"One more $1,000 over-contributes your TFSA (1%/mo penalty)."* (74,000 over-contribution notices/yr.) Protective, not a tool. **Never gated.**
2. **🎯 "Best move right now" (cross-account reasoning).** One proactive, rule-based recommendation connecting things siloed tools don't: *"GIC matures in 30 days + $14k TFSA room → shelter it"*; *"RRSP deadline in 12 days; at your income $5k saves ≈$1,750 — beats TFSA now."* This answers the RRSP-vs-TFSA decision people Google, **in context, no AI.**
3. **💰 Found money.** Quantified dollar cards: unused TFSA/RRSP room, CCB estimate, Canada Carbon Rebate amount, OAS clawback proximity.
4. **🔗 Whole-life reasoning** across deadlines + accounts + benefits + rates together.
5. **📍 Province- & life-stage-aware** (vs. generic "Canada" tools).

Supporting layers: **live rates** (BoC/prime via free Valet API, GIC/HISA list), **know-your-rights explainers** (static, province-aware), and the existing **reminders** engine.

## Canadian Data Engine (shared foundation)
- **On-device rules + math** (embedded, versioned): TFSA limit table, RRSP %/caps, federal+provincial tax brackets, CCB formula, carbon-rebate amounts, OAS thresholds, HST rates, CRA payment-date schedules. Local compute → instant, offline, **zero token cost**.
- **One hosted JSON "data pack"** (static file, ~$0 infra) the app fetches + caches: yearly/quarterly-changing values (current limits, benefit amounts, GIC/HISA list, rate snapshots). Update a number → all users get it, **no app release**.
- **BoC policy/prime rate** via the **free official Bank of Canada Valet API** (client-side, no backend).
- Realizes the earlier **content-as-data** decision; structured as a **standalone module** so every future app imports the same engine.

## UX & trust
- **Hybrid input:** onboarding profile (province + accounts/situation/life-stage) decides *which* cards appear; each card asks inline for the one number it needs.
- The "Your day, handled" hero evolves to summarize **deadlines + found money + the one best move**.
- **Trust mechanics (critical):** every figure labeled an **estimate** with a **"How we got this"** expansion (formula + rule/source, e.g. "2025 TFSA limit $7,000 · CRA"); province + year stamped; **"informational, not financial advice"** footer; conservative math.

## Free vs Pro (governing rule, sharpened 2026-06-05)
> **If a feature drives affiliate clicks → Free.** If it deepens the personal picture → Pro. If it prevents a CRA penalty → Free, always. Rate intelligence is an affiliate driver — never gate it.

- **Free:** deadlines · found money · guardrails · "best move" · live rates · **rate gap card** ("you're losing $X/yr at your bank") · HISA/GIC **rates sheet** · contextual affiliate CTAs in insight cards · BoC rate-impact card · Maple Wrapped · all province/profile personalization. Generous → affiliate conversions + word-of-mouth + SEO.
- **Pro ($2.99/mo · $19.99/yr):** year-end optimizer · RRSP-vs-TFSA deep comparison (side-by-side with their numbers) · partner/spouse account tracking · net-worth history + chart · contribution pace tracker · PDF year summary · **personalised paywall** (surfaces their actual numbers — high conversion) · no ads.
- **AI (within Pro):** CRA-letter explainer, deep personalized advice, draft response letters.
- **Principle:** never gate guardrails or deadlines. *(Repriced 2026-06-05 from $4.99; no free trial.)*

## Ecosystem foundation
MapleAlerts is app #1 of a Canadian chain (CanDoc thesis — directional, not literal). The shared **data engine + design system + brand** are built once here and lifted into siblings (CRA-letter explainer, HST invoicing, tenant rights, mortgage-renewal coach). Audience flywheel: acquire free on MapleAlerts → in-app cross-promo → each app markets the others. SEO clusters per app aggregate under one brand. **Action:** keep the data engine a standalone module from day one.

## Phased build (additive to what's shipped: Aurora UI, reminders, profile)
1. **Canadian Data Engine** — embedded rules + math + hosted JSON pack loader + BoC Valet client.
2. **First found-money + guardrail cards** — TFSA room (+ over-contribution guardrail), RRSP room (+ tax-saving + deadline best-move).
3. **BoC/prime rate live card** + carbon-rebate amount by province.
4. **"Best move right now"** home surface.
5. Explainers + remaining found-money (CCB, OAS clawback) + more guardrails.
6. *(Later/Premium)* AI CRA-letter explainer → the bridge to app #2.

## Consequences
- **Positive:** genuine differentiation (guardrails + best-move), trust-first, $0 marginal cost, reusable engine seeds the whole chain.
- **Costs:** getting Canadian rules right is real research (the moat); estimates need careful trust framing + disclaimers; expands MapleAlerts' surface (mitigated: phased, additive).
