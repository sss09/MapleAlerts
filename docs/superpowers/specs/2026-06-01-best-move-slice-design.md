# Best Move Right Now — slice design

**Date:** 2026-06-01
**Status:** Approved (auto-mode dev day) — building
**Builds on:** TFSA + RRSP + CCB rules + topics gate. The flagship phase-4 differentiator.

## Goal
Surface ONE proactive, deterministic, rule-based recommendation that reasons
*across* the user's accounts — answering the "what should I actually do?" /
"RRSP vs TFSA?" questions in context, no AI.

## Key architecture decision
Best-move is **engine-level logic over the typed rule results** (`TfsaRoomResult`,
`RrspResult`), NOT over the presentation `MoneyInsight` view-models (which are
lossy — tax savings/deadline live in copy, not fields). This is exactly why the
earlier design kept best-move reasoning in the engine. **`MoneyInsight` stays
unchanged a 4th time.**

## Engine
```
domain/best_move.dart   // BestMove model + BestMoveKind
rules/best_move_rule.dart // bestMove(profile, asOf, dataPack) -> BestMove?
```
`BestMoveKind { fixGuardrail, deadline, opportunity }`.
`BestMove { kind, title, detail, double? dollarValue, String? targetInsightId,
List<FigureSource> sources, bool isEstimate }`. `targetInsightId` is
`'rrsp_room'`/`'tfsa_room'` so the app maps it to a setup action via
`MoneyTopic.fromInsightId` (engine stays free of presentation enums). Returns
`null` when nothing is actionable.

`bestMove` runs the TFSA + RRSP rules and only considers a topic when it's
configured (`birthYear`+`tfsaContributed` for TFSA; province+income+limit+
contributed for RRSP). CCB is excluded — it's automatic money, not an action.

### Deterministic priority cascade
1. **RRSP over-contribution** → `fixGuardrail`, value = overage (penalty accruing).
2. **TFSA over-contribution** → `fixGuardrail`, value = overage.
3. **RRSP deadline ≤ 60 days** with room > 0 and tax savings > 0 → `deadline`,
   value = estimated tax savings.
4. **Opportunity tie-break (RRSP vs TFSA):**
   - RRSP room > 0 AND marginal rate ≥ `kRrspPreferredMarginalRate` (0.30) →
     RRSP, value = tax savings. ("At your income, RRSP beats TFSA.")
   - else TFSA room > 0 → TFSA, value = room. ("Shelter $X tax-free.")
   - else RRSP room > 0 → RRSP, value = tax savings.
5. else `null`.

Every `BestMove` carries `sources` explaining *why it won* (e.g. "Marginal rate
~32% · RRSP saves more than TFSA at your income", "RRSP deadline Mar 2 2027").

## App
- `bestMoveProvider` (Provider<BestMove?>) over the current profile + EmbeddedDataPack.
- `BestMoveCard` — prominent accent-gradient card, pinned at the TOP of Home
  (above Found money). Shows kind eyebrow ("YOUR BEST MOVE"), title, detail,
  the dollar value, a "How we decided" expansion (sources), estimate/not-advice
  framing, and a CTA that routes via `targetInsightId → MoneyTopic.setupAction`
  to the relevant sheet. Hidden when `bestMove == null`.
- Wired into `HomeScreenV2` between the hero and Found money.

## Edge cases
- Nothing configured / no room / no guardrail → `null` → card hidden (the
  get-started card already drives setup).
- Over-71 (RRSP noLongerEligible) → RRSP branches skipped.
- Engine total; no throws.

## Testing (TDD)
`bestMove`: RRSP over-contribution → fixGuardrail; near-deadline (asOf in Feb)
with room → deadline; high marginal rate → RRSP opportunity; low marginal rate →
TFSA opportunity; nothing configured → null; all maxed → null. Plus the
ordering (guardrail beats deadline beats opportunity). Widget: BestMoveCard
renders title + value and hides on null.

## Out of scope
GIC-maturity / cross-product moves (needs GIC wired into the engine/profile),
multi-move ranking lists (only the single top move), CCB as an action.
`kRrspPreferredMarginalRate` is a documented, tunable heuristic, framed as
guidance + "how we decided", not financial advice.
