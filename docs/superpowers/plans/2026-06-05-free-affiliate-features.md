# Free Affiliate Features — Implementation Plan

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Build every free affiliate-driven feature — rate gap card, rates sheet, contextual CTAs in insight cards, GIC rate comparison, BoC rate-impact card — so the app has a complete affiliate monetisation surface before launch.

**Governing rule (from free_vs_pro_revenue_map):** Rate intelligence = affiliate driver = always free. Show all institutions regardless of affiliate deal. Credibility first.

**Rate source:** rates live in the data pack (`web/datapack/pack.json`) — not scraped live. Manual weekly update. Every rates display shows `asOf` date + "Rates as of [date] — verify with institution" disclaimer (legal + trust). Promotional rates labeled clearly.

**Insurance labels (legally required):** CDIC (banks) · CDIC via ATB (Neo) · CDIC via Peoples Bank (KOHO) · DGCM (Manitoba CUs: Achieva, Outlook) · CIPF (Wealthsimple). Never say CDIC for a credit union or CIPF account.

**Affiliate strategy while awaiting approvals:** UTM-tagged direct URLs day 1 (build conversion data). EQ Bank + Wealthsimple + Neo + KOHO apply immediately. Ratehub as fallback for all institutions.

**Env:** Flutter `/c/src/flutter/bin/flutter`; `maple_alerts`; branch `main`; commit each task (no push); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## Task A1 — Add institution URLs + rate data to constants + data pack

**Files:** `lib/utils/constants.dart`, `web/datapack/pack.json`, `tool/generate_data_pack.dart` (if it embeds pack data), `lib/engine/canadian_data_engine/data/data_pack.dart`.

### Step 1 — Add institution URLs to `constants.dart`
```dart
// HISA affiliates
const String kEqBankHisaUrl     = 'https://www.eqbank.ca/personal-banking/savings-accounts/savings?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kWealthsimpleCashUrl = 'https://www.wealthsimple.com/en-ca/accounts/cash?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kNeoFinancialUrl   = 'https://www.neo.ca/savings?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kSimpliiHisaUrl    = 'https://www.simplii.com/en/bank-accounts/high-interest-savings-account.html?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kTangerineUrl      = 'https://www.tangerine.ca/en/products/banking/savings?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kKohoUrl           = 'https://www.koho.ca/earn-interest/?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kMotiveUrl         = 'https://www.motivefinancial.com/savings?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kAchievaUrl        = 'https://www.achieva.mb.ca/savings?utm_source=maplealerts&utm_medium=app&utm_campaign=hisa';
const String kOakenHisaUrl      = 'https://www.oaken.com/savings-accounts/?utm_source=maplealerts&utm_medium=app&utm_campaign=gic';
// GIC affiliates
const String kOakenGicUrl       = 'https://www.oaken.com/gics/?utm_source=maplealerts&utm_medium=app&utm_campaign=gic';
const String kEqBankGicUrl      = 'https://www.eqbank.ca/personal-banking/gics?utm_source=maplealerts&utm_medium=app&utm_campaign=gic';
// Mortgage / general comparison
const String kRatehubMortgageUrl = 'https://www.ratehub.ca/best-mortgage-rates?utm_source=maplealerts&utm_medium=app&utm_campaign=mortgage';
// Newsletter subscribe (Vercel proxy — update after deploy)
const String kNewsletterSubscribeUrl = 'https://maplealerts.vercel.app/api/subscribe';
```
Keep existing `kEqBankUrl`, `kWealthsimpleUrl`, `kRatehubUrl` (used in reminder_card.dart + affiliate_links.dart — do NOT remove).

