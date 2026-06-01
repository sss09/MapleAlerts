# Aurora Design System + Home — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the Aurora design-system (swappable token/ThemeExtension foundation + core widgets) and a new Aurora **Home** screen, wired to the *existing* `alertsProvider`/`Alert` data — shippable this week.

**Architecture:** All visual values live in `ThemeExtension` token sets under `lib/core/design/` (swap a design = swap tokens). Widgets are token-driven and logic-free. A presentation mapper turns the existing `Alert` model into a `ReminderView` the widgets render. Reuses the entire Plan 1 domain core untouched and the existing data layer; only the category registry is adapted in place.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod, google_fonts (Manrope), shared_preferences. Tests via `flutter test`.

**Design source of truth (in repo):** `docs/design/ux-design-1/ui.jsx` (tokens), `home.jsx` (layout), `app.jsx` (shell), `data.js` (categories/urgency/sample data). Port exact hex/size values from these.

**Environment:** Flutter not on shell PATH — use `/c/src/flutter/bin/flutter`. Branch `main`. Commit each task (no push unless asked); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

**Conventions:** test cmd `/c/src/flutter/bin/flutter test <path> -r compact`; analyze `/c/src/flutter/bin/flutter analyze <path>`. Widget smoke tests pump the widget inside `MaterialApp(theme: mapleThemeData(DesignTheme.fog))` and assert it builds + key finders.

---

## PHASE A — Design System

### Task A1: Adapt category registry to 8 life-domains (reuse, minimize rework)

Modify the existing `ReminderCategory` registry (Plan 1, Task 5) to the design's 8 life-domains + `custom`. Same structure (id/label/icon/color/defaultLeadTimes/premiumByDefault) — only the entries change. Tints from `docs/design/ux-design-1/data.js` CATEGORIES.

**Files:**
- Modify: `lib/features/reminders/domain/reminder_category.dart`
- Modify: `test/features/reminders/domain/reminder_category_test.dart`

- [ ] **Step 1: Update the test to the new taxonomy**

