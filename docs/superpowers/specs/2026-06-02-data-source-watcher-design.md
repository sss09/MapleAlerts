# Data-Source Watcher — Design Spec

**Date:** 2026-06-02
**Status:** Approved
**Slice:** Post-data-pack automation (removes manual "watch CRA + type numbers" work)

## Why

The hosted data pack (`…/2026-06-02-hosted-data-pack-design.md`) made updating
Canada's figures a one-file edit + push. But it still relies on a human
*remembering* to check CRA each December/July and *typing* the new numbers —
error-prone and easy to forget. This slice automates the **detection and
drafting**, while keeping a human as the final accuracy gate (the brand is
accuracy; a scraper must never silently ship a wrong number).

**Goal:** a scheduled job watches the CRA source pages; when a figure changes
it opens a **pull request** with a regenerated `pack.json`, the diff, and the
source link. The maintainer reviews the number against the source and merges.
If a page can't be parsed or a value looks insane, it opens an **issue**
instead — never a silent edit.

## Decisions (locked with user, 2026-06-02)

| Decision | Choice |
|---|---|
| Automation level | **B — detect + draft PR.** Not full auto-publish (C): a misparsed financial figure shipped silently is worse than manual. Not alert-only (A): we want the numbers drafted, not just a ping. |
| Scope (v1) | **Indexed single-numbers:** TFSA annual limit, RRSP dollar max, OAS recovery threshold, CCB max amounts + thresholds 1/2. **Tax brackets stay manual** (13 tables, highest misparse risk, once-a-year eyes-on edit). |
| Failure mode | Parser returns null OR value fails a sanity band → **open an issue**, never touch the pack. |

## Architecture

```
tool/data_sources/
  source.dart            WatchedSource model (id, url, parser, sanity band)
  parsers.dart           pure (htmlBody) -> num? extractors, one per figure
  sources.dart           the WatchedSource list (URLs + bounds + which pack field)
tool/check_data_sources.dart   the runner: fetch -> parse -> sanity -> diff -> emit
.github/workflows/data-watch.yml   cron + PR/issue creation
test/tool/parsers_test.dart    TDD parsers against saved HTML fixtures
test/tool/fixtures/*.html      captured CRA page snippets (good + mangled)
```

### 1. Parsers — pure functions, the testable core

Each figure has a parser `num? Function(String htmlBody)`:
- Extracts via a tight regex/pattern anchored on stable nearby text (e.g. the
  TFSA page's "$" figure following the year label), not on brittle CSS depth.
- Returns `null` on any miss (page restructured, figure absent, non-numeric).
- Parsers are pure (no I/O) → unit-tested against saved fixtures, including
  **deliberately mangled** HTML that MUST return null.

### 2. Sanity bands — the misparse guard

Every `WatchedSource` carries a plausible `[min, max]` (and where natural, a
`step`, e.g. TFSA limits are multiples of $500). After parsing:
- value `null` or outside the band → **not trusted**; the runner records it as
  a "parse failure" for this source.
- value in band but **different** from the current pack value → a "change".
- value in band and equal → "no change".

This is what stops a `$7,500 → $75,000` misread from ever reaching a PR.

### 3. Runner — `tool/check_data_sources.dart`

For each `WatchedSource`: fetch the URL (5s timeout), run its parser, apply the
sanity band, compare to the current value read from `web/datapack/pack.json`.
Then:
- **Any change (all in-band):** regenerate `pack.json` via the existing
  `tool/generate_data_pack.dart` logic with the new value(s) merged + a bumped
  `packVersion` (today's date), print a machine-readable summary to stdout
  (changed fields, old→new, source URLs) and exit code `10`.
- **Any parse failure:** print the failing source(s) + reason, exit code `20`.
  (A run can have changes AND failures; failures take precedence → issue, no
  PR, so a half-broken scrape never produces a partial pack.)
- **No change, no failure:** exit `0`, silent.

The runner only ever *writes a candidate pack.json in the workspace*; it never
deploys. Deployment is the existing Pages flow, triggered by merging the PR.

### 4. GitHub Action — `data-watch.yml`

- **Schedule:** monthly cron, plus weekly during Nov 1–Jan 31 and Jun 1–Jul 31
  (the indexation/benefit-year windows). Plus `workflow_dispatch` for manual
  runs.
- Steps: checkout → setup Flutter/Dart → `dart run tool/check_data_sources.dart`
  → branch on exit code:
  - `10` → `peter-evans/create-pull-request` with title
    `data: CRA change — <field> <old>→<new>`, body = the runner summary +
    source links + "verify against the source before merging".
  - `20` → `actions/github-script` opens/updates an issue titled
    `data-watch: could not parse <source>` with the reason.
  - `0` → nothing.
- Permissions: `contents: write`, `pull-requests: write`, `issues: write`.

### 5. Maintainer loop

PR arrives → open the source link → confirm the number → merge → existing
`pages.yml` deploys the new `pack.json` → users get it within 24h (the pack's
own TTL). Issue arrives → a parser needs fixing (CRA restructured a page);
update the regex + fixture, manual pack edit covers that cycle.

## Testing

- **Parsers (unit, TDD):** each parser vs a saved good fixture returns the
  known figure; vs a mangled fixture returns null; sanity-band logic rejects
  out-of-range values. Fixtures are committed snippets (not live fetches) so
  tests are offline and deterministic.
- **Sanity/diff logic (unit):** in-band-equal → no change; in-band-different →
  change; out-of-band → failure; mixed → failure precedence.
- **Pack regeneration (unit):** merging a changed value produces a pack.json
  that `RemoteDataPack.fromJson` parses and that differs only in the intended
  field + `packVersion`.
- The Action YAML itself is thin glue — not unit-tested; validated by a
  `workflow_dispatch` dry run.

## Honest caveats (in scope, documented)

- **Scrapers are maintenance.** CRA *will* restructure a page eventually; the
  designed response is an issue (not a bad PR), and a parser/fixture update.
- **No API exists** for these figures — HTML scraping is the only option short
  of a paid data vendor; this is the pragmatic, reversible choice.
- Live source URLs can rate-limit/block CI IPs; the runner treats a fetch
  failure as a parse failure (issue, not crash).

## Deferred

- Tax-bracket scraping (13 tables) — stays manual.
- IRCC/immigration figures — not in the engine yet.
- Auto-merge on high-confidence changes — explicitly rejected for v1 (human
  gate is the point).