### Step 2 — Add `rates` section to `web/datapack/pack.json`
Add a `"rates"` key (alongside existing keys). HISA rates in descending order, GIC rates separately. Format:
```json
"rates": {
  "asOf": "2026-06-05",
  "disclaimer": "Rates approximate and change frequently. Verify with institution before opening an account.",
  "hisa": [
    {"id":"eq_bank",     "name":"EQ Bank",          "rate":4.75,"insurance":"CDIC",                 "tier":1,"hasAffiliate":true},
    {"id":"wealthsimple","name":"Wealthsimple Cash", "rate":4.50,"insurance":"CIPF",                 "tier":1,"hasAffiliate":true,"note":"CIPF — not CDIC"},
    {"id":"neo",         "name":"Neo Financial",     "rate":4.65,"insurance":"CDIC via ATB",          "tier":1,"hasAffiliate":true},
    {"id":"simplii",     "name":"Simplii Financial", "rate":4.60,"insurance":"CDIC",                 "tier":1,"hasAffiliate":true},
    {"id":"tangerine",   "name":"Tangerine",         "rate":4.00,"insurance":"CDIC",                 "tier":2,"hasAffiliate":true,"note":"Promotional rates available — verify current"},
    {"id":"koho",        "name":"KOHO",              "rate":4.25,"insurance":"CDIC via Peoples Bank","tier":2,"hasAffiliate":true,"note":"Prepaid Visa with savings"},
    {"id":"motive",      "name":"Motive Financial",  "rate":4.55,"insurance":"CDIC",                 "tier":2,"hasAffiliate":false},
    {"id":"achieva",     "name":"Achieva Financial", "rate":4.60,"insurance":"DGCM",                 "tier":2,"hasAffiliate":false,"note":"DGCM — not CDIC"},
    {"id":"big_bank",    "name":"Typical big bank",  "rate":0.05,"insurance":"CDIC",                 "tier":3,"hasAffiliate":false,"note":"Comparison baseline only"}
  ],
  "gic_1yr": [
    {"id":"oaken",       "name":"Oaken Financial",   "rate":4.90,"insurance":"CDIC",                 "hasAffiliate":false},
    {"id":"eq_bank",     "name":"EQ Bank",            "rate":4.85,"insurance":"CDIC",                 "hasAffiliate":true},
    {"id":"achieva",     "name":"Achieva Financial",  "rate":4.85,"insurance":"DGCM",                 "hasAffiliate":false,"note":"DGCM — not CDIC"},
    {"id":"motive",      "name":"Motive Financial",   "rate":4.80,"insurance":"CDIC",                 "hasAffiliate":false},
    {"id":"tangerine",   "name":"Tangerine",          "rate":4.50,"insurance":"CDIC",                 "hasAffiliate":true,"note":"Verify current — may be promotional"}
  ]
}
```

### Step 3 — Add `RatesData` to the data pack Dart model
In `lib/engine/canadian_data_engine/data/data_pack.dart` (or wherever the pack is parsed), add:
```dart
class InstitutionRate {
  final String id, name;
  final double rate;
  final String insurance;
  final int tier;
  final bool hasAffiliate;
  final String? note;
  const InstitutionRate({required this.id, required this.name, required this.rate,
      required this.insurance, required this.tier, required this.hasAffiliate, this.note});
  factory InstitutionRate.fromJson(Map<String,dynamic> j) => InstitutionRate(
    id: j['id'] as String, name: j['name'] as String, rate: (j['rate'] as num).toDouble(),
    insurance: j['insurance'] as String, tier: (j['tier'] as num?)?.toInt() ?? 1,
    hasAffiliate: j['hasAffiliate'] as bool? ?? false,
    note: j['note'] as String?);
}
class RatesData {
  final String asOf, disclaimer;
  final List<InstitutionRate> hisa, gic1yr;
  const RatesData({required this.asOf, required this.disclaimer, required this.hisa, required this.gic1yr});
  static const empty = RatesData(asOf:'', disclaimer:'', hisa:[], gic1yr:[]);
  factory RatesData.fromJson(Map<String,dynamic> j) => RatesData(
    asOf: j['asOf'] as String? ?? '',
    disclaimer: j['disclaimer'] as String? ?? '',
    hisa: (j['hisa'] as List?)?.map((e) => InstitutionRate.fromJson(e as Map<String,dynamic>)).toList() ?? [],
    gic1yr: (j['gic_1yr'] as List?)?.map((e) => InstitutionRate.fromJson(e as Map<String,dynamic>)).toList() ?? [],
  );
}
```
Expose `RatesData get rates` from the pack (read from the JSON). Wire it into `dataPackProvider` so the app can access `ref.watch(dataPackProvider).rates`.

### Step 4 — Tests
- Unit test: `RatesData.fromJson` on a minimal JSON → correct hisa + gic1yr lists; `InstitutionRate` fields parse correctly; empty input → `RatesData.empty` fields are empty.
- Sanity test: `web/datapack/pack.json` parses without error and `rates.hisa.isNotEmpty`.
- Full suite green. Commit `feat: add institution URLs (UTM-tagged) + rates section to data pack`.

