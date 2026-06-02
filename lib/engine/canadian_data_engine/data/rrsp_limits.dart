/// RRSP dollar maximums by tax year, in dollars. SOURCE: CRA.
/// Verified: 2024, 2025. VERIFY 2026 before launch.
/// (The rule uses the user's NOA deduction limit for room; this table is
/// contextual/informational.)
const Map<int, int> kRrspAnnualMax = {
  2024: 31560,
  2025: 32490,
  2026: 33810,
};

/// CRA lifetime over-contribution buffer before the 1%/month penalty applies.
const double kRrspOverContributionBuffer = 2000;

/// RRSP data pack vintage.
const String kRrspDataPackVersion = 'rrsp-embedded-2026.1';

/// The next RRSP contribution deadline on or after [asOf].
///
/// Contributions in the first 60 days of a calendar year can be applied to the
/// previous tax year; the cutoff is that 60th day (≈ March 1). Returns the next
/// such cutoff that has not yet passed relative to [asOf] (date-only).
DateTime nextRrspDeadline(DateTime asOf) {
  DateTime sixtiethDay(int year) =>
      DateTime(year, 1, 1).add(const Duration(days: 59));

  final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);
  final thisYear = sixtiethDay(asOf.year);
  if (!thisYear.isBefore(asOfDate)) return thisYear;
  return sixtiethDay(asOf.year + 1);
}
