import '../domain/figure_source.dart';

/// A plain-language "know your rights" explainer. Content-as-data: versioned,
/// pure Dart, liftable into sibling apps. [topicInsightId] links it to a money
/// card (e.g. 'tfsa_room') for contextual "Learn more"; null = pure jargon.
class Explainer {
  final String id;
  final String? topicInsightId;
  final String title;
  final String summary;
  final List<String> points;
  final List<FigureSource> sources;
  final String? provinceNote;

  const Explainer({
    required this.id,
    this.topicInsightId,
    required this.title,
    required this.summary,
    required this.points,
    required this.sources,
    this.provinceNote,
  });
}

/// Returns the explainer linked to a money card [insightId], or null.
Explainer? explainerForInsightId(String insightId) {
  for (final e in kExplainers) {
    if (e.topicInsightId == insightId) return e;
  }
  return null;
}

const _cra = 'CRA';
const _serviceCanada = 'Service Canada';

/// Curated, verified plain-language explainers. Accuracy is the moat — figures
/// match the embedded data packs and are labelled with their source/year.
const List<Explainer> kExplainers = [
  Explainer(
    id: 'tfsa',
    topicInsightId: 'tfsa_room',
    title: 'TFSA, explained',
    summary:
        'A Tax-Free Savings Account lets your savings grow — and come out — '
        'completely tax-free.',
    points: [
      'Room starts the year you turn 18 (since 2009) and never expires — unused room carries forward forever.',
      'The 2025 and 2026 limit is \$7,000/year.',
      'Withdrawals are tax-free and are added back to your room the FOLLOWING January 1.',
      'Over-contributing costs a 1%-per-month penalty on the excess — the number one TFSA mistake.',
    ],
    sources: [FigureSource('TFSA limits & rules', '2026', _cra)],
  ),
  Explainer(
    id: 'rrsp',
    topicInsightId: 'rrsp_room',
    title: 'RRSP, explained',
    summary:
        'A Registered Retirement Savings Plan lowers your tax bill now and '
        'defers tax until you withdraw (ideally in retirement at a lower rate).',
    points: [
      'Contributions are deductible — they reduce your taxable income at your marginal rate.',
      'Room is 18% of your prior-year earned income up to an annual max, plus any carry-forward.',
      'The deadline to contribute for a tax year is ~March 1 of the next year.',
      'You can borrow from it tax-free for a first home (HBP) or schooling (LLP), with repayment rules.',
      'Over-contributing beyond a \$2,000 lifetime buffer triggers a 1%/month penalty.',
    ],
    sources: [FigureSource('RRSP deduction limit & deadline', '2026', _cra)],
  ),
  Explainer(
    id: 'fhsa',
    topicInsightId: 'fhsa',
    title: 'FHSA, explained',
    summary:
        'The First Home Savings Account is the best of both worlds for a first '
        'home: deductible like an RRSP AND tax-free on withdrawal like a TFSA.',
    points: [
      'Contribute up to \$8,000/year, \$40,000 lifetime.',
      'Contributions reduce your taxable income (like an RRSP).',
      'Withdrawals for a qualifying first home are completely tax-free (like a TFSA).',
      'Unused annual room carries forward up to \$8,000.',
      'You must be a first-time home buyer to open one; the account has a 15-year limit.',
    ],
    sources: [FigureSource('FHSA limits & rules', '2025', _cra)],
  ),
  Explainer(
    id: 'ccb',
    topicInsightId: 'ccb',
    title: 'Canada Child Benefit, explained',
    summary:
        'A tax-free monthly payment to help with the cost of raising children '
        'under 18.',
    points: [
      'Amount is based on your adjusted family net income (AFNI) and your kids’ ages.',
      'Maximum (Jul 2025–Jun 2026): \$7,997/yr under 6, \$6,748/yr ages 6–17.',
      'It is recalculated every July from your prior-year tax return — so file on time, every year.',
      'Higher family income gradually reduces the amount; it is never taxed.',
    ],
    sources: [FigureSource('CCB amounts & formula', 'Jul 2025–Jun 2026', _cra)],
  ),
  Explainer(
    id: 'oas',
    topicInsightId: 'oas',
    title: 'OAS clawback, explained',
    summary:
        'Old Age Security is reduced (“recovered”) once your income passes a '
        'threshold — the OAS recovery tax.',
    points: [
      'Starts at age 65.',
      'For 2025, OAS is reduced by 15¢ for every dollar of net income over \$93,454.',
      'It’s fully clawed back around \$151,668 (ages 65–74) / \$157,490 (75+).',
      'Splitting income with a spouse or using a TFSA (which doesn’t count toward the threshold) can reduce the clawback.',
    ],
    sources: [FigureSource('OAS recovery tax', '2025', _serviceCanada)],
  ),
  Explainer(
    id: 'gic',
    topicInsightId: 'gic',
    title: 'GICs, explained',
    summary:
        'A Guaranteed Investment Certificate locks in your money for a set term '
        'in exchange for a guaranteed interest rate.',
    points: [
      'Principal is guaranteed — you can’t lose it.',
      'Interest is fully taxable each year UNLESS the GIC is held inside a TFSA, RRSP, or FHSA.',
      'Your money is usually locked until maturity (cashable GICs are the exception).',
      'At maturity, decide deliberately: reinvest, or move the cash into a tax-shelter with room.',
    ],
    sources: [FigureSource('GIC basics', '—', _cra)],
  ),
  // ── Jargon (no card) ──────────────────────────────────────────────────────
  Explainer(
    id: 'marginal_rate',
    title: 'What is your marginal tax rate?',
    summary:
        'The tax rate on your NEXT dollar of income — combined federal + '
        'provincial. It’s higher than your average rate.',
    points: [
      'Canada’s tax is progressive: each bracket of income is taxed at its own rate.',
      'A deduction (RRSP, FHSA) saves you tax at your marginal rate — so it’s worth more the higher your income.',
      'Example: at a 30% marginal rate, a \$5,000 RRSP contribution cuts your tax by about \$1,500.',
    ],
    sources: [FigureSource('Federal + provincial brackets', '2025', _cra)],
  ),
  Explainer(
    id: 'contribution_room',
    title: 'What is contribution room?',
    summary:
        'The most you’re allowed to put into a registered account. Each account '
        'tracks it differently.',
    points: [
      'TFSA: room since age 18 (2009+), unused carries forward forever, withdrawals come back next year.',
      'RRSP: 18% of prior-year income up to a max, plus carry-forward; from your CRA Notice of Assessment.',
      'FHSA: \$8,000/year up to \$40,000 lifetime.',
      'Go over and the CRA charges a 1%/month penalty — track it.',
    ],
    sources: [FigureSource('Contribution limits', '2026', _cra)],
  ),
  Explainer(
    id: 'rrsp_vs_tfsa',
    title: 'RRSP or TFSA — which first?',
    summary:
        'A rule of thumb based on your tax rate now versus in retirement.',
    points: [
      'RRSP wins when your tax rate now is HIGHER than it will be when you withdraw (you deduct high, withdraw low).',
      'TFSA wins for flexibility, lower-income years, or to avoid pushing up income-tested benefits (OAS, CCB).',
      'Saving for a first home? The FHSA usually beats both.',
      'You don’t have to choose one forever — it can change year to year.',
    ],
    sources: [FigureSource('General guidance', '—', _cra)],
  ),
  Explainer(
    id: 'afni',
    title: 'What is adjusted family net income (AFNI)?',
    summary:
        'The income figure the CRA uses to size income-tested benefits like the '
        'Canada Child Benefit.',
    points: [
      'It’s both spouses’/partners’ net incomes combined, with a few adjustments.',
      'Lowering it (e.g. via RRSP/FHSA deductions) can INCREASE benefits like the CCB.',
      'It’s taken from your filed tax returns — another reason to file on time.',
    ],
    sources: [FigureSource('AFNI definition', '—', _cra)],
  ),
];