---

## Task A2 — `savingsBalance` in `MoneyProfile` (needed for rate gap card)

**Files:** `lib/engine/canadian_data_engine/domain/money_profile.dart`, `lib/services/money_profile_store.dart`, setup sheet or inline card (for input).

Add `final double? savingsBalance;` to `MoneyProfile` (with `clearSavingsBalance` in `copyWith`, JSON round-trip). Add a `savingsBalance` field to `money_profile_store.dart` persistence. No separate setup sheet needed for launch — the rate gap card itself asks inline ("Add your savings balance to see your rate gap"). Tests: `MoneyProfile.copyWith` / `fromJson` / `toJson` round-trip includes `savingsBalance`. Commit `feat: add savingsBalance to MoneyProfile`.

---

## Task A3 — Rate gap card ("You're losing $X/yr at your bank")

**Files:** Create `lib/features/money/presentation/widgets/rate_gap_card.dart`; test alongside; wire into `lib/features/money/presentation/widgets/found_money_section.dart`.

`RateGapCard` (ConsumerWidget): reads `moneyProfileProvider` + `dataPackProvider`.
- If `savingsBalance == null` → show setup prompt: "How much do you have in savings? We'll show you what you're leaving on the table." with a small text field (inline, no sheet needed). On save → update `moneyProfileProvider`.
- If balance set → compute: `bestRate = rates.hisa.first.rate` (highest tier-1); `bigBankRate = rates.hisa.lastWhere((r) => r.tier == 3).rate`; `gapPercent = bestRate - bigBankRate`; `annualGap = balance * gapPercent / 100`. Display:
  - Headline: `"You could be earning \$${annualGap.toStringAsFixed(0)}/yr more"` (severity = positive if gap > 100, info otherwise)
  - Subline: `"${rates.hisa.first.name} pays ${bestRate}% vs the typical big-bank ${bigBankRate}%"`
  - Primary CTA → opens `RatesSheet` (Task A4)
  - `asOf` disclaimer label
  - Track analytics: `analyticsProvider.track('rate_gap_shown', {'gap_annual': annualGap.toInt()})`
