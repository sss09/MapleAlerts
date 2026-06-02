import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();
  final june = DateTime(2026, 6, 1);
  final maturingSoon = DateTime(2026, 6, 20);

  BestMove? run(MoneyProfile p) =>
      bestMove(profile: p, asOf: june, dataPack: pack);

  test('FHSA room outranks the RRSP/TFSA opportunity', () {
    final m = run(MoneyProfile(
      birthYear: 1985,
      tfsaContributed: 0, // TFSA room
      province: Province.on,
      annualIncome: 120000, // high marginal → would otherwise pick RRSP
      rrspDeductionLimit: 20000,
      rrspContributed: 0, // RRSP room
      fhsaContributed: 0, // FHSA room → should win
    ))!;
    expect(m.kind, BestMoveKind.opportunity);
    expect(m.targetInsightId, 'fhsa');
  });

  test('FHSA over-contribution is a guardrail', () {
    final m = run(const MoneyProfile(
      birthYear: 1985,
      tfsaContributed: 0,
      fhsaContributed: 42000, // over the $40k lifetime limit
    ))!;
    expect(m.kind, BestMoveKind.fixGuardrail);
    expect(m.targetInsightId, 'fhsa');
  });

  test('a maturing GIC still outranks the FHSA opportunity (time-bound first)', () {
    final m = run(MoneyProfile(
      birthYear: 1985,
      tfsaContributed: 0, // TFSA room (GIC shelters here)
      fhsaContributed: 0, // FHSA room too
      gicAmount: 20000,
      gicMaturityDate: maturingSoon,
    ))!;
    expect(m.kind, BestMoveKind.deadline);
    expect(m.title, contains('GIC'));
  });

  test('an over-contribution still outranks the FHSA opportunity', () {
    final m = run(const MoneyProfile(
      birthYear: 1985,
      tfsaContributed: 2000000, // TFSA wildly over
      fhsaContributed: 0,
    ))!;
    expect(m.kind, BestMoveKind.fixGuardrail);
    expect(m.targetInsightId, 'tfsa_room');
  });
}
