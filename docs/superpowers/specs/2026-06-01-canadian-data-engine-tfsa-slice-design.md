# Canadian Data Engine (skeleton) + TFSA Room — First Vertical Slice

**Date:** 2026-06-01
**Status:** Approved (brainstorm) — pending spec review
**Implements:** Phase 1 (Canadian Data Engine foundation) + first card of Phase 2 from
[money-copilot-strategy-design](./2026-06-01-money-copilot-strategy-design.md).

## Goal

Prove the entire "money co-pilot" stack end-to-end with one real, shippable feature —
**TFSA contribution-room "found money" + over-contribution guardrail on Home** — while
laying down the two foundational seams that are cheap now and expensive to retrofit:

1. A **standalone, pure-Dart Canadian Data Engine** module (liftable into sibling apps).
2. A **structured `MoneyProfile` store** (not a junk drawer of `SettingsState` scalars).
3. A **thin shared `MoneyInsight` view-model** so Home renders a *list* of insights and a
   future "best move" surface has a uniform shape to consume.

This slice is deliberately one rule deep. It is the template every later rule copies.

## Non-goals (explicitly later slices)

Hosted JSON data pack (network/cache), BoC Valet client, RRSP/CCB/carbon/OAS rules,
"best move right now" ranking engine, province/life-stage onboarding, premium AI,
withdrawal/re-contribution modelling.

## Why this is sustainable as the app grows

- **One rule = one pure function returning a typed result carrying its own `sources`.**
  Adding RRSP/CCB/etc. is more files of the same shape — no new plumbing.
- **`DataPack` is an override seam.** Embedded const table today; a `HostedDataPack` can
  replace values later with zero rule changes.
