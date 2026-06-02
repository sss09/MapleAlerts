# RRSP Slice — room + tax-savings + deadline + guardrail

**Date:** 2026-06-01
**Status:** Approved (brainstorm) — building
**Builds on:** [canadian-data-engine-tfsa-slice](./2026-06-01-canadian-data-engine-tfsa-slice-design.md).
Second rule in the engine; first province- and income-aware rule.

## Goal

Ship the RRSP card: **unused room (found money) + estimated tax savings (the
headline differentiator) + March-1 deadline awareness + over-contribution
guardrail**. Along the way, prove the engine/profile/insight seams scale to a
second, richer rule — especially that `MoneyInsight` holds with zero new fields.

## Decisions (from brainstorm)

- **Include tax-savings now** — pulls province + income + federal/provincial
  marginal-bracket tables into the engine.
- **Room from the NOA deduction limit** — ask the user for the "RRSP deduction
  limit" on their CRA Notice of Assessment plus amount contributed;
  `room = limit − contributed`. (The NOA number already folds in carry-forward
  room and pension adjustment, so this is accurate; computing from income is not.)
- **Tax savings = marginal-rate × amount** — matches the strategy framing
  ("$5k saves ≈$1,750 at your marginal rate"); simpler and less error-prone than
  full progressive integration. Labelled an estimate that assumes the
  contribution stays within the current bracket.
- **`MoneyInsight` stays unchanged** — room is the primary amount; tax-savings +
  deadline live in the subline and drive severity. Zero new fields across two
  rules. If it strains in build, that's the signal to widen it (reported, not
  silently worked around).

## Engine additions (pure Dart, same module)

```
data/
  tax_brackets.dart   // federal + 13 provincial/territorial marginal bracket tables, year-stamped
  rrsp_limits.dart    // annual RRSP dollar maximums, $2,000 lifetime buffer, deadline calc
domain/
  province.dart       // Province enum (AB BC MB NB NL NS NT NU ON PE QC SK YT) + display names + code (de)serialization
  rrsp_room.dart      // RrspResult + RrspStatus
rules/
  tax_rule.dart       // marginalRate(year, province, income) = federalMarginal + provincialMarginal
  rrsp_rule.dart      // room, estimatedTaxSavings, marginalRate, deadline, status
```

`DataPack` gains:
- `List<TaxBracket> federalBrackets(int year)`
- `List<TaxBracket> provincialBrackets(int year, Province province)`
- `int? rrspAnnualMax(int year)` and `double get rrspOverContributionBuffer` (=2000)

`TaxBracket { double lowerBound; double rate; }` (rate applies to income above
lowerBound up to the next bracket). `EmbeddedDataPack` carries the const tables.

`MoneyProfile` gains four nullable fields: `Province? province`,
`double? annualIncome`, `double? rrspDeductionLimit`, `double? rrspContributed`
— added to `toJson`/`fromJson`/`copyWith`. No new prefs keys, no store changes.

## The rule

```
room          = deductionLimit − contributed
marginalRate  = federalMarginal(income) + provincialMarginal(income)   // at income's bracket
estimatedTaxSavings = max(0, room) × marginalRate
nextDeadline  = first RRSP deadline strictly relevant to asOf (≈ Mar 1 of next year)
```

`RrspStatus`:

| Status            | Condition                                            | Framing                                                              |
|-------------------|------------------------------------------------------|----------------------------------------------------------------------|
| `noLongerEligible`| birthYear known & age in asOfYear > 71               | info: "RRSP converts to a RRIF at 71."                               |
| `overContributed` | `contributed > limit + 2000`                         | alert: "$X over (past the $2,000 buffer) — 1%/month penalty."        |
| `withinBuffer`    | `−2000 ≤ room < 0`                                    | caution: "Into your $2,000 lifetime buffer — no penalty yet."        |
| `nearLimit`       | `0 ≤ room ≤ 1000`                                     | caution: "$X of room left."                                          |
| `healthy`         | `room > 1000`                                         | found money: "$X of RRSP room · using it could save ≈$Y."           |

