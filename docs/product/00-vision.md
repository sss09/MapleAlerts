# 00 — Vision & Strategy

> **⚑ 2026-06-01 REFRAME (naming updated 2026-06-05) — read first.** MapleAlerts is repositioned from "alert app" to a **Canadian money co-pilot** and **app #1 of the Maple chain** — siblings: **MapleDoc**, **MapleInvoice**, **MapleRates**, **MapleRenter**. Bundle = **Maple Pro** $6.99/mo. **Built in Flutter** (strategy doc says RN/Expo — that's superseded). Reminders are now *one pillar*. The differentiators are **penalty guardrails**, **"best move right now"** recommendations, and **found money** — all deterministic/free (no AI; AI is premium-only). See the full strategy: [`2026-06-01-money-copilot-strategy-design.md`](../superpowers/specs/2026-06-01-money-copilot-strategy-design.md). The sections below remain the deadline-hub base this builds on.

## The one-line pitch
> *Your Canadian money, handled — deadlines, the money you're owed, and what to actually do, in plain language.*
> (original: *the only app that tells Canadians about every financial deadline, benefit, and rate change before it costs them money.*)

This is **not** a budgeting/bank/investment app. It's a **money co-pilot**: it knows the Canadian rules and does the work for you — surfacing deadlines, found money, penalty guardrails, and plain-English guidance. Free value is fully deterministic (no AI/backend cost); AI is reserved for premium.

## The problem
There is no single app that alerts Canadians about the financial dates and windows that quietly cost them money when missed:

- TFSA room opening (Jan 1) · RRSP deadline (~Mar 1) · Tax filing (Apr 30 / Jun 15)
- Mortgage renewal windows · OSAP repayment grace-period end
- CPP / OAS / GIS application windows · FHSA contribution room
- CRA benefit payment dates (CCB, GST/HST credit, Trillium, CAI…)
- Bank of Canada rate announcements · GIC maturity / auto-renewal traps
- Benefit clawback thresholds · RESP grant (CESG) deadlines · DTC renewals

**Missing these costs real money:** a missed RRSP deadline = hundreds in lost tax savings; a missed OSAP window = accumulating interest; unused TFSA room = forgone tax-free growth; a GIC auto-renewing at a lower rate = lost yield.

## Target users
Every adult Canadian with a financial life — but especially:
- **Employees & freelancers** managing RRSP/TFSA/tax deadlines
- **Homeowners** facing mortgage renewals and rate changes
- **Students** navigating OSAP repayment
- **Parents** chasing RESP/CCB free-money deadlines
- **Seniors** timing CPP/OAS/GIS/RRIF decisions
- **Newcomers** learning an unfamiliar system on a clock

Onboarding personalization (see [04](04-onboarding.md)) tailors which alerts each user sees.

## Positioning
Simple. Focused. Useful. The app does **one job extremely well**: never let a Canadian miss a money-relevant date. Everything else (rate shopping, education, planning) hangs off that core as optional value.

## Competitive moat
Why this is defensible despite being "simple":

| Moat | Why it's hard to copy |
|------|------------------------|
| **Content** | Getting every Canadian rule right — federal + provincial variants, updated annually — takes months of research. |
| **Trust** | First credible "Canadian financial alerts" app becomes the default; reviews/reputation compound. |
| **Affiliate relationships** | Bank/financial affiliate deals have approval processes (3–6 months); a late competitor starts from zero. |
| **User data (ethical, anonymous)** | Aggregate timing patterns (when GICs mature, mortgages renew) improve personalization over time. |
| **SEO** | Ranking for "RRSP deadline reminder app Canada" takes 6–12 months; first mover compounds. |

**Strategic implication:** invest early in (a) **content accuracy** and (b) **SEO + seasonal PR**, because those are the moats that take longest to build.

## Why now
- FHSA (2023) and Canada Dental Care Plan (2024) are new — most Canadians don't know the rules → low-competition, high-value content.
- Annual seasonal spikes (RRSP Feb–Mar, tax Apr, OSAP Aug–Sep, BoC rate cycle) provide repeatable free-media + search windows.

## Non-goals (V1)
- ❌ Bank account integration / open banking
- ❌ AI advisor (optional Q&A may come later — see roadmap)
- ❌ Real-time market data
- ❌ Budgeting / expense tracking

See [01 — MVP](01-mvp.md) for the disciplined first slice.
