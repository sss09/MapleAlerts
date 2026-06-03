# Hosted Data Pack — Design Spec

**Date:** 2026-06-02
**Status:** Approved
**Slice:** Pre-launch infrastructure (rule-currency without app updates)

## Why

Every figure in the Canadian Data Engine is a compiled-in constant ("as per
2025"). Canadian rules change on a predictable calendar — indexed limits each
November/December, CCB each July, occasional budget changes — and today every
change requires an app-store release that users may never install. The engine
was built with an explicit override seam for this (`DataPack`,
`data_pack.dart:13`: "A future `HostedDataPack` can fetch + cache a JSON file
and override values with no changes to any rule"). This slice builds that.

**Goal:** updating Canada's numbers = editing one JSON file in this repo →
push → every installed app picks it up within ~24h. No store release.

## Decisions (locked with user, 2026-06-02)

| Decision | Choice | Why |
|---|---|---|
| Hosting | **GitHub Pages, same repo** — `web/datapack/pack.json` → `https://sss09.github.io/MapleAlerts/datapack/pack.json` | Zero new infra (rides the existing `pages.yml` deploy; Flutter copies `web/` verbatim into the build). Free, CDN-backed, CORS-open (`Access-Control-Allow-Origin: *`) so it works on Android **and** Flutter web. Every pack change is a reviewed git commit. |
| Fallback semantics | **Per-field** delegation to `EmbeddedDataPack` | A partial or partially-corrupt pack can never break a rule; worst case a figure is as stale as the app build. |
| Version gate | `schemaVersion` (int) must equal the supported value, else reject wholesale; `packVersion` (ISO date string) decides remote-vs-embedded | An old app must never misparse a future pack shape; a fresh app update must beat a stale cached pack. |
| Refresh policy | Startup, fail-soft, only when cache is >24h old | Matches rule-change cadence; no polling, no battery cost. |

## Architecture

```
web/datapack/pack.json                        the hosted pack (also deployed)
lib/engine/canadian_data_engine/data/
  remote_data_pack.dart                       RemoteDataPack.fromJson (pure Dart, parse only)
  data_pack.dart                              + kEmbeddedPackVersion (ISO date)
lib/services/data_pack_service.dart           fetch + prefs cache (injectable fetcher)
lib/providers/data_pack_provider.dart         resolves remote-vs-embedded; app-wide DataPack
```

### 1. Pack JSON schema (v1)

Field shapes mirror the engine types exactly (`CcbParams`, `OasParams`,
`TaxBracket(lowerBound, rate)`, `Province.name` keys). All sections OPTIONAL —
missing sections fall back per-field.

```json
{
  "schemaVersion": 1,
  "packVersion": "2026-06-02",
  "tfsaAnnualLimits": { "2009": 5000, "2026": 7000 },
  "rrspAnnualMax": { "2025": 32490 },
  "rrspOverContributionBuffer": 2000,
  "fhsa": { "annualLimit": 8000, "lifetimeLimit": 40000 },
  "ccb": {
    "maxUnder6": 7997, "max6to17": 6748,
    "threshold1": 37487, "threshold2": 81222,
    "step1Rates": [0.07, 0.135, 0.19, 0.23],
    "step2Rates": [0.032, 0.057, 0.08, 0.095]
  },
  "oas": {
    "recoveryThreshold": 93454, "recoveryRate": 0.15,
    "upperThreshold65to74": 151668, "upperThreshold75plus": 157490
  },
  "tax": {
    "federal": [[0, 0.145], [57375, 0.205], [114750, 0.26], [177882, 0.29], [253414, 0.33]],
    "provincial": { "on": [[0, 0.0505], [52886, 0.0915]] }
  }
}
```

Brackets serialize as `[lowerBound, rate]` pairs; provincial keys are
`Province.name` strings (`on`, `bc`, `ab`, `qc`, `mb`, `sk`, `ns`, `nb`,
`nl`, `pe`, `yt`, `nt`, `nu`). The **v1 file content is generated from
today's embedded tables** — identical data, proving the pipe end-to-end with
zero figure risk.

### 2. Engine: `RemoteDataPack` (pure Dart — parsing only, no network, no Flutter)

`RemoteDataPack.fromJson(Map<String, dynamic> json, {required DataPack fallback})`

- Throws `FormatException` when `schemaVersion` ≠ 1 or `packVersion` is
  missing/not a string — caller falls back wholesale.
- Each `DataPack` member parses its section lazily-safe: section missing OR
  any value of the wrong shape → that member delegates to `fallback`. Parsing
  is defensive per section (one bad section never poisons another).
- `packVersion` returns the pack's own version string.
- `EmbeddedDataPack.packVersion` changes to a new comparable constant
  `kEmbeddedPackVersion` (ISO date, starts `'2026-06-02'`; bump when embedded
  tables change). Existing tests only assert non-empty — safe. The old
  per-table vintage strings (`kTfsaDataPackVersion` etc.) remain on their
  tables as documentation.

### 3. App: `DataPackService` (mirrors `BocRateService` pattern)

- `DataPackService({Future<String> Function(Uri)? fetcher})` — injectable;
  production uses `http.get` with a 5s timeout; tests inject fakes. No test
  touches the network.
- `refreshIfStale()`: reads `kDataPackFetchedAtKey` from prefs; if older than
  24h (or absent), fetches the pack URL, validates it parses
  (`RemoteDataPack.fromJson` against embedded fallback), then stores the raw
  JSON string under `kDataPackJsonKey` + timestamp. Every failure path is
  swallowed (offline, 404, bad JSON → keep the previous cache).
- Called fire-and-forget from app startup (after `runApp`, not blocking boot).

### 4. App: `dataPackProvider`

`Provider<DataPack>` resolution order:
1. Cached JSON exists, parses, `schemaVersion` supported, **and**
   `packVersion` (string compare — ISO dates sort lexicographically) is
   strictly newer than `kEmbeddedPackVersion` → `RemoteDataPack` (with
   embedded fallback).
2. Otherwise → `const EmbeddedDataPack()`.

Concretely: a `cachedPackJsonProvider` (`StateProvider<String?>`, seeded from
prefs at construction) holds the raw cached JSON; `dataPackProvider` watches
it and applies the resolution above; `DataPackService` writes the provider
after a successful fetch so cards rebuild without restart. The **6 existing
call sites** (`best_move_provider`, `money_insights_provider` ×4,
`tfsa_insight_provider`) swap `const EmbeddedDataPack()` →
`ref.watch(dataPackProvider)`.

### 5. Trust surface

You tab, under the Privacy caption: one line —
`Canadian data: v2026-06-02 · built-in` or `· updated over the air` —
reflecting the resolved pack. (Figures on cards already cite source + year via
"How we got this".)

## The ops loop (how rules stay current)

| When | What | Action |
|---|---|---|
| Nov–Dec | CRA announces next year's indexed limits (TFSA, RRSP, brackets, OAS) | Edit `web/datapack/pack.json`, verify vs CRA, bump `packVersion`, push |
| July | CCB benefit-year reset | Same |
| Budgets | Occasional rule changes | Review + same |
| Each app release | — | Refresh embedded tables to match the live pack; bump `kEmbeddedPackVersion` |

Verification discipline stays: a pack edit must cite its source in the commit
message, same standard as the embedded tables.

## Testing

- **Engine (unit):** full pack overrides every member; empty `{}` pack
  delegates everything; one corrupt section falls back alone; wrong
  `schemaVersion` throws; bracket/province parsing round-trips vs embedded.
- **Generator sanity:** a test asserts the shipped `web/datapack/pack.json`
  parses and its values equal `EmbeddedDataPack`'s for spot-checked figures
  (the file is loaded from disk in the test — keeps the deployed pack honest).
- **Service:** stale→fetch→cache; fresh→no fetch; fetch failure keeps old
  cache; injectable fetcher only.
- **Provider:** newer cached pack wins; older/equal cached pack loses to
  embedded; garbage cache → embedded.
- All 276 existing tests stay green (tests default to `EmbeddedDataPack`).

## Deferred

- Pack signing/integrity (HTTPS + same-repo review is the v1 trust model).
- Multi-pack/regional splitting; ETag/If-Modified-Since (24h TTL is enough).
- Explainer figures from the pack (explainers stay embedded content).
