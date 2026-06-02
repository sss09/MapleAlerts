import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

/// Cumulative TFSA limit for someone eligible since 2009, as of 2026.
/// 2009-2012: 5000x4=20000 · 2013-2014: 5500x2=11000 · 2015: 10000 ·
/// 2016-2018: 5500x3=16500 · 2019-2022: 6000x4=24000 · 2023: 6500 ·
/// 2024-2026: 7000x3=21000  => 109000
const _cumulativeSince2009AsOf2026 = 109000.0;

/// Cumulative limit for someone who turned 18 in 2018, as of 2026.
/// 2018: 5500 · 2019-2022: 24000 · 2023: 6500 · 2024-2026: 21000 => 57000
const _cumulativeFrom2018AsOf2026 = 57000.0;

void main() {
  final asOf2026 = DateTime(2026, 6, 1);
  final pack = const EmbeddedDataPack();

  TfsaRoomResult run(int? birthYear, double? contributed) => tfsaRule(
        profile: MoneyProfile(birthYear: birthYear, tfsaContributed: contributed),
        asOf: asOf2026,
        dataPack: pack,
      );

  group('eligibility & cumulative limit', () {
    test('birth before 2009 clamps the start year to 2009', () {
      final r = run(1990, 0); // turned 18 in 2008
      expect(r.startYear, 2009);
      expect(r.cumulativeLimit, _cumulativeSince2009AsOf2026);
    });

    test('start year is the year the user turned 18', () {
      final r = run(2000, 0); // turned 18 in 2018
      expect(r.startYear, 2018);
      expect(r.cumulativeLimit, _cumulativeFrom2018AsOf2026);
    });

    test('turning 18 in the current year yields just this year\'s limit', () {
      final r = run(2008, 0); // turns 18 in 2026
      expect(r.startYear, 2026);
      expect(r.cumulativeLimit, 7000);
      expect(r.currentYearLimit, 7000);
    });

    test('under 18 is notYetEligible with zero room', () {
      final r = run(2010, 0); // turns 18 in 2028
      expect(r.status, TfsaStatus.notYetEligible);
      expect(r.room, 0);
    });
  });

  group('room & status', () {
    test('zero contributed gives full room and healthy status', () {
      final r = run(1990, 0);
      expect(r.room, _cumulativeSince2009AsOf2026);
      expect(r.status, TfsaStatus.healthy);
      expect(r.isEstimate, isTrue);
    });

    test('over-contribution flags overContributed with the true overage', () {
      final r = run(2008, 8000); // limit 7000
      expect(r.status, TfsaStatus.overContributed);
      expect(r.room, -1000); // true overage preserved (not clamped)
    });

    test('room of exactly 1000 is nearLimit (boundary)', () {
      final r = run(2008, 6000); // 7000 - 6000 = 1000
      expect(r.room, 1000);
      expect(r.status, TfsaStatus.nearLimit);
    });

    test('room of exactly 0 is nearLimit (boundary)', () {
      final r = run(2008, 7000);
      expect(r.room, 0);
      expect(r.status, TfsaStatus.nearLimit);
    });

    test('room just above 1000 is healthy', () {
      final r = run(2008, 5999); // 7000 - 5999 = 1001
      expect(r.room, 1001);
      expect(r.status, TfsaStatus.healthy);
    });
  });

  group('sources & trust framing', () {
    test('result carries the current-year limit source from CRA', () {
      final r = run(1990, 0);
      expect(r.sources, isNotEmpty);
      final limitSource = r.sources.firstWhere(
        (s) => s.source == 'CRA',
        orElse: () => throw StateError('no CRA source'),
      );
      expect(limitSource.value, contains('7,000'));
      expect(r.isEstimate, isTrue);
    });
  });

  group('embedded data pack', () {
    test('exposes a non-empty pack version and the 2026 limit', () {
      expect(pack.packVersion, isNotEmpty);
      expect(pack.tfsaAnnualLimit(2026), 7000);
    });
  });
}