```dart
// test/features/reminders/domain/reminder_category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';

void main() {
  group('ReminderCategory registry (life-domains)', () {
    const ids = ['government','bills','vehicle','health','finance','home','family','seasonal','custom'];

    test('contains the 8 life-domains plus custom', () {
      for (final id in ids) {
        expect(kReminderCategories.containsKey(id), isTrue, reason: 'missing $id');
      }
    });

    test('every map key equals its category id', () {
      for (final e in kReminderCategories.entries) {
        expect(e.value.id, e.key, reason: 'id mismatch for ${e.key}');
      }
    });

    test('categoryFor falls back to custom for unknown id', () {
      expect(categoryFor('nope').id, 'custom');
    });

    test('finance has a tint color and label', () {
      final fin = kReminderCategories['finance']!;
      expect(fin.label, 'Finance');
      expect(fin.color.toARGB32(), isNot(0));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails** — `/c/src/flutter/bin/flutter test test/features/reminders/domain/reminder_category_test.dart -r compact` → FAIL (old finance ids).

- [ ] **Step 3: Replace the registry entries** (keep the `ReminderCategory` class + `categoryFor` exactly as-is; replace only the `kReminderCategories` map). Use these tints (from data.js) and reasonable Material icons + lead-times:

```dart
const Map<String, ReminderCategory> kReminderCategories = {
  'government': ReminderCategory(id: 'government', label: 'Government', icon: Icons.account_balance, color: Color(0xFF74C2A4), defaultLeadTimes: [Duration(days: 30), Duration(days: 7), Duration(days: 1)]),
  'bills':      ReminderCategory(id: 'bills',      label: 'Bills',      icon: Icons.bolt,            color: Color(0xFF8FC2D4), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'vehicle':    ReminderCategory(id: 'vehicle',    label: 'Vehicle',    icon: Icons.directions_car, color: Color(0xFF90B0D2), defaultLeadTimes: [Duration(days: 14), Duration(days: 3)]),
  'health':     ReminderCategory(id: 'health',     label: 'Health',     icon: Icons.favorite_border,color: Color(0xFF78C8AC), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'finance':    ReminderCategory(id: 'finance',    label: 'Finance',    icon: Icons.savings,         color: Color(0xFFDCC289), defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)]),
  'home':       ReminderCategory(id: 'home',       label: 'Home',       icon: Icons.home_outlined,   color: Color(0xFFAAB8D4), defaultLeadTimes: [Duration(days: 30), Duration(days: 7)]),
  'family':     ReminderCategory(id: 'family',     label: 'Family',     icon: Icons.people_outline,  color: Color(0xFFC2AEE0), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'seasonal':   ReminderCategory(id: 'seasonal',   label: 'Seasonal',   icon: Icons.ac_unit,         color: Color(0xFF9CCEDC), defaultLeadTimes: [Duration(days: 14), Duration(days: 3)]),
  'custom':     ReminderCategory(id: 'custom',     label: 'Custom',     icon: Icons.notifications_none, color: Color(0xFF8A99AC)),
};
```
Add `import 'package:flutter/material.dart';` if not present. Premium gating moves to per-reminder (not per-domain), so drop `premiumByDefault: true` entries.

- [ ] **Step 4: Run test to verify it passes.**
- [ ] **Step 5: Commit** — `git commit -m "refactor: adapt category registry to 8 life-domains"`

---

### Task A2: `MapleColors` ThemeExtension

**Files:** Create `lib/core/design/tokens/maple_colors.dart`; Test `test/core/design/tokens/maple_colors_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';

void main() {
  test('MapleColors holds foundation colors and lerps', () {
    const c = MapleColors.fog;
    expect(c.canvas, const Color(0xFF070D15));
    expect(c.accent, const Color(0xFF5BC6A0));
    final l = c.lerp(c, 0.5) as MapleColors;
    expect(l.canvas, c.canvas);
  });
}
```

- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Implement** (values from `ui.jsx` `C`, TEXT, MUTED, FAINT, GREEN):

```dart
import 'package:flutter/material.dart';

@immutable
class MapleColors extends ThemeExtension<MapleColors> {
  final Color canvas, surface1, surface2, line, lineStrong;
  final Color text, muted, faint, accent, accentHi, slate;

  const MapleColors({
    required this.canvas, required this.surface1, required this.surface2,
    required this.line, required this.lineStrong, required this.text,
    required this.muted, required this.faint, required this.accent,
    required this.accentHi, required this.slate,
  });

  static const fog = MapleColors(
    canvas: Color(0xFF070D15), surface1: Color(0xFF0B1320), surface2: Color(0xFF101D26),
    line: Color(0x1A9CB2C8), lineStrong: Color(0x2E9CB2C8),
    text: Color(0xFFE6EDF3), muted: Color(0x9EB4C4D4), faint: Color(0x61B4C4D4),
    accent: Color(0xFF5BC6A0), accentHi: Color(0xFF62D2A8), slate: Color(0xFF8A99AC),
  );

  @override
  MapleColors copyWith({Color? canvas, Color? surface1, Color? surface2, Color? line,
      Color? lineStrong, Color? text, Color? muted, Color? faint, Color? accent,
      Color? accentHi, Color? slate}) => MapleColors(
        canvas: canvas ?? this.canvas, surface1: surface1 ?? this.surface1,
        surface2: surface2 ?? this.surface2, line: line ?? this.line,
        lineStrong: lineStrong ?? this.lineStrong, text: text ?? this.text,
        muted: muted ?? this.muted, faint: faint ?? this.faint,
        accent: accent ?? this.accent, accentHi: accentHi ?? this.accentHi,
        slate: slate ?? this.slate,
      );

  @override
  MapleColors lerp(ThemeExtension<MapleColors>? other, double t) {
    if (other is! MapleColors) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return MapleColors(
      canvas: m(canvas, other.canvas), surface1: m(surface1, other.surface1),
      surface2: m(surface2, other.surface2), line: m(line, other.line),
      lineStrong: m(lineStrong, other.lineStrong), text: m(text, other.text),
      muted: m(muted, other.muted), faint: m(faint, other.faint),
      accent: m(accent, other.accent), accentHi: m(accentHi, other.accentHi),
      slate: m(slate, other.slate),
    );
  }
}
```

- [ ] **Step 4: Run → PASS.**
- [ ] **Step 5: Commit** — `feat: add MapleColors design token`

---

### Task A3: `MapleSemantics` ThemeExtension (6 status colors)

**Files:** Create `lib/core/design/tokens/maple_semantics.dart`; Test `test/core/design/tokens/maple_semantics_test.dart`

Implement an immutable `MapleStatus { Color color, edge, glow, soft; String label }` and `MapleSemantics extends ThemeExtension` holding the 6 statuses (urgent/attention/upcoming/info/planning/done) from `ui.jsx` `SEM`, plus `MapleStatus byName(String, {bool warmAccents = true})` that, when `warmAccents` is false, returns slate `#8FA8C0` color for `urgent`/`attention` (calm mode, per `home.jsx` statusColor).

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';

void main() {
  const s = MapleSemantics.standard;
  test('exposes 6 statuses with labels', () {
    expect(s.byName('urgent').label, 'Urgent');
    expect(s.byName('upcoming').color, const Color(0xFF5FC6A0));
    expect(s.byName('done').label, 'Handled');
  });
  test('calm mode cools urgent/attention to slate', () {
    expect(s.byName('urgent', warmAccents: false).color, const Color(0xFF8FA8C0));
    expect(s.byName('upcoming', warmAccents: false).color, const Color(0xFF5FC6A0));
  });
  test('unknown status falls back to upcoming', () {
    expect(s.byName('zzz').color, s.byName('upcoming').color);
  });
}
```

- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Implement** with `MapleStatus` + `MapleSemantics.standard` (colors/labels from `SEM` in ui.jsx: urgent `#E78B7B`/edge `0x8CE78B7B`/glow `0x4DE78B7B`/soft `0x21E78B7B` "Urgent"; attention `#E4B469` "Needs attention"; upcoming `#5FC6A0` "Upcoming"; info `#71C3D6` "Good to know"; planning `#A79CE2` "Planning ahead"; done `#8A99AC` "Handled"). `byName` returns the map entry (fallback upcoming); calm mode swaps urgent/attention `.color` to `Color(0xFF8FA8C0)`. Provide `copyWith`/`lerp` (lerp may return `this` for simplicity since these are discrete palettes).
- [ ] **Step 4: Run → PASS.**
- [ ] **Step 5: Commit** — `feat: add MapleSemantics status palette`

---

### Task A4: Aurora specs + registry (4 systems)

**Files:** Create `lib/core/design/tokens/maple_aurora.dart`; Test `test/core/design/tokens/maple_aurora_test.dart`

Model the aurora background: `AuroraBlob { Color color; double size; Alignment position }` and `MapleAurora extends ThemeExtension { String label; List<Color> baseStops; List<AuroraBlob> blobs }`, plus `const Map<String, MapleAurora> kAuroras` with the 4 systems from `ui.jsx` `AURORAS` (emerald/teal/arctic/lights). Convert each radial `base` to 3 representative stops and the 3 blobs (color w/ alpha, size in px, x/y% → Alignment via `Alignment(x*2-1, y*2-1)`).

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_aurora.dart';

void main() {
  test('registry has the 4 aurora systems', () {
    for (final k in ['emerald','teal','arctic','lights']) {
      expect(kAuroras.containsKey(k), isTrue, reason: 'missing $k');
    }
  });
  test('each aurora has base stops and 3 blobs', () {
    for (final a in kAuroras.values) {
      expect(a.baseStops.length, greaterThanOrEqualTo(2));
      expect(a.blobs.length, 3);
    }
  });
}
```

- [ ] **Step 2–5:** Implement (port values from `AURORAS`), run → PASS, commit `feat: add aurora systems`.

---

### Task A5: `DesignTheme` assembly + `mapleThemeData()` + `designThemeProvider`

**Files:** Create `lib/core/design/design_theme.dart`, `lib/core/design/maple_theme.dart`, `lib/core/design/design_theme_provider.dart`; Test `test/core/design/maple_theme_test.dart`

- `DesignTheme` = named bundle: `{ String id; MapleColors colors; MapleSemantics semantics; MapleAurora aurora }`, with `DesignTheme.fog` (emerald aurora + standard semantics + fog colors). A `kDesignThemes` map keyed by aurora id (reuse `kAuroras` to vary the aurora; colors/semantics shared for now).
- `mapleThemeData(DesignTheme t, {bool warmAccents = true})` → `ThemeData` (dark, `useMaterial3: true`, `scaffoldBackgroundColor: t.colors.canvas`, `textTheme: GoogleFonts.manropeTextTheme(...)` tinted to `t.colors.text`, and `.extensions` = [colors, semantics, aurora]).
- `MapleTweaks { String auroraId; String cardStyle; bool warmAccents, legend, motion; String fab }` with defaults from `app.jsx` TWEAK_DEFAULTS; `tweaksProvider` (StateNotifier) loads/saves via shared_preferences; `designThemeProvider` derives the active `DesignTheme`+ThemeData from tweaks.

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';

void main() {
  test('mapleThemeData exposes token extensions', () {
    final td = mapleThemeData(DesignTheme.fog);
    expect(td.extension<MapleColors>()!.accent, const Color(0xFF5BC6A0));
    expect(td.scaffoldBackgroundColor, const Color(0xFF070D15));
  });
}
```

- [ ] **Step 2–5:** Implement, run → PASS (note: `GoogleFonts.manropeTextTheme` needs no network in tests; if it warns, wrap text theme creation so the test only checks extensions). Commit `feat: assemble Maple theme + design-theme provider with persisted tweaks`.

---

### Task A6: `StrokeIcon` widget (geometric icon set)

**Files:** Create `lib/core/design/widgets/stroke_icon.dart`; Test `test/core/design/widgets/stroke_icon_test.dart`

Port the `ICONS` path map from `docs/design/ux-design-1/data.js` into a `const Map<String,String> kStrokeIconPaths`. `StrokeIcon({required String name, double size = 20, Color? color, double strokeWidth = 1.7})` renders an SVG-like path via `CustomPaint` using `Path` parsing — **use `flutter_svg`'s string SVG** instead: build `'<svg viewBox="0 0 22 22"><path d="$d" .../></svg>'` and render with `SvgPicture.string` (flutter_svg is already a dependency). Returns `SizedBox(size)` if name unknown.

- [ ] **Step 1: Smoke test** — pump `StrokeIcon(name: 'bell')` in a `MaterialApp`; `expect(find.byType(StrokeIcon), findsOneWidget)`; pump unknown name → still builds (no throw).
- [ ] **Step 2: Run → FAIL.** **Step 3: Implement** (port paths, build SVG string, `SvgPicture.string`). **Step 4: Run → PASS.** **Step 5: Commit** `feat: add StrokeIcon`.

---

### Task A7: `ProgressRing` (CustomPainter)

**Files:** Create `lib/core/design/widgets/progress_ring.dart`; Test `test/core/design/widgets/progress_ring_test.dart`

`ProgressRing({double progress, double size = 38, double strokeWidth = 3, required Color color, Color? track, bool glow = true, Widget? child})` — CustomPainter draws a track circle + an arc from -90° sweeping `progress*2π`, round cap, optional glow via `MaskFilter.blur`. Centers `child`.

- [ ] **Step 1: Smoke test** — pump `ProgressRing(progress: 0.5, color: Colors.green, child: Text('2'))`; assert builds + finds 'Text'. **Steps 2–5:** implement (port geometry from `ui.jsx` `Ring`), run, commit `feat: add ProgressRing`.

---

### Task A8: `MapleSurface` (matte-glass container)

**Files:** Create `lib/core/design/widgets/maple_surface.dart`; Test `test/core/design/widgets/maple_surface_test.dart`

`MapleSurface({MapleSurfaceLevel level = minimal, String? status, bool active = false, bool passive = false, double radius = 22, EdgeInsets padding, required Widget child})`. Reads `MapleColors`/`MapleSemantics` from context. Renders `ClipRRect`+`BackdropFilter`(blur per level: minimal 9 / bordered 7 / solid 12) + `Container`(bg rgba per `ui.jsx` `surface()`, border = status edge when active else line, boxShadow = glow when active). Port bg/blur/shadow values from `surface()` in ui.jsx.

- [ ] **Step 1: Smoke test** — pump `MapleSurface(child: Text('x'))` inside `MaterialApp(theme: mapleThemeData(DesignTheme.fog))`; assert builds + 'x' found; pump with `status:'urgent', active:true` → builds. **Steps 2–5:** implement, run, commit `feat: add MapleSurface`.

---

### Task A9: `AuroraBackground`

**Files:** Create `lib/core/design/widgets/aurora_background.dart`; Test `test/core/design/widgets/aurora_background_test.dart`

`AuroraBackground({MapleAurora? aurora, bool motion = true, double parallax = 0})` — `Stack` of: base `DecoratedBox`(radial/linear gradient from `baseStops`), each blob as a positioned blurred radial circle (`Container` + `ImageFiltered`/`BackdropFilter` or a `RadialGradient` circle with `ImageFilter.blur`), a fog veil gradient, and a subtle dark overlay. If `motion`, animate blob offsets slowly (`AnimationController`, gated by `MediaQuery.disableAnimations`). Reads active aurora from context if not passed.

- [ ] **Step 1: Smoke test** — pump `Stack(children:[AuroraBackground(), Text('hi')])`; assert builds + 'hi'. Pump with `motion:false`. **Steps 2–5:** implement (port from `ui.jsx` `Aurora`), run, commit `feat: add AuroraBackground`.

---

### Task A10: `MapleScaffold` (aurora bg + glass tab bar + center FAB)

**Files:** Create `lib/core/design/widgets/maple_scaffold.dart`; Test `test/core/design/widgets/maple_scaffold_test.dart`

`MapleScaffold({required int currentIndex, required List<MapleTab> tabs, required ValueChanged<int> onTab, VoidCallback? onAdd, required Widget body})` where `MapleTab { String iconName, label }`. Renders: `AuroraBackground` behind, `body` in a `Stack`, a floating glass bottom bar (4 tabs split 2+2 with a center gap) + a raised circular green gradient FAB (port from `app.jsx` `TabBar`/`Fab` dock mode). Tabs: Home, Timeline, Alerts, You.

- [ ] **Step 1: Smoke test** — pump `MapleScaffold(currentIndex:0, tabs:[...4], onTab:(_){}, onAdd:(){}, body: Text('home'))`; assert builds + 'home' + finds 4 tab labels. **Steps 2–5:** implement, run, commit `feat: add MapleScaffold shell`.

---

## PHASE B — Home (on existing data)

### Task B1: `ReminderView` + `AlertPresentation.map` (TDD — pure logic)

Maps the existing `Alert` (`lib/models/alert.dart`: id,title,description,type(AlertType),deadline,metadata) → a display `ReminderView`. Derives section/status/whenLabel/progress. Categories map `AlertType`→life-domain id.

**Files:** Create `lib/features/reminders/presentation/reminder_view.dart`, `lib/features/reminders/presentation/alert_presentation.dart`; Test `test/features/reminders/presentation/alert_presentation_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/features/reminders/presentation/alert_presentation.dart';

Alert _a(AlertType t, DateTime d) => Alert(id: 'x', title: 'T', description: 'D', type: t, deadline: d);

void main() {
  final now = DateTime(2026, 2, 24);
  group('AlertPresentation.map', () {
    test('maps RRSP to finance category', () {
      final v = AlertPresentation.map(_a(AlertType.rrsp, DateTime(2026, 3, 1)), now);
      expect(v.categoryId, 'finance');
    });
    test('section: today / this week / upcoming', () {
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 24)), now).section, 'Today');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 28)), now).section, 'This Week');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 4, 1)), now).section, 'Upcoming');
    });
    test('status: due-soon is urgent, far-off is planning', () {
      expect(AlertPresentation.map(_a(AlertType.boc, DateTime(2026, 2, 25)), now).status, 'urgent');
      expect(AlertPresentation.map(_a(AlertType.mortgage, DateTime(2026, 6, 1)), now).status, 'planning');
    });
    test('whenLabel reads naturally', () {
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 24)), now).whenLabel, 'Today');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 26)), now).whenLabel, 'In 2 days');
    });
    test('progress is 0..1 and higher when closer', () {
      final near = AlertPresentation.map(_a(AlertType.boc, DateTime(2026, 2, 25)), now).progress;
      final far  = AlertPresentation.map(_a(AlertType.mortgage, DateTime(2026, 6, 1)), now).progress;
      expect(near, inInclusiveRange(0, 1));
      expect(near, greaterThan(far));
    });
  });
}
```

- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Implement.** `ReminderView` = immutable `{ id, title, description, categoryId, status, section, whenLabel, progress, amount? }`. `AlertPresentation`:
  - `categoryId`: `AlertType.rrsp/tfsa/gic/mortgage/boc/osap → 'finance'`, `ccb → 'family'`, `custom → 'custom'` (table).
  - `daysLeft = deadline.difference(now).inDays` (floor by date).
  - `section`: `<=0 → 'Today'`; `<=7 → 'This Week'`; else `'Upcoming'`.
  - `status`: `daysLeft<=2 → 'urgent'`; `<=7 → 'attention'`; `<=21 → 'upcoming'`; `<=60 → 'info'`; else `'planning'`.
  - `whenLabel`: reuse `lib/utils/date_helpers.dart` (`daysUntilLabel`/`formatDateShort`); "Today" when 0, "In N days" otherwise.
  - `progress`: `(1 - daysLeft/90).clamp(0.0, 1.0)`.
  - `amount`: from `metadata['amount']` if present.
- [ ] **Step 4: Run → PASS.** **Step 5: Commit** `feat: add Alert→ReminderView presentation mapper`.

---

### Task B2: `DayHandledHero`

**Files:** Create `lib/features/reminders/presentation/widgets/day_handled_hero.dart`; Test alongside.
`DayHandledHero({required int needs, required int total})` → `MapleSurface(radius:26)` with a `ProgressRing`(progress: handled/total, center: needs + "to do") + sparkle icon + "Your day, handled" label + copy "<needs> things need you this week. The other <handled> are quietly taken care of." Port from `home.jsx` `Hero`.
- [ ] Smoke test: pump with needs:2,total:8 → builds + finds 'Your day, handled'. Implement, run, commit `feat: add DayHandledHero`.

---

### Task B3: `CategoryFilterChips` + `StatusLegend`

**Files:** Create `lib/features/reminders/presentation/widgets/category_filter_chips.dart`; Test alongside.
`CategoryFilterChips({required String active, required ValueChanged<String> onPick})` — horizontal scroll: 'All' + 8 categories (from `kReminderCategories`), tinted when active (port from `home.jsx` `Chips`). `StatusLegend()` — horizontal row of the 5 active statuses from `MapleSemantics` (port `Legend`).
- [ ] Smoke test: pump chips with active:'All' → builds + finds 'All' + 'Finance'. Implement, run, commit `feat: add category chips + status legend`.

---

### Task B4: `ReminderCard` (swipe-to-act + tap-to-expand)

**Files:** Create `lib/features/reminders/presentation/widgets/reminder_card.dart`; Test alongside.
`ReminderCard({required ReminderView item, VoidCallback? onDone, VoidCallback? onSnooze})` — `MapleSurface`(status: item.status, radius 22) row: `ProgressRing`(progress, color: status color) wrapping a `CategoryAvatar`(category icon+tint) → title + optional amount → status dot + whenLabel + category name → chevron. Tap toggles an expandable detail (description + Mark done/Snooze pills). Swipe-left reveals Snooze/Done actions — use `Dismissible` (key, `direction: endToStart`, custom background with two actions) OR a `GestureDetector` translate; **use `Dismissible`** for reliability (confirmDismiss returns false; fire `onDone`/`onSnooze` from the action buttons in the background). Port visual from `home.jsx` `ReminderCard`. (Create `CategoryAvatar` here or as a small core widget.)
- [ ] Smoke test: pump with a sample `ReminderView(status:'urgent', whenLabel:'In 2 days', title:'Hydro bill due', categoryId:'bills')` inside themed MaterialApp → builds + finds 'Hydro bill due'; tap the card → finds detail action 'Mark done'. Implement, run, commit `feat: add ReminderCard with expand + swipe actions`.

---

### Task B5: `SeasonalRail` + `MapleSectionHeader`

**Files:** Create `lib/features/reminders/presentation/widgets/seasonal_rail.dart`, `lib/core/design/widgets/maple_section_header.dart`; Tests alongside.
`MapleSectionHeader({required String label, String? count})` (port `home.jsx` SectionHeader). `SeasonalRail()` — horizontal `MapleSurface('bordered')` cards from a small const seasonal list (port `SEASONAL` from data.js: CRA filing, carbon rebate, DST, property tax). 
- [ ] Smoke tests: each builds + finds its label. Implement, run, commit `feat: add seasonal rail + section header`.

---

### Task B6: `HomeScreen` + wire into app (replace old home & theme)

**Files:** Create `lib/features/reminders/presentation/screens/home_screen_v2.dart`; Modify `lib/main.dart` (use `mapleThemeData`), `lib/router.dart` (Home tab → `HomeScreenV2`, wrap shell in `MapleScaffold`); Test `test/features/reminders/presentation/screens/home_screen_v2_test.dart`

`HomeScreenV2` (ConsumerWidget): reads existing `alertsProvider`; on data, `map` each `Alert`→`ReminderView`, filter by active category chip, group by section (Today/This Week/Upcoming), compute `needs` (urgent+attention) & total. Renders scroll: greeting+date+weather chip → `DayHandledHero` → `CategoryFilterChips` → optional `StatusLegend` (from tweaks) → sections → `SeasonalRail` → caught-up footer. Wrap in `AuroraBackground` (parallax on scroll). Update `main.dart` to `theme: mapleThemeData(DesignTheme.fog), themeMode: ThemeMode.dark` (read from `designThemeProvider` once provider wired) and `router.dart` shell to `MapleScaffold`.

- [ ] **Step 1: Smoke test** — pump `ProviderScope(child: MaterialApp(theme: mapleThemeData(DesignTheme.fog), home: HomeScreenV2()))` with `alertsProvider` overridden to return 2 sample alerts; assert builds + finds 'Your day, handled' + a sample title. (Override the provider to avoid DB in tests.)
- [ ] **Step 2: Run → FAIL.** **Step 3: Implement** screen + wire main/router. **Step 4: Run → PASS.**
- [ ] **Step 5: Verify on web** — `/c/src/flutter/bin/flutter run -d chrome --web-port=8088`; confirm Aurora home renders with reminders, chips filter, a card expands. (Manual; the running agent navigates with Playwright + reads semantics: expects 'Your day, handled', section labels, tab labels.)
- [ ] **Step 6: Analyze + full suite** — `/c/src/flutter/bin/flutter analyze lib test` (no issues) and `/c/src/flutter/bin/flutter test -r compact` (all green).
- [ ] **Step 7: Commit** `feat: Aurora Home screen wired to existing alerts; retire old red home/theme`.

---

## Self-Review
- **Spec coverage:** tokens (A2–A4), theme+provider+tweaks (A5), widget library (A6–A10, B2–B5), Home layout (B6), presentation derivations (B1), category taxonomy adaptation (A1), reuse of existing data (B1/B6). ✓ Out-of-scope (Timeline/Alerts/You/repository wiring) deferred per shipment plan.
- **Placeholders:** none — code given for logic/tokens; widgets specify constructor + responsibility + exact design-source reference + smoke test.
- **Type consistency:** `ReminderView` fields used identically in B1↔B2↔B4↔B6; `MapleColors`/`MapleSemantics`/`MapleAurora` extension names consistent A2↔A5↔widgets; `categoryFor`/`kReminderCategories` reused from A1; `mapleThemeData(DesignTheme.fog)` signature consistent across tests.
- **Reuse / minimize rework:** domain core (Plan 1) untouched; only `reminder_category.dart` edited; existing `alertsProvider`/`Alert`/`date_helpers` reused; old home/theme retired (inherited, not our work).
