import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

MortgageResult _result(MortgageStatus status, {int days = 60}) {
  final renewal = DateTime(2026, 8, 6);
  return MortgageResult(
    status: status,
    renewalDate: renewal,
    daysToRenewal: days,
    sources: [
      FigureSource('Renewal date', '2026-08-06', 'Your input'),
    ],
  );
}

void main() {
  // ── hasRequiredInput: false ────────────────────────────────────────────────

  test('no input → setup insight with editMortgageProfile CTA', () {
    final insights = mortgageInsights(
      _result(MortgageStatus.none),
      hasRequiredInput: false,
    );
    expect(insights, hasLength(1));
    final i = insights.single;
    expect(i.kind, InsightKind.setup);
    expect(i.severity, InsightSeverity.info);
    expect(i.cta?.action, InsightAction.editMortgageProfile);
  });

  test('status none but hasRequiredInput true → still setup insight', () {
    final insights = mortgageInsights(
      const MortgageResult(status: MortgageStatus.none),
      hasRequiredInput: true,
    );
    expect(insights.single.kind, InsightKind.setup);
  });

  // ── renewalSoon ────────────────────────────────────────────────────────────

  test('renewalSoon 60 days → caution foundMoney with day count in headline', () {
    final insights = mortgageInsights(
      _result(MortgageStatus.renewalSoon, days: 60),
      hasRequiredInput: true,
    );
    expect(insights, hasLength(1));
    final i = insights.single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.severity, InsightSeverity.caution);
    expect(i.headline, contains('60'));
    expect(i.isEstimate, isFalse);
    expect(i.cta?.action, InsightAction.editMortgageProfile);
  });

  test('renewalSoon subline mentions rate shopping', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalSoon, days: 90),
      hasRequiredInput: true,
    ).single;
    expect(i.subline, contains('rate'));
  });

  // ── renewalUrgent ──────────────────────────────────────────────────────────

  test('renewalUrgent 15 days → alert guardrail', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalUrgent, days: 15),
      hasRequiredInput: true,
    ).single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.alert);
    expect(i.headline, contains('15'));
  });

  test('renewalUrgent overdue (days <= 0) → "overdue" headline', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalUrgent, days: 0),
      hasRequiredInput: true,
    ).single;
    expect(i.headline, contains('overdue'));
  });

  test('renewalUrgent negative days → "overdue" headline', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalUrgent, days: -3),
      hasRequiredInput: true,
    ).single;
    expect(i.headline, contains('overdue'));
  });

  // ── renewalFar ─────────────────────────────────────────────────────────────

  test('renewalFar → info insight, no CTA', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalFar, days: 180),
      hasRequiredInput: true,
    ).single;
    expect(i.kind, InsightKind.info);
    expect(i.severity, InsightSeverity.info);
    expect(i.cta, isNull);
    expect(i.headline, contains('180'));
  });

  // ── sources ────────────────────────────────────────────────────────────────

  test('non-setup insights carry the renewal date source', () {
    final i = mortgageInsights(
      _result(MortgageStatus.renewalSoon, days: 60),
      hasRequiredInput: true,
    ).single;
    expect(i.sources, isNotEmpty);
    expect(i.sources.first.value, '2026-08-06');
  });

  // ── id ─────────────────────────────────────────────────────────────────────

  test('all insights carry id mortgage_renewal', () {
    for (final status in MortgageStatus.values) {
      final days = status == MortgageStatus.renewalUrgent
          ? 10
          : status == MortgageStatus.renewalSoon
              ? 60
              : status == MortgageStatus.renewalFar
                  ? 200
                  : 0;
      final insights = mortgageInsights(
        _result(status, days: days),
        hasRequiredInput: status != MortgageStatus.none,
      );
      for (final i in insights) {
        expect(i.id, 'mortgage_renewal');
      }
    }
  });
}
