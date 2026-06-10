import '../domain/figure_source.dart';
import '../domain/money_profile.dart';

enum MortgageStatus { none, renewalFar, renewalSoon, renewalUrgent }

const int kMortgageSoonDays = 120; // 4 months — when to start shopping
const int kMortgageUrgentDays = 30;

class MortgageResult {
  final MortgageStatus status;
  final DateTime? renewalDate;
  final int daysToRenewal;
  final List<FigureSource> sources;
  const MortgageResult({
    required this.status,
    this.renewalDate,
    this.daysToRenewal = 0,
    this.sources = const [],
  });
}

MortgageResult mortgageRule({
  required MoneyProfile profile,
  required DateTime asOf,
}) {
  final renewal = profile.mortgageRenewalDate;
  if (renewal == null) return const MortgageResult(status: MortgageStatus.none);
  final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);
  final renewDate = DateTime(renewal.year, renewal.month, renewal.day);
  final days = renewDate.difference(asOfDate).inDays;
  final status = days < 0
      ? MortgageStatus.renewalUrgent
      : days <= kMortgageUrgentDays
          ? MortgageStatus.renewalUrgent
          : days <= kMortgageSoonDays
              ? MortgageStatus.renewalSoon
              : MortgageStatus.renewalFar;
  return MortgageResult(
    status: status,
    renewalDate: renewal,
    daysToRenewal: days,
    sources: [
      FigureSource(
        'Renewal date',
        '${renewal.year}-${renewal.month.toString().padLeft(2, '0')}-${renewal.day.toString().padLeft(2, '0')}',
        'Your input',
      ),
    ],
  );
}
