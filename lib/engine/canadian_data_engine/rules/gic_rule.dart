import '../domain/figure_source.dart';
import '../domain/gic_holding.dart';
import '../domain/money_profile.dart';
import '../util/money_format.dart';

/// A GIC maturing within this many days is "maturing soon" — the window in
/// which sheltering the freed-up cash becomes the best move.
const int kGicMaturingSoonDays = 60;

/// Computes the maturity state of the user's tracked GIC. Deterministic, total.
GicResult gicRule({
  required MoneyProfile profile,
  required DateTime asOf,
}) {
  final amount = profile.gicAmount ?? 0;
  final maturity = profile.gicMaturityDate;

  if (amount <= 0 || maturity == null) {
    return const GicResult(
      status: GicStatus.none,
      amount: 0,
      maturityDate: null,
      daysToMaturity: 0,
    );
  }

  final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);
  final matDate = DateTime(maturity.year, maturity.month, maturity.day);
  final days = matDate.difference(asOfDate).inDays;

  final GicStatus status;
  if (days < 0) {
    status = GicStatus.matured;
  } else if (days <= kGicMaturingSoonDays) {
    status = GicStatus.maturingSoon;
  } else {
    status = GicStatus.later;
  }

  return GicResult(
    status: status,
    amount: amount,
    maturityDate: maturity,
    daysToMaturity: days,
    sources: [
      FigureSource('GIC principal', formatDollars(amount), 'Your input'),
      FigureSource(
        'Matures',
        '${maturity.year}-${maturity.month.toString().padLeft(2, '0')}-${maturity.day.toString().padLeft(2, '0')}',
        'Your input',
      ),
    ],
  );
}
