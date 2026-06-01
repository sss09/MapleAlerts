# MapleAlerts — UX Redesign ("Aurora") Design

**Date:** 2026-06-01
**Status:** Approved (design provided by user via `UX-design-1.zip`; implementation architecture approved)
**Source:** Claude-design prototype (React/JSX) preserved at `docs/design/ux-design-1/` (screenshots + JSX tokens).
**Related:** [Architecture spec](2026-05-31-maplealerts-architecture-design.md) · [Product docs](../../product/README.md)

## Goal
Replace the inherited red Material UI with the provided dark **"Aurora"** design — calm, trustworthy, glanceable — and do it through a **swappable design-token system** so future design changes are a token swap, not a rewrite (explicit user requirement: "room for multiple design changes").

## Visual identity (tokens)
**Foundation (cool, low-saturation):** canvas `#070D15`, surfaces `#0B1320`/`#101D26`, hairlines `rgba(156,178,200,.10/.18)`. Text `#E6EDF3`, muted `rgba(180,196,212,.62)`, faint `.38`. Accent aurora green `#5BC6A0` / hi `#62D2A8`. Font **Manrope** (400–800) with system fallback.

**Semantic status palette (6) — never pure red:**
| status | color | label |
|--------|-------|-------|
| urgent | `#E78B7B` | Urgent |
| attention | `#E4B469` | Needs attention |
| upcoming | `#5FC6A0` | Upcoming |
| info | `#71C3D6` | Good to know |
| planning | `#A79CE2` | Planning ahead |
| done | `#8A99AC` | Handled |

Each status carries `color/edge/glow/soft` for borders, glows, badges. "Calm mode" (warm-accents off) cools urgent/attention to slate `#8FA8C0`.

**Categories (8 life-domains)** — each `icon + tint`:
Government `#74C2A4` · Bills `#8FC2D4` · Vehicle `#90B0D2` · Health `#78C8AC` · Finance `#DCC289` · Home `#AAB8D4` · Family `#C2AEE0` · Seasonal `#9CCEDC`.

**Auroras (4 swappable gradient systems):** Aurora Fog (emerald, default), Teal Frost, Arctic Steel, Northern Lights — each a radial base + 3 blurred drifting blobs + fog veil + noise grain.

**Shape/motion:** card radius 22, hero 26, chips 17, tab bar 26; matte-glass surfaces with backdrop blur (9/7/12px by level); ambient blob drift + scroll parallax (toggleable).

