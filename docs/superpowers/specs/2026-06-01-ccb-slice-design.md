# CCB Slice — Canada Child Benefit monthly estimate (found money)

**Date:** 2026-06-01
**Status:** Approved (auto-mode dev day) — building
**Builds on:** TFSA + RRSP slices. Third engine rule; reuses the card/sheet/insight template.
**Context:** Replaces the originally-planned Carbon Rebate card — the Canada Carbon
Rebate for individuals is **closed** (final payment Apr 15 2025), so a carbon
found-money card would be inaccurate. CCB is current and active.

## Goal
A "found money" card estimating the household's **monthly Canada Child Benefit**
from family net income + children by age band. Federal, province-agnostic.

## Data (verified vs CRA, July 2025–June 2026 benefit year, 2024 base year)
- Max **under 6**: $7,997/yr ($666.41/mo). Max **6–17**: $6,748/yr ($562.33/mo).
- Thresholds: AFNI ≤ **$37,487** → full; **$37,487–$81,222** → Step 1;
  > **$81,222** → Step 2.
- Step-1 reduction rate by child count: 1→7%, 2→13.5%, 3→19%, 4+→23%.
- Step-2 additional rate: 1→3.2%, 2→5.7%, 3→8%, 4+→9.5%, applied to AFNI over
  $81,222, **plus** a base = step1Rate × ($81,222 − $37,487) (computed, not
  transcribed, to avoid drift).
- Source: CRA CCB calculation sheet (Jul 2025–Jun 2026). Version-stamped
  `kCcbDataPackVersion`. The reduction *rates* are long-stable; max amounts +
  thresholds index each July (re-verify at the next benefit year).

## Rule
```
base       = under6 × maxUnder6 + age6to17 × max6to17
childCount = under6 + age6to17
reduction  = AFNI ≤ t1 ? 0
           : AFNI ≤ t2 ? step1Rate(count) × (AFNI − t1)
           : step1Rate(count) × (t2 − t1) + step2Rate(count) × (AFNI − t2)
annual     = max(0, base − reduction)
monthly    = annual / 12
```
`CcbStatus`: `notEligible` (childCount == 0), `zeroByIncome` (kids but annual == 0),
`receiving` (annual > 0). `CcbResult`: monthly, annual, under6, age6to17,
childCount, afni, sources, isEstimate.

## Profile additions
`int? kidsUnder6`, `int? kids6to17`, `double? familyNetIncome` (AFNI — distinct
from the RRSP individual `annualIncome`). JSON/copyWith/provider setter
`setCcbInputs`. No store changes.

## Insight mapping (MoneyInsight unchanged again)
- `!hasRequiredInput` (familyNetIncome or either count null) → setup insight,
  CTA `editCcbProfile`.
- `notEligible` → info ("CCB is for children under 18").
- `zeroByIncome` → info ("At your family income, CCB phases out to $0").
- `receiving` → foundMoney positive, headline "≈$X/month in Canada Child Benefit",
  amount = monthly, subline annual total + "tax-free", sources.

## Wiring
`ccbInsights` mapper (TDD) + `ccbInsightsProvider`; add to `moneyInsightsProvider`
(now TFSA + RRSP + CCB). `CcbSetupSheet` (two kid-count steppers + family net
income) + `InsightAction.editCcbProfile` routing in `FoundMoneySection`.

## Known UX debt (documented, not fixed here)
New users now see **three setup prompts** (TFSA, RRSP, CCB) — and CCB is
irrelevant to non-parents. This slice keeps the consistent per-card setup prompt;
the right fix is a future **onboarding "which apply to you" gate** (and/or
consolidating setup prompts into one) — its own slice. Flagged in build-status.

## Testing (TDD)
Rule: full amount below t1 (1 child under 6); Step-1 reduction (2 mixed kids);
Step-2 phase-out to $0 (high income); 4+ child bucket; 0 kids → notEligible.
Mapper: each status → kind/severity; setup when input missing. Widget: combined
section shows a CCB card alongside TFSA/RRSP.

## Out of scope
Child Disability Benefit, provincial child benefits, shared-custody split,
under-6 vs 6–17 birthday transitions mid-year (use current age band).