- **Financial inputs live in a structured `MoneyProfile`** (one serialized blob, one
  provider). New inputs (province, balances, income, # kids) are new *fields*, not new
  prefs keys + setters + `copyWith` branches.
- **Rules project onto a shared `MoneyInsight`.** Home renders `List<MoneyInsight>`, so it
  doesn't accrete bespoke wiring per feature, and "best move" later has a uniform list to
  reason over. We establish the *shape* now but do **not** build the ranking/registry
  machinery — that earns itself once a second rule exists.

Honest caveat: a fully generic insight type designed from one example can be wrong, so
`MoneyInsight` is kept deliberately thin and UI-copy stays out of the engine.

## Architecture

### Engine module (pure Dart — no `package:flutter` imports)

```
lib/engine/canadian_data_engine/
  canadian_data_engine.dart        // public barrel — the ONLY import site for app code
  data/
    data_pack.dart                 // abstract DataPack + EmbeddedDataPack
    tfsa_limits.dart               // const annual-limit table 2009..2026 + packVersion
  domain/
    money_profile.dart             // immutable inputs (birthYear, tfsaContributed)
    figure_source.dart             // {label, value, source} for "How we got this"
    tfsa_room.dart                 // TfsaRoomResult + TfsaStatus enum
  rules/
    tfsa_rule.dart                 // pure fn: (MoneyProfile, asOf, DataPack) -> TfsaRoomResult
```

Rules never touch widgets, SharedPreferences, `intl`, or the `Alert` model. The engine is
total: every `MoneyProfile` yields a valid `TfsaRoomResult` (no throws for missing input).

### App glue (Flutter side)

```
lib/services/money_profile_store.dart       // SharedPreferences JSON blob, one key, + legacy migration
lib/providers/money_profile_provider.dart   // StateNotifier<MoneyProfile> over the store
lib/providers/tfsa_insight_provider.dart     // runs tfsa_rule over EmbeddedDataPack -> List<MoneyInsight>
lib/features/money/presentation/money_insight.dart   // MoneyInsight view-model + enums + mapper from TfsaRoomResult
lib/features/money/presentation/widgets/insight_card.dart      // generic card renders one MoneyInsight
lib/features/money/presentation/widgets/found_money_section.dart // header + List<MoneyInsight>
lib/features/money/presentation/widgets/tfsa_setup_sheet.dart    // inline "the one number" input
```

## Data flow

```
MoneyProfileStore (prefs blob)
   -> moneyProfileProvider (MoneyProfile)
       -> tfsaInsightProvider: tfsaRule(profile, today, EmbeddedDataPack()) -> TfsaRoomResult
                                -> map -> List<MoneyInsight>
           -> FoundMoneySection on HomeScreenV2 renders the list via InsightCard
               -> card CTA (setup state) opens TfsaSetupSheet
                   -> writes tfsaContributed/birthYear via moneyProfileProvider.notifier
                       -> providers recompute -> card updates live
```

## The rule (deterministic math)

```
startYear       = max(2009, birthYear + 18)            // room accrues from age 18, >= 2009
cumulativeLimit = sum of limits[y] for y in [startYear .. asOfYear]
room            = cumulativeLimit - tfsaContributed
```

`TfsaStatus`:

| Status            | Condition                                  | Framing                                                        |
|-------------------|--------------------------------------------|----------------------------------------------------------------|
| `notYetEligible`  | `birthYear + 18 > asOfYear`                | "TFSA room starts the year you turn 18."                       |
| `overContributed` | `contributed > cumulativeLimit`            | guardrail: "$X over — CRA charges 1%/month on the excess."     |
| `nearLimit`       | `0 <= room <= 1000`                        | caution: "$X left — one more deposit could over-contribute."   |
| `healthy`         | `room > 1000`                              | found money: "$X of tax-free room available."                  |

`TfsaRoomResult` fields: `status`, `room`, `cumulativeLimit`, `contributed`, `startYear`,
`asOfYear`, `currentYearLimit`, `sources: List<FigureSource>`, `isEstimate = true`.

`sources` examples (drive the "How we got this" expansion):
- `FigureSource('2026 TFSA limit', '$7,000', 'CRA')`
- `FigureSource('Room counted from', '2018', 'You turned 18 that year')`
- `FigureSource('You told us you contributed', '$X', 'Your input')`

### TFSA annual-limit table (the moat — verify at implementation)

2009 $5,000 · 2010 $5,000 · 2011 $5,000 · 2012 $5,000 · 2013 $5,500 · 2014 $5,500 ·
2015 $10,000 · 2016 $5,500 · 2017 $5,500 · 2018 $5,500 · 2019 $6,000 · 2020 $6,000 ·
2021 $6,000 · 2022 $6,000 · 2023 $6,500 · 2024 $7,000 · 2025 $7,000 · 2026 $7,000

> Each value, and especially **2026**, is verified against the official CRA TFSA page at
> implementation time before the table is committed. `tfsa_limits.dart` carries a
> `packVersion` string so we know which vintage shipped.

## MoneyProfile store & migration

`MoneyProfile` (engine domain): `{ int? birthYear, double? tfsaContributed }` — room to grow.

`MoneyProfileStore` persists the profile as a single JSON string under one key
(`kMoneyProfileKey`). On first load, if the blob is absent it performs a **read-through
migration**: reads the legacy `kTfsaBirthYearKey` value (only ever written by the now-dead
V1 screens) to seed `birthYear`, then writes the blob. Other legacy financial keys
(e.g. `kRrspContributionKey`) are not consumed by this slice and are left untouched
(harmless; a future RRSP slice migrates them when it adds the field). `SettingsState`
keeps only app/UX prefs
(`notificationsEnabled`, `onboardingDone`, appearance tweaks); the financial scalars are no
longer read by live code.

## MoneyInsight (shared view-model)

Presentation-layer model (NOT in the engine — it carries UI copy/affordances):

```
enum InsightKind { foundMoney, guardrail, setup }
enum InsightSeverity { positive, info, caution, alert }

class MoneyInsight {
  final String id;            // stable, e.g. 'tfsa_room'
  final InsightKind kind;
  final InsightSeverity severity;
  final String headline;      // "You have $14,000 of TFSA room"
  final String? subline;
  final double? amount;       // for big-number rendering
  final List<FigureSource> sources;
  final bool isEstimate;
  final InsightCta? cta;      // label + callback (e.g. "Add your number" -> sheet)
}
```

A pure mapper `tfsaInsights(TfsaRoomResult, {required bool hasInput}) -> List<MoneyInsight>`
produces: a `setup` insight when input is missing, otherwise a `foundMoney`/`guardrail`
insight per status. Home renders the list with one generic `InsightCard`.

## UI placement & states

`FoundMoneySection` is inserted into `HomeScreenV2` directly **under `DayHandledHero`,
above the category chips / reminder sections**, with a `MapleSectionHeader('Found money')`.
It renders only when there is at least one insight (always at least the setup prompt once
the engine is wired). Card states: **setup** (no birth year/number → CTA opens
`TfsaSetupSheet`), **healthy**, **nearLimit**, **overContributed**. Every card shows: the
amount, a collapsible **"How we got this"** listing `sources`, an **estimate** tag with
province (n/a — federal) + year stamp, and the **"Informational, not financial advice"**
footer. Styling uses existing `MapleSurface` / Aurora tokens; guardrail states use the
warm-urgency accent.

## Error handling & edge cases

- Missing birth year or contributed number → `setup` insight, never a wrong figure.
- Under 18 (`birthYear + 18 > asOfYear`) → `notYetEligible`.
- Contributed exactly at limit → `nearLimit`, room $0.
- Engine is total — no exceptions for absent/extreme inputs; negative room is clamped only
  for *display* (the guardrail still reports the true overage amount).

## Testing

Pure Dart unit tests on `tfsa_rule.dart` (no Flutter), the correctness core:

- birth year pre-2009 (start clamps to 2009) and full cumulative total for a known asOf year.
- exactly turning 18 this year; under 18 (`notYetEligible`).
- $0 contributed → room == cumulativeLimit, `healthy`.
- over-contribution → `overContributed`, overage amount correct.
- near-limit threshold boundaries ($1,000 and $0).

Plus a light mapper test (`TfsaRoomResult` → expected `MoneyInsight` kind/severity) and,
optionally, one widget smoke test that the setup card renders and the sheet writes back.

## Build order

1. Engine: `tfsa_limits` + `data_pack` + `figure_source` + `money_profile` + `tfsa_room` +
   `tfsa_rule` + barrel. Unit tests first (TDD).
2. App: `MoneyProfileStore` (+ migration) + `moneyProfileProvider`.
3. `MoneyInsight` + mapper (+ mapper test) + `tfsaInsightProvider`.
4. `InsightCard` + `FoundMoneySection` + `TfsaSetupSheet`.
5. Wire `FoundMoneySection` into `HomeScreenV2`; manual on-device verification.
6. Update build-status.md (per the keep-docs-updated memory).

## Consequences

- **Positive:** first real co-pilot feature shipped; two expensive-to-retrofit seams
  (structured profile, uniform insight) established at near-zero extra cost; engine is a
  copyable template and stays liftable.
- **Costs:** transcribing/verifying the CRA limit table is real (and intentional — it's the
  moat); a thin risk that `MoneyInsight` needs reshaping when RRSP arrives (accepted —
  kept deliberately minimal).
