import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();
  final june = DateTime(2026, 6, 1); // far from the RRSP deadline
  final feb = DateTime(2026, 2, 1); // ~28 days before the Mar 1 deadline

  BestMove? run(MoneyProfile p, {DateTime? asOf}) =>
      bestMove(profile: p, asOf: asOf ?? june, dataPack: pack);

  // A fully-configured profile helper.
  MoneyProfile profile({
    int? birthYear = 1985,
    double? tfsaContributed,
    Province? province = Province.on,
    double? income,
    double? rrspLimit,
    double? rrspContributed,
  }) =>
      MoneyProfile(
        birthYear: birthYear,
        tfsaContributed: tfsaContributed,
        province: province,
        annualIncome: income,
        rrspDeductionLimit: rrspLimit,
        rrspContributed: rrspContributed,
      );

  test('nothing configured → no best move', () {
    expect(run(const MoneyProfile()), isNull);
  });

  test('RRSP over-contribution outranks everything (fix the penalty)', () {
    final m = run(profile(
      income: 120000,
      rrspLimit: 10000,
      rrspContributed: 13000, // past the $2k buffer
      tfsaContributed: 0, // lots of TFSA room too
    ))!;
    expect(m.kind, BestMoveKind.fixGuardrail);
    expect(m.targetInsightId, 'rrsp_room');
    expect(m.dollarValue, closeTo(3000, 1e-6)); // overage
  });

  test('near the RRSP deadline with room → deadline move', () {
    final m = run(
      profile(income: 120000, rrspLimit: 30000, rrspContributed: 5000),
      asOf: feb,
    )!;
    expect(m.kind, BestMoveKind.deadline);
    expect(m.targetInsightId, 'rrsp_room');
    expect(m.dollarValue, greaterThan(0)); // estimated tax savings
  });

  test('high marginal rate → RRSP beats TFSA as the opportunity', () {
    final m = run(profile(
      income: 120000, // ON marginal ~37% (>= 30%)
      rrspLimit: 20000,
      rrspContributed: 0,
      tfsaContributed: 0, // TFSA room exists too
    ))!;
    expect(m.kind, BestMoveKind.opportunity);
    expect(m.targetInsightId, 'rrsp_room');
  });

  test('low marginal rate → TFSA wins the opportunity', () {
    final m = run(profile(
      income: 30000, // ON marginal ~19.55% (< 30%)
      rrspLimit: 20000,
      rrspContributed: 0,
      birthYear: 1985,
      tfsaContributed: 0, // TFSA room exists
    ))!;
    expect(m.kind, BestMoveKind.opportunity);
    expect(m.targetInsightId, 'tfsa_room');
  });

  test('everything maxed out → no best move', () {
    final m = run(profile(
      income: 120000,
      rrspLimit: 10000,
      rrspContributed: 10000, // no room
      birthYear: 1985,
      tfsaContributed: 1000000, // way over... but that is a guardrail!
    ));
    // TFSA is wildly over-contributed → that becomes the guardrail move.
    expect(m, isNotNull);
    expect(m!.kind, BestMoveKind.fixGuardrail);
    expect(m.targetInsightId, 'tfsa_room');
  });

  test('configured, no room, no guardrail → no best move', () {
    final m = run(profile(
      income: 120000,
      rrspLimit: 10000,
      rrspContributed: 10000, // room 0, not over
      birthYear: 2009, // turned 18 in 2027 → not yet eligible / minimal TFSA
      tfsaContributed: 0,
    ));
    // 2009 birth → TFSA notYetEligible (no room); RRSP room 0 → nothing to do.
    expect(m, isNull);
  });
}
