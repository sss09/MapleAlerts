# 02 — Alert Catalog + Feature Backlog

This is the **long-term content/feature backlog** (alerts + money-co-pilot features). It is *not* the build order. Getting Canadian rules right, province-by-province and annually updated, **is the moat.**

## Revenue map features (from `free_vs_pro_revenue_map.html`, 2026-06-05)
*The governing rule: affiliate driver → Free; personal depth → Pro; penalty protection → Free always.*

### Free (affiliate-driven) — build in order
| Feature | Status | Revenue mechanism |
|---|---|---|
| Rate gap card — "you're losing $X/yr at your bank" (calculates best HISA vs user balance × rate diff) | ❌ not built | Highest-conversion affiliate trigger |
| Rates sheet — top HISA + GIC rates with affiliate links | ❌ not built | Affiliate revenue |
| Contextual CTAs in insight cards (TFSA → EQ Bank HISA, RRSP → Wealthsimple, GIC → rate compare) | ⚠️ partial (reminder cards only, not insight cards) | Affiliate revenue |
| GIC maturity → live rate comparison (EQ Bank 4.85% vs your 3.20%) | ⚠️ partial (no live rate shown) | Affiliate revenue |
| BoC decision → rate-impact card ("rates dropped — lock in a GIC now") | ⚠️ partial (rate card exists, not this framing) | Affiliate trigger |
| Maple Wrapped — shareable year summary card (free; every share = acquisition) | ❌ not built | Growth engine |

### Pro ($2.99/mo) — post-launch v1.1
| Feature | Status | Value |
|---|---|---|
| Personalised paywall — shows user's actual TFSA room / deadline / found money | ❌ not built | Highest conversion driver |
| Year-end optimizer — personalised Dec 31 checklist | ❌ not built | Anchor Pro feature |
| RRSP vs TFSA deep comparison — side-by-side with their numbers | ⚠️ engine only, no UI | High perceived value |
| Partner / spouse account tracking | ❌ not built | Household value |
| Net worth history + chart (fl_chart) | ❌ not built | Progress tracking |
| Contribution pace tracker (on track to max TFSA?) | ❌ not built | Engagement |
| PDF year summary (share_plus, pdf package) | ❌ not built | Tax-season value |

**Phase legend:** `P1` = MVP · `P2` = post-launch benefits/trackers · `P3` = life events & advanced · `Pn` = later/expansion.

> **Architecture note:** every item below is one `Reminder` of a registered `category` with a `schedule` (one-time or recurring) and a `NotificationConfig`. Adding a category = one registry entry + its rule data. Provincial/audience variants are data, not code. See the [architecture spec](../superpowers/specs/2026-05-31-maplealerts-architecture-design.md).

---

## Category 1 — Registered Accounts
**TFSA** `P1`: Jan 1 new-room alert · cumulative room tracker (from age-18 year) · unused-room nudge · over-contribution warning · withdrawal re-add reminder. `P2+`
**RRSP** `P1` (deadline) / `P2`: 60/30/7/day-of deadline · contribution-room estimator · spousal RRSP (3-yr attribution) · RRSP→RRIF conversion (age 71) · **HBP repayment** schedule · **LLP repayment**.
**FHSA** `P1.5/P2` (new, low-competition): $8,000 annual room · $40,000 lifetime tracker · carry-forward "use it or lose it" · withdraw-first-for-home · close-within-1-year / transfer-to-RRSP-by-71.
**RESP** `P2/P3`: annual **CESG** ($500 free/yr — widely missed) · child-turns-17 last-full-CESG · child-turns-18 rule change · **CLB** (low income) · provincial grants (BC BCTESG, AB ACES) · contribution room.
**RDSP** `Pn`: CDSG deadline · CDSB (low income) · 10-yr holdback · DTC expiry.

## Category 2 — Tax Deadlines
**Federal** `P1` (filing) / `P2`: Apr 30 filing (60/30/7/day-of) · Jun 15 self-employed (Apr 30 payment) · late-penalty warning · quarterly installments (Mar/Jun/Sep/Dec 15) · T4 availability (end Feb) · RRSP receipt (end Mar).
**GST/HST (self-employed)** `P2/P3`: quarterly + annual filing · $30k registration threshold · input tax credit reminder.
**Provincial** `P2`: Quebec separate system/deadlines.
**Capital gains** `P3`: year-end tax-loss-harvesting window · capital-gains budgeting · inclusion-rate change tracking.

