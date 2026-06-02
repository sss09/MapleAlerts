import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();
  final asOf = DateTime(2026, 6, 2);
  final maturingSoon = DateTime(2026, 6, 20); // 18 days out

  BestMove? run(MoneyProfile p) =>
      bestMove(profile: p, asOf: asOf, dataPack: pack);

  test('maturing GIC + TFSA room → shelter into TFSA (value capped to room)', () {
    final m = run(MoneyProfile(
      birthYear: 1985, // lots of TFSA room
      tfsaContributed: 0,
      gicAmount: 20000,
      gicMaturityDate: maturingSoon,
    ))!;
    expect(m.kind, BestMoveKind.deadline);
    expect(m.targetInsightId, 'tfsa_room');
    expect(m.dollarValue, 20000); // min(20000 GIC, ~109k room)
  });

  test('value is capped at the available room when the GIC is larger', () {
    final m = run(MoneyProfile(
      birthYear: 2008, // turned 18 in 2026 → room = 2026 limit $7,000
      tfsaContributed: 0,
      gicAmount: 50000,
      gicMaturityDate: maturingSoon,
    ))!;
    expect(m.targetInsightId, 'tfsa_room');
    expect(m.dollarValue, 7000); // capped to TFSA room
  });

  test('falls back to RRSP when there is no TFSA room', () {
    final m = run(MoneyProfile(
      birthYear: 2009, // TFSA not yet eligible → no room
      tfsaContributed: 0,
      province: Province.on,
      annualIncome: 80000,
      rrspDeductionLimit: 20000,
      rrspContributed: 0,
      gicAmount: 30000,
      gicMaturityDate: maturingSoon,
    ))!;
    expect(m.kind, BestMoveKind.deadline);
    expect(m.targetInsightId, 'rrsp_room');
    expect(m.dollarValue, 20000); // min(30000, 20000 RRSP room)
  });

  test('an over-contribution still outranks a maturing GIC', () {
    final m = run(MoneyProfile(
      birthYear: 1985,
      tfsaContributed: 0,
      province: Province.on,
      annualIncome: 80000,
      rrspDeductionLimit: 10000,
      rrspContributed: 13000, // over the buffer
      gicAmount: 20000,
      gicMaturityDate: maturingSoon,
    ))!;
    expect(m.kind, BestMoveKind.fixGuardrail);
    expect(m.targetInsightId, 'rrsp_room');
  });

  test('no room anywhere → GIC does not produce a move', () {
    final m = run(MoneyProfile(
      birthYear: 2009, // no TFSA room
      tfsaContributed: 0,
      gicAmount: 20000,
      gicMaturityDate: maturingSoon,
    ));
    expect(m, isNull);
  });
}
