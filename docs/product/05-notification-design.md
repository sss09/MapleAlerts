# 05 — Notification Design

## The one rule
> **Every notification must answer: "What should I DO about this?"**

A date alone is not useful. A date + the stakes + a clear next action is. This is the difference between an app users mute and an app users trust.

## Anatomy of a great alert
1. **Icon + urgency** (⏰ / 🏦 / ✅ / 💰) and timeframe
2. **The fact** (what, when)
3. **The stakes** (what it means for *them*, ideally quantified)
4. **Actions** ([Do it] · [Learn more] · [Remind me later])

## Good vs bad

**RRSP**
- ❌ "RRSP deadline is March 1"
- ✅ "⏰ RRSP deadline in 7 days (March 1). Contributing $5,000 could save you ~$1,750 in tax. [Contribute Now] [Learn More] [Remind me later]"

**Bank of Canada**
- ❌ "Bank of Canada announcement today"
- ✅ "🏦 BoC rate decision today at 10 AM ET. Current: 4.75% | Expected: hold or −0.25%. If they cut, your variable mortgage saves ~$X/mo. [What this means for me]"

**TFSA**
- ❌ "TFSA room available"
- ✅ "✅ New TFSA room: $7,000 added Jan 1. Your unused room: ~$14,000 (est). Every dollar here grows tax-free forever. [Calculate my room] [Open TFSA]"

**GIC**
- ❌ "GIC maturing soon"
- ✅ "💰 Your GIC may be maturing soon. Best 1-yr rates now: EQ 5.05% | Oaken 5.10% | Simplii 4.90%. Don't let it auto-renew lower. [Compare rates]"

## Action buttons = monetization surface
The *next action* is often where affiliate value lives ([Open TFSA], [Compare rates]). Keep it genuinely helpful and clearly labelled — the action must serve the user first. (See [03 Monetization](03-monetization.md).)

## Lead-time strategy
- Each alert supports **multiple lead-times** (e.g., 60 / 30 / 7 / 1 days before) pulled from its category defaults and **user-overridable**.
- Fire at a sensible **local time-of-day** (default ~9:00 AM), timezone-correct.
- Recurring alerts roll forward to their next occurrence on app launch.
- (Implemented by the single notification pipeline in the [architecture spec](../superpowers/specs/2026-05-31-maplealerts-architecture-design.md).)

## Tone
- Plain language, no jargon (or jargon immediately explained).
- Specific and quantified where possible ("~$1,750 in tax").
- Calm and trustworthy — never alarmist or salesy.

## Anti-fatigue
- Personalize via [onboarding](04-onboarding.md) so users only get relevant alerts.
- Let users tune lead-times and mute categories.
- Don't stack redundant pings; consolidate same-day alerts where sensible.

## Quiet hours & permissions
- Respect OS notification permissions and quiet hours.
- Onboarding should request notification permission *after* showing value (post first alert setup), not on cold launch.
