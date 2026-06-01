# 04 — Onboarding

**Principle:** Onboarding = personalization = more relevant notifications = higher retention. The goal is to learn *just enough* to show only the alerts that matter to this user — fast, skippable, no forced account.

## UX rules
- **Local-first, no forced sign-up** — onboarding writes to the local profile; account/sync is optional and offered later.
- **< 60 seconds** to a personalized alert list.
- Each screen is multi-select, skippable, and editable later in Settings.
- Answers map to **profile tags** that filter the [alert catalog](02-alert-catalog.md).

## The flow

**Screen 1 — "Who are you?"**
Employee (T4) · Self-employed / Freelancer · Student · Retired / Semi-retired · New to Canada (< 3 years)

**Screen 2 — "What accounts do you have?"**
TFSA · RRSP · FHSA · RESP (kids) · RDSP (disability) · Non-registered · GICs / Term deposits

**Screen 3 — "What's your situation?"**
Renter · Homeowner (with mortgage) · Homeowner (no mortgage) · First-time buyer (planning)

**Screen 4 — "Life stage?"**
Student · Early career (20s–30s) · Growing family · Mid-career (40s) · Pre-retirement (55–64) · Retired (65+)

**Screen 5 — "Your province"**
ON · BC · AB · QC · MB · SK · NS · NB · Others

## From answers → alerts
The profile tags filter which catalog items are active. Examples:
- **Student + OSAP** → OSAP alerts, TFSA; *no* mortgage alerts.
- **Homeowner with renewal** → mortgage renewal, BoC rate changes; *no* OSAP.
- **Retiree** → OAS, CPP, GIS, RRIF; *no* OSAP.
- **New baby (life event)** → CCB, RESP/CESG, beneficiary updates.

## Data model mapping
- Onboarding stores a `UserProfile { employmentType, accounts[], housing, lifeStage, province, lifeEvents[] }` (local; syncable later).
- Catalog rules carry `audience` / `province` predicates; the active reminder set = catalog filtered by profile.
- This keeps personalization **data-driven** — adding a new audience filter is data, not code.

## Personalization, not gatekeeping
- Showing fewer, more-relevant alerts increases trust and reduces notification fatigue.
- Users can always browse the full catalog ("Show all Canadian alerts") and add any manually.
- Re-prompt lightly when a life event is detected or seasonally (e.g., "Buying a home this year?").