## Category 3 — Government Benefits & Payments
**CRA payment dates** `P1` (CCB) / `P2`: CCB monthly + July reassessment · GST/HST credit (quarterly) · Ontario Trillium · Alberta Child & Family Benefit · BC Family Benefit · Climate Action Incentive · Advanced Canada Workers Benefit · Canada Dental Care Plan (2024).
**Seniors** `P2/P3`: OAS (apply 6mo before 65; defer-to-70 +36%) · GIS (annual reapply / file on time) · CPP window (60 reduced ↔ 70 increased; break-even calc) · survivor's benefit · **OAS clawback threshold** alert.
**Provincial** `Pn`: ODSP / BC PWD / AB AISH review reminders · rent supplement renewals.

## Category 4 — Mortgage & Real Estate
**Mortgage** `P1` (renewal) / `P2`: renewal 12/6/3/1-mo (shop 4mo early) · rate-hold expiry (~120 days) · variable-rate change (tied to BoC dates) · prepayment-privilege anniversary · **trigger-rate** alert (variable) · CMHC premium · FTHB incentive repayment · property tax deadlines (by municipality).
**Home equity** `Pn`: HELOC review · equity milestones · principal-residence exemption tracking.

## Category 5 — Student Loans & OSAP
**OSAP** `P1` (grace-end) / `P2`: application open/deadline by semester · **repayment grace-period end** (high-value, easily forgotten) · RAP eligibility · interest-relief deadline · forgiveness programs.
**Canada Student Loan** `P2`: repayment start · assistance · rate changes · consolidation · NSLSC alerts.
**Provincial** `Pn`: BC StudentAidBC · Alberta Student Aid · Manitoba · Quebec AFE.

## Category 6 — Employment & Income
**EI** `P3`: apply within 4 weeks of job loss · payment schedule · ROE reminder · benefit-period end · mat/parental-leave timeline · 1-wk waiting period.
**CPP** `P2/P3`: annual contribution room · maxed-for-year · CPP2 (enhanced) tracking · statement check · self-employed both-portions.
**Minimum wage** `Pn`: provincial change alerts.

## Category 7 — Interest Rates & Banking
**Bank of Canada** `P1` (dates) / `P2` (rate-change): 8 announcement dates/yr · rate-change impact ("your variable payment changes ~$X") · inflation/GDP release dates.
**HISA** `P2` (needs rate-tracking backend): major-bank rate-change alerts · promo-rate expiry · CDIC coverage reminder.
**GIC** `P1` (maturity) / `P2` (rate tracker): 60/30/7 maturity · **auto-renewal warning** · best-rate tracker · redeemable vs non-redeemable.
**Credit cards** `P3`: annual-fee charge date (review worth) · points/miles expiry · statement-close (utilization) · payment-due · grace-period end · limit changes.

## Category 8 — Insurance
`Pn`: auto renewal (shop — avg $400/yr saved) · home/condo renewal · life-insurance 5-yr review · employer-coverage-ends-on-leaving · provincial health card renewal (OHIP 5-yr) · newcomer OHIP 3-mo gap.

## Category 9 — Investments
`P3`: year-end tax-loss-harvesting window (Dec 1–27) · T3/T5 availability (Mar) · DRIP open/close · annual rebalancing · dividend schedule tracker · registered-vs-non-registered tax reminder.

## Category 10 — Newcomers to Canada
`P2/P3`: SIN replacement · PR card renewal (5-yr) · citizenship eligibility (3-yr PR) · TFSA eligibility (first year) · partial-year tax filing · T1135 (foreign assets > $100K) · FHSA eligibility · foreign pension transfer.

## Category 11 — Life-Event Triggers
`P3` — user declares an event → app generates a bundle of relevant alerts:
- **Married:** spousal RRSP · beneficiary updates · combine RESP · income splitting.
- **New baby:** CCB now (retroactive only 11mo) · open RESP yr 1 (CESG) · beneficiaries · mat/parental EI · CLB if income < $50K.
- **Bought a house:** FHSA withdrawal · HBP repayment (starts 2yr after withdrawal) · property tax · CMHC · home-office deduction · principal-residence designation.
- **Turned 60/65/71:** CPP early (60) · OAS+CPP (65) · RRSP→RRIF (71) · GIS if low income.
- **Started freelancing:** GST/HST $30k threshold · quarterly installments · expense/home-office · HST number.
- **Back to school:** OSAP/StudentAid dates · RESP withdrawal rules · LLP from RRSP · tuition credit.
- **Lost job:** EI now (within 4 weeks) · severance/EI interaction · health coverage · mortgage deferral · RRSP-withdrawal tax.

---

## Content-as-data principle (important)
Because rules vary by **province** and change **annually** (indexation, new benefit amounts, threshold changes), the catalog must be stored as **versioned data** keyed by `year` + `province` + `audience`, separate from app code — so updates ship without an app release (and can later be served via remote config). This is the single highest-leverage decision for the content moat.
