import '../data/data_pack.dart';
import '../data/tax_brackets.dart';
import '../domain/province.dart';

/// The marginal rate of a progressive bracket table at [income] — the rate of
/// the highest bracket whose [TaxBracket.lowerBound] is ≤ income.
double bracketMarginalRate(List<TaxBracket> brackets, double income) {
  var rate = brackets.isEmpty ? 0.0 : brackets.first.rate;
  for (final b in brackets) {
    if (income >= b.lowerBound) {
      rate = b.rate;
    } else {
      break;
    }
  }
  return rate;
}

/// Combined federal + provincial marginal tax rate (a fraction, e.g. 0.2965)
/// for [income] in [province] for the given tax [year].
///
/// This is the rate at which an RRSP deduction reduces tax — used to estimate
/// "contributing $X saves ≈ $X × rate." A labelled estimate that assumes the
/// contribution stays within the current bracket.
double marginalTaxRate({
  required int year,
  required Province province,
  required double income,
  required DataPack dataPack,
}) {
  final federal = bracketMarginalRate(dataPack.federalBrackets(year), income);
  final provincial =
      bracketMarginalRate(dataPack.provincialBrackets(year, province), income);
  return federal + provincial;
}
