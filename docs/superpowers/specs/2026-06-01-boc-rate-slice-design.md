# BoC Live Rate Card — slice design

**Date:** 2026-06-01
**Status:** Approved (auto-mode dev day) — building
**Builds on:** the engine slices. First **network** dependency + first card needing no user input.

## Goal
Show the current **Bank of Canada policy interest rate** (live) + the **typical
prime rate**, with offline caching and an "as of" date. A supporting "live
rates" layer from the strategy.

## Data source
Bank of Canada **Valet API** (free, no auth, JSON): series **V39079** = target
for the overnight rate.
`GET https://www.bankofcanada.ca/valet/observations/V39079/json?recent=1`
→ `{ "observations": [ { "d": "YYYY-MM-DD", "V39079": { "v": "2.75" } } ] }`.

Prime is set by banks, not BoC, so we DON'T claim a live prime: we show
**typical prime = policy + 2.20%** (the standing spread), clearly labelled
"typical". A later enhancement can fetch a real prime series after verifying its
Valet code.

## Architecture (app layer, not the pure engine)
Network fetch is app infrastructure, kept out of the offline engine.
```
services/boc_rate_service.dart
  BocRate { double policyRate; DateTime asOf; double typicalPrime; bool fromCache; }
  parseValetPolicyRate(String json) -> (double rate, DateTime date)   // pure, TDD
  class BocRateService {
    BocRateService({Fetcher? fetch})   // Fetcher = Future<String> Function(Uri); defaults to http.get
    Future<BocRate?> load()            // cached value (instant), or null
    Future<BocRate?> refresh()         // fetch + cache; on failure returns cached
  }
providers/boc_rate_provider.dart
  bocRateProvider : FutureProvider<BocRate?>  // load cache, then refresh; returns best available
```
- `http` package added to pubspec.
- Cache: one prefs key `kBocRateKey` (JSON: rate + asOf). `kBocPrimeSpread = 2.20`.
- **Injectable `fetch`** so tests never hit the network.
- Graceful degradation: fetch failure (incl. web CORS) → fall back to cache;
  no cache → card hidden. Never throws into the UI.

## UI
`BocRateCard` (always shown — no profile input):
- Headline: policy rate big (e.g. "2.75%"), label "Bank of Canada policy rate".
- Secondary: "Typical prime ≈ 4.95%" (labelled typical).
- "As of {date}" stamp; a small "Updated live" / "Offline — last known" hint.
- Tapping refreshes.
Placed on Home below the Found-money section in a "Rates" mini-section.

## Testing (TDD)
- `parseValetPolicyRate`: valid JSON → rate + date; missing/empty observations →
  throws/handled; malformed value.
- `BocRateService` with an injected fetcher + mock prefs: refresh caches; a
  failing fetcher falls back to cached; `load` returns cached or null.
- Widget: card renders a rate from an overridden provider; hidden on null.

## Edge cases
First launch offline / fetch fails, no cache → card hidden (no error UI).
Stale cache → shown with the older "as of" date + offline hint.

## Out of scope
Live prime series, historical chart, rate-change push notifications, next-
announcement date (needs a verified BoC schedule — later).
