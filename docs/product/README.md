# MapleAlerts — Product Documentation

> **One-line pitch:** *Your Canadian money, handled — deadlines, the money you're owed, and what to actually do, in plain language.*
>
> A **Canadian money co-pilot** and the **foundation of a chain** of Canadian apps. Differentiators: **penalty guardrails**, **"best move right now"**, **found money** — all free/deterministic; AI is premium-only.
> **⚑ Current strategy:** [`docs/superpowers/specs/2026-06-01-money-copilot-strategy-design.md`](../superpowers/specs/2026-06-01-money-copilot-strategy-design.md) (reframes the "alert app" docs below).

## Index

| Doc | What's in it |
|-----|--------------|
| [00 — Vision & Strategy](00-vision.md) | Problem, market, positioning, competitive moat |
| [01 — MVP Definition](01-mvp.md) | The 8 launch alerts, free/paid split, 4-week build plan, success metrics |
| [02 — Alert Catalog](02-alert-catalog.md) | Full taxonomy of all 11 categories — the content/feature backlog |
| [03 — Monetization](03-monetization.md) | Revenue streams, recommended sequencing, projections |
| [04 — Onboarding](04-onboarding.md) | Personalization flow that drives relevance + retention |
| [05 — Notification Design](05-notification-design.md) | The "what should I DO?" principle; good vs bad examples |
| [06 — Roadmap](06-roadmap.md) | Phased build (V1→V3), Year-1 timeline, marketing channels |
| [Architecture Spec](../superpowers/specs/2026-05-31-maplealerts-architecture-design.md) | Engineering design: structure, data model, data layer, migration, testing |

## How these fit together

- **Vision** sets the *why* and the moat.
- **MVP** is the disciplined *first slice* — ship in ~4 weeks, ride the RRSP/tax-season search spike.
- **Alert Catalog** is the long-term *content backlog* — the moat is getting all of this right, province by province, year by year.
- **Monetization / Onboarding / Notifications** are the *growth and UX systems*.
- **Architecture Spec** is *how* it's built so the catalog can grow without rewrites.

## Guiding principles
1. **Best UX / seamless experience** is the north star — every decision serves it.
2. **Trust is the moat** — no intrusive ads at launch; accuracy over breadth.
3. **Content as data** — Canadian rules live in versioned data, not hardcoded logic, so annual changes don't require code releases.
4. **Ship the MVP, then expand by content** — tech is mostly done after V1; the work becomes curating accurate Canadian financial rules.
