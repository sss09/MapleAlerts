# Day 3 — Aurora Onboarding + Reminder Detail/Affiliate CTA

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Restyle onboarding in Aurora (first impression; fix the post-onboarding nav bug) and add a category-aware **affiliate CTA** into the reminder detail (monetization hook). Reuse-first; no domain changes.

**Env:** Flutter at `/c/src/flutter/bin/flutter`; package `maple_alerts`; branch `main`; commit each task (no push); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Test `flutter test <path> -r compact`; analyze `flutter analyze <path>`.

**Design language:** match the Aurora screens already built — `AuroraBackground`, `MapleSurface`, `StrokeIcon`, `ProgressRing`, tokens via `Theme.of(context).extension<MapleColors>()!`, accent green CTAs, Manrope. No design file for onboarding exists; follow the established Aurora style + the product flow in `docs/product/04-onboarding.md`.

---

### Task D3-1: Aurora onboarding restyle (+ fix nav)
**File:** Rewrite `lib/screens/onboarding/onboarding_screen.dart` (keep the class name `OnboardingScreen` + the `settingsProvider.completeOnboarding()` call). Test: `test/screens/onboarding/onboarding_screen_test.dart`.
- Keep a `PageView` flow (4 value pages). Reskin in Aurora: `Stack` with `AuroraBackground()` behind; each page = centered `StrokeIcon` (e.g. 'sparkle','finance','wallet','bell') in a glowing ring or `MapleSurface` chip + `Text(title, 28/700/colors.text)` + `Text(desc, 16/colors.muted)`.
- Page copy (update premium price to the locked **$4.99/mo**): (1) "Welcome to MapleAlerts" / "Never miss a Canadian financial deadline again." (2) "Your day, handled" / "RRSP, TFSA, tax, benefits, renewals — we track the dates so you don't have to." (3) "Calm, timely nudges" / "Reminders that tell you what to do — never robotic, never panic." (4) "Unlock everything" / "Personalized trackers, all categories, no ads — $4.99/mo. Start free."
- Dots indicator (active = accent, inactive = faint). Buttons: "Skip" (text, top-right, muted) + primary accent button "Next" / "Get Started" (green gradient like the FAB, dark text).
- **Fix nav:** on complete → `context.go('/')` (NOT `/home` — Home moved to `/` on Day 1). Verify the route in `lib/router.dart`.
- Smoke test: pump `OnboardingScreen` in `ProviderScope` + `MaterialApp(theme: mapleThemeData(DesignTheme.fog))` (override `settingsProvider` if its notifier auto-loads from shared_preferences — READ settings_provider.dart; if it needs a stub, mirror the alerts stub pattern). Assert first page title renders + a "Skip"/"Next" control is present. Run→PASS→analyze→commit `feat: restyle onboarding in Aurora; fix post-onboarding nav to /`.

### Task D3-2: Category-aware affiliate CTA in reminder detail
**Files:** Create `lib/features/reminders/presentation/affiliate_links.dart`; modify `lib/features/reminders/presentation/widgets/reminder_card.dart`; test `test/features/reminders/presentation/affiliate_links_test.dart`.
- `affiliate_links.dart`: `class AffiliateLink { final String label; final String url; const AffiliateLink(...); }` + `AffiliateLink? affiliateForCategory(String categoryId)`: finance→ "Compare savings & GIC rates" `kEqBankUrl` (or Wealthsimple `kWealthsimpleUrl`); home→ "Compare mortgage rates" `kRatehubUrl`; bills→ null; etc. Use the existing URL consts in `lib/utils/constants.dart` (kEqBankUrl, kWealthsimpleUrl, kRatehubUrl). Return null when no relevant partner (most categories) — only finance/home get a CTA for now.
- In `ReminderCard`'s expanded detail: if `affiliateForCategory(item.categoryId) != null`, render a subtle full-width CTA button (MapleSurface/outline style, accent text + small chevron) below the Mark done/Snooze pills, labeled with the link's `label`. onTap → `launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication)` (import `package:url_launcher/url_launcher.dart`). Wrap launch in try/catch (no crash if unavailable). Add a tiny "Sponsored" / "Partner" tag for transparency (per monetization doc).
- Pure-logic test (`affiliate_links_test.dart`): `affiliateForCategory('finance')` non-null with a real url; `affiliateForCategory('bills')` null; `affiliateForCategory('home')` non-null. Run→PASS.
- Also update the ReminderCard test if the expanded layout changed; keep its existing assertions passing.
- analyze clean; run `flutter test -r compact` full suite green. Commit `feat: add category-aware affiliate CTA to reminder detail`.

---
## Self-Review
- Covers Day 3 (onboarding + detail/affiliate). Fixes the latent `/home` nav bug from the Day-1 route change.
- No placeholders; reuses Aurora widgets/tokens + existing affiliate URL consts + url_launcher (already a dep). Transparency tag per monetization doc.
- Onboarding keeps existing `completeOnboarding()` logic; only the UI + nav target change.