## Design-system architecture (the swappability mechanism)
```
lib/core/design/
  tokens/
    maple_colors.dart        ThemeExtension: canvas, surfaces, lines, text/muted/faint, accent
    maple_semantics.dart     ThemeExtension: 6 statuses → {color, edge, glow, soft, label}
    maple_categories.dart    category id → {icon, tint}
    maple_aurora_spec.dart   active aurora: base gradient stops + blob list
    maple_shapes.dart        radii, paddings, blur levels
    maple_type.dart          Manrope text theme
  themes/
    design_theme.dart        a named bundle of the above token sets
    design_theme_registry.dart   built-in themes (4 auroras); add a design = add an entry
    design_theme_provider.dart    Riverpod: active theme + tweaks, persisted (shared_preferences)
  widgets/                   token-driven primitives (see below)
```
- Tokens are Flutter **`ThemeExtension`s** assembled into `ThemeData.extensions`. Widgets read them via `Theme.of(context).extension<…>()`. **No widget hardcodes a color/size.** A new or revised design = a new `DesignTheme` entry; swapping is a provider change. This is the core requirement.
- **Tweaks** (mirrors the prototype's panel): `aurora` (×4), `cardStyle` (minimal/bordered/solid), `warmAccents` (calm mode), `legend`, `motion`, `fab` (dock/float/radial). Persisted; surfaced in the "You"/Settings screen.

## Widget library
**Core (token-driven):** `AuroraBackground` (animated blobs + veil + grain + scroll parallax), `ProgressRing` (CustomPainter, glow), `MapleSurface` (matte-glass container; level + status-reactive border/glow + blur), `StrokeIcon` (geometric stroke icon set ported from the design), `CategoryAvatar` (ring + category icon), `UrgencyDot`, `MapleChip`, `SectionHeader`, `MapleScaffold` (aurora bg + floating glass tab bar + center FAB).
**Home feature widgets:** `DayHandledHero` (ring: handled/total + "N to do" + reassurance copy), `CategoryFilterChips` (All + 8), `StatusLegend` (toggleable), `ReminderCard` (swipe→Done/Snooze + tap→expand detail w/ status badge, sub, detail, action pills), `SeasonalRail` (horizontal "Seasonal — Canada" cards).

## Home screen layout
Greeting + full date + weather chip → `DayHandledHero` → `CategoryFilterChips` → (optional `StatusLegend`) → sections **Today / This Week / Upcoming** each a `SectionHeader` + `ReminderCard`s → `SeasonalRail` → "You're all caught up" footer. Vertical scroll with aurora parallax. Bottom: glass tab bar (Home / Timeline / Alerts / You) + center FAB (add reminder).

## Category taxonomy + mapping (decision: adopt 8 life-domains)
The registry's top-level categories become the design's **8 life-domains**. Canadian financial built-ins map in:
- RRSP, TFSA, GIC, mortgage → **Finance**
- Tax filing, OSAP → **Finance** (Government for OSAP application/loan-servicing items)
- BoC rate dates → **Finance**
- CCB / benefit payments → **Family** (child benefit) / **Government** (general benefits)
- OHIP, passport → **Government** ; prescriptions → **Health** ; auto insurance/tires → **Vehicle** ; property tax → **Home**

`Reminder.categoryId` now references a life-domain id; the free/premium split (locked earlier) is preserved by tagging individual built-in reminders, not whole domains. The previous finance-specific category ids are superseded (kept only as historical migration mapping).

## Presentation / view-model (keeps widgets dumb)
`ReminderPresentation.map(Reminder, now) → ReminderView { title, categoryId, status, whenLabel, progress, amount?, sub, detail, section }`:
- **section:** daysUntil ≤ 0 or today → Today; ≤ 7 → This Week; else → Upcoming.
- **status:** from daysUntil vs category lead-times — within shortest lead-time → urgent/attention; within longest → upcoming/info; beyond → planning. Optional `metadata['status']` override.
- **progress:** `(1 − daysUntil/longestLeadTimeDays).clamp(0,1)`.
- **whenLabel:** date_helpers ("Ready today", "Due in 2 days", "In 18 days").
- **amount/sub/detail/place:** `description` + `metadata`.
Home reads `remindersProvider`, maps to `ReminderView`, groups by section. **Initially backed by seed data** (the design's sample set) so the UI builds/runs before Plan 2's DB lands; swap to the real `ReminderRepository` later with no widget changes.

## Build scope (decision: design system + Home first)
- **Phase A — Design system:** tokens (ThemeExtensions), theme registry + provider + tweaks persistence, core widgets (AuroraBackground, ProgressRing, MapleSurface, StrokeIcon, MapleScaffold).
- **Phase B — Home:** greeting/date/weather, DayHandledHero, chips, sections, ReminderCard (swipe + expand), SeasonalRail — on seed data; replaces old home.
- **Phase C — Tweaks/Settings:** wire aurora switch, card style, calm mode, motion, FAB mode into the "You"/Settings screen.
- **Later (out of scope here):** Timeline, Alerts, You screens; wire Home to real repository (after Plan 2 data layer); restyle onboarding; the radial/voice/scan FAB actions.

## Web/runtime notes
- Aurora blur + animations must stay smooth on web (primary dev target) and Android (physical device available). Use `BackdropFilter` sparingly; cap blob blur; gate ambient motion behind the `motion` tweak and `MediaQuery.disableAnimations`.
- Manrope via `google_fonts` (already a dependency) with bundling for offline.

## Consequences
- **Positive:** future redesigns = token swaps; the prototype's 4 auroras ship day one; logic-free widgets; matches the long-term multi-category hub vision.
- **Costs:** broader category set widens content scope (mitigated: ship finance content first); custom-painted ring/aurora need performance care; replaces existing screens (old theme/screens retired).
