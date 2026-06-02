# GIC → Best Move — slice design

**Date:** 2026-06-02
**Status:** Approved (auto-mode) — building
**Builds on:** best-move + topics gate. Realizes the strategy's flagship cross-product move.

## Decisions
- **Single tracked GIC via the profile** (not the orphaned V1 multi-GIC SQLite
  table) — `gicAmount` + `gicMaturityDate` on `MoneyProfile`. Multi-GIC is a
  later enhancement.
- **Shelter target: TFSA first, then RRSP** when a GIC is maturing and there's room.

## Engine
- `domain/gic_holding.dart`: `GicResult` + `GicStatus { none, later, maturingSoon, matured }`, `daysToMaturity`.
- `rules/gic_rule.dart`: `gicRule(profile, asOf)` — date math; `maturingSoon` when 0 ≤ days ≤ 60.
- `MoneyProfile` += `double? gicAmount`, `DateTime? gicMaturityDate` (json: ISO string; copyWith/==/hash).
- **`best_move_rule`** new cascade rung (after over-contribution guardrails,
  before the RRSP deadline tier): a GIC maturing within 60 days **and** TFSA or
  RRSP room available → `BestMoveKind.deadline`, "Shelter your maturing $X GIC
  into your TFSA" (RRSP fallback). `dollarValue = min(gicAmount, targetRoom)`,
  `targetInsightId = 'tfsa_room' | 'rrsp_room'`. Requires the target topic
  configured (to know room); otherwise skipped.

## App
- `gicInsights` mapper (→ generic `InsightCard`; MoneyInsight unchanged a 7th time):
  setup (no input) → CTA `editGicProfile`; `matured` → info ("matured — reinvest/shelter");
  `maturingSoon` → foundMoney ("Your $X GIC matures in N days"); `later` → info (matures {date}).
- `gicInsightsProvider` into `moneyInsightsProvider`.
- `MoneyTopic.gic` (opt-in) + `GicSetupSheet` (amount + date picker) + `editGicProfile`
  routed in `FoundMoneySection` and `BestMoveCard` switches.

## Testing (TDD)
- `gic_rule`: none / later / maturingSoon (≤60d boundary) / matured; daysToMaturity.
- best-move: maturing GIC + TFSA room → shelter-into-TFSA move (value = min); RRSP
  fallback when no TFSA room; skipped when no room/topic configured; still ranks
  below over-contribution guardrails.
- `gicInsights` mapper: each status → kind; setup when no input.

## Out of scope
Multiple GICs, GIC interest/maturity-value math, auto-reminders for maturity
(reminders engine already covers dates), web SQLite.