- Place in `FoundMoneySection` after the existing insight cards, always visible (not topic-gated — it's a free affiliate trigger).

Tests: build with balance set → finds gap headline; build without balance → finds setup prompt; gap calculation correct. Commit `feat: add rate gap card`.

---

## Task A4 — Rates sheet (HISA + GIC, affiliate links, expandable)

**Files:** Create `lib/features/money/presentation/widgets/rates_sheet.dart`; expose `showRatesSheet(context, ref)` helper; test alongside.

A `DraggableScrollableSheet` or `showModalBottomSheet`:
- Header: "Best Canadian rates" + `asOf` date + disclaimer text (small, muted).
- **HISA tab/section**: show tier-1 institutions (top 5: EQ Bank, Wealthsimple, Neo, Simplii, Tangerine) in `MapleSurface(bordered)` rows: name + rate + insurance badge + optional `note` tag (promotional/CIPF/DGCM). For `hasAffiliate` → tappable with `→ Open account` link button (uses `launchUrl` to the matching constant). For non-affiliate → plain link. A "See more" `TextButton` expands to tier-2 (KOHO, Motive, Achieva). Big bank row at bottom: "Typical big bank 0.05% — comparison only" (no link, muted style).
- **GIC section** (below or second tab): top 5 GIC providers, same row format. Oaken first.
- Insurance badge: small chip: CDIC=green, DGCM=amber, CIPF=blue.
- Footer: "Rates from data pack. Updated [asOf]. Always verify before opening an account."
- Analytics: `track('rates_sheet_opened', {'from': source})`.

Tests: builds, shows EQ Bank, shows disclaimer text, shows "See more" control. Commit `feat: add rates sheet with HISA + GIC rates and affiliate links`.

---

## Task A5 — Contextual affiliate CTAs in insight cards

**Files:** Modify `lib/features/money/presentation/widgets/insight_card.dart`; `lib/utils/constants.dart` (already updated in A1); test update.

Add a small affiliate CTA row at the bottom of `InsightCard` — shown *only* for specific insight ids + conditions. Below the existing CTA button, separated by a thin divider:
- `id == 'tfsa_room'` AND `insight.amount != null && insight.amount! > 5000` → `"Open a TFSA HISA at EQ Bank — ${bestHisaRate}% →"` → `launchUrl(kEqBankHisaUrl)`.
- `id == 'rrsp_room'` AND `amount > 5000` → `"Open an RRSP with Wealthsimple →"` → `launchUrl(kWealthsimpleUrl)`.
- `id == 'gic'` AND `insight.severity == InsightSeverity.alert || caution` (maturing/matured) → `"Compare GIC rates at EQ Bank →"` → `launchUrl(kEqBankGicUrl)` + `"Oaken Financial →"` → `launchUrl(kOakenGicUrl)`.
- Style: `fontSize: 12.5`, `colors.muted` text, `Icons.chevron_right` size 14. NOT a button — a `GestureDetector` text row. Subtle. Should feel helpful, not salesy.
- Pass `RatesData` (from `dataPackProvider`) into the card as an optional param, or read it from `Theme`/a provider — choose the cleaner pattern.
- Analytics: `track('affiliate_tapped', {'insight_id': id, 'partner': partner})`.

Tests: pump a TFSA insight card with amount > 5000 → finds EQ Bank CTA text; pump GIC maturing card → finds Oaken CTA; pump RRSP card amount < 5000 → no affiliate CTA. Commit `feat: contextual affiliate CTAs in insight cards`.

---

## Task A6 — BoC rate-impact card (enrich existing card with affiliate trigger)

**Files:** Modify `lib/features/money/presentation/widgets/boc_rate_card.dart`.

The card already shows policy rate + typical prime. Enrich it:
- Add a second row below the existing rate display: *"Rates just moved — this is a good time to compare GIC and HISA rates."* (shown whenever `rate != null`; vary the copy: if rate dropped → "Rates dropped — consider locking in a GIC."; if held → "Rate held — shop HISA rates now."; if rose → "Rates rose — HISA yields may improve soon."). Use a simple heuristic: compare to a `kBocPreviousRate` const (set to 2.75 initially) or just show a generic "BoC rate updated" message for launch.
- Add a small CTA row: `"See best rates →"` → opens `RatesSheet`.
- Analytics: `track('boc_rate_cta_tapped')`.

Tests: pump BocRateCard with a mocked rate → finds "See best rates" text. Commit `feat: enrich BoC card with rate-impact context + affiliate trigger`.

---

## Task A7 — GIC maturity → live rate comparison in GIC insight card

**Files:** Modify `lib/features/money/presentation/money_insight.dart` (or the GIC insight mapper) to pass best GIC rate into the insight subline when GIC is maturing/matured; ensure `insight_card.dart` shows it.

When `GicStatus.maturingSoon` or `GicStatus.matured`:
- Enrich `subline` (in the insight mapper) to include: `"Best 1-yr GIC now: ${topGicRate.name} ${topGicRate.rate}% — don't let it auto-renew at a lower rate."` Pass `RatesData` into the GIC insight mapper (or read it at the provider level).
- The affiliate CTA already added in A5 handles the link.

Tests: verify GIC maturing insight subline contains the rate text when RatesData has gic1yr entries. Commit `feat: enrich GIC maturity insight with live rate comparison`.

---

## Task A8 — Wire everything into the home screen

**Files:** `lib/features/reminders/presentation/screens/home_screen_v2.dart`.

- Add `RateGapCard` below `FoundMoneySection`, above `SeasonalRail`, visible under All and Finance chips.
- Ensure `RatesSheet` is accessible from Home (the "See best rates" link on the BoC card and rate gap card both open it).
- `flutter analyze lib test` clean; `flutter test -r compact` FULL suite green.
- Commit `feat: wire rate gap card + rates sheet into Home`.

---

## Self-review
- All 6 affiliate features covered: rate gap (A3), rates sheet (A4), contextual CTAs (A5), BoC trigger (A6), GIC comparison (A7), home wiring (A8).
- Foundation first: institutions/URLs in constants → data pack model → profile field → surfaces.
- Legal compliance: `asOf` disclaimer and insurance labels built into A4 data and rates sheet UI.
- UTM tags on all URLs from day 1 (constants in A1).
- No feature gated behind Pro — all free, all affiliate-driven.