`RrspResult` fields: `status`, `room`, `deductionLimit`, `contributed`,
`marginalRate`, `estimatedTaxSavings`, `nextDeadline`, `daysToDeadline`,
`asOfYear`, `province`, `sources: List<FigureSource>`, `isEstimate = true`.

Deadline severity: when `healthy`/`nearLimit` and `daysToDeadline ≤ 60`, the
insight escalates (caution) and the subline leads with the deadline. (Today is
June 1 → deadline is far off, so normal framing.)

`sources` examples: `('Your RRSP deduction limit', '$X', 'Your CRA NOA')`,
`('Marginal tax rate', '~32%', '2026 ON tax brackets')`,
`('Contributed', '$X', 'Your input')`, `('RRSP deadline', 'Mar 2, 2027', 'CRA')`.

## Tax-bracket data (the moat — verification required)

Federal + all 13 provinces/territories, marginal brackets for **tax year 2025**
(most recent fully-published year, used consistently across all jurisdictions —
brackets move little year-to-year and the figure is labelled an estimate),
version-stamped via `kTaxDataPackVersion`. Process: transcribe all; web-verify federal + ON/BC/AB/QC;
leave a `// VERIFY:` checklist for the remainder before launch. Quebec carries a
caveat — its provincial brackets are included but the 16.5% federal abatement is
omitted, so the QC estimate is slightly conservative (high). All figures labelled
estimates.

## Wiring (app)

- `rrspInsights(RrspResult, {required bool hasRequiredInput}) -> List<MoneyInsight>`
  (hasRequiredInput = province, income, deductionLimit, contributed all set).
- `rrspInsightsProvider` (profile → `tax_rule`/`rrsp_rule` over `EmbeddedDataPack`).
- **`moneyInsightsProvider`** = `[...tfsaInsights, ...rrspInsights]` — the single
  list `FoundMoneySection` renders (a small step toward the future ranking
  registry). `FoundMoneySection` switches from `tfsaInsightsProvider` to this.
- `RrspSetupSheet` — province picker + income + deduction limit + contributed,
  writing through `moneyProfileProvider`; new setters for the four fields.
- `InsightAction.editRrspProfile`; `FoundMoneySection._handleAction` routes it.

## Error handling & edge cases

- Any required input missing → setup insight (CTA → RRSP sheet). Never a number
  from assumptions.
- Income below the lowest bracket → lowest marginal rate; income $0 → savings $0.
- Age > 71 → `noLongerEligible` regardless of room.
- Engine stays total — no throws.

## Testing (TDD)

Rule (`tax_rule`, `rrsp_rule`): marginal rate at known incomes for ≥2 provinces
(incl. a bracket boundary); room; tax-savings = room × rate; over-contribution
past the $2k buffer; within-buffer; near/healthy boundaries; age>71; deadline
calc + the ≤60-day escalation. Mapper: each status → expected kind/severity, and
setup when input missing. Widget: combined `FoundMoneySection` renders both a
TFSA and an RRSP card from `moneyInsightsProvider`.

## Build order

1. `province.dart` + `MoneyProfile` fields (+ store/provider setters).
2. `tax_brackets.dart` + `DataPack` bracket accessors + `tax_rule` (TDD).
3. `rrsp_limits.dart` + `rrsp_room.dart` + `rrsp_rule` (TDD).
4. `rrspInsights` mapper (TDD) + `rrspInsightsProvider` + `moneyInsightsProvider`.
5. `RrspSetupSheet` + action routing; point `FoundMoneySection` at the combined provider.
6. Verify (analyze + full suite), update build-status.md, commit.

## Consequences

- **Positive:** ships the headline differentiator (tax-savings); proves the
  profile grows by fields and `MoneyInsight` holds across two rules; `tax_rule`
  is reusable by future rules (OAS clawback, best-move).
- **Costs:** the bracket tables are real research and need a verification pass
  (mitigated: web-verify the big jurisdictions, checklist the rest, version-stamp,
  label estimates); Quebec is approximate.
