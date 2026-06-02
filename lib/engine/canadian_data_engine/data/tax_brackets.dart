import '../domain/province.dart';

/// One marginal tax bracket: [rate] (a fraction, e.g. 0.205) applies to income
/// at or above [lowerBound] up to the next bracket's [lowerBound].
class TaxBracket {
  final double lowerBound;
  final double rate;
  const TaxBracket(this.lowerBound, this.rate);
}

/// Tax-data pack vintage. Bump when any bracket table changes.
const String kTaxDataPackVersion = 'tax-embedded-2025.1';

/// Federal marginal brackets, 2025 tax year.
///
/// SOURCE: CRA. The lowest-bracket rate is the 2025 *full-year* effective rate
/// (14.5%) reflecting the mid-2025 rate cut; it becomes 14% for 2026+. Figures
/// used to produce a labelled estimate.
const List<TaxBracket> kFederalBrackets2025 = [
  TaxBracket(0, 0.145),
  TaxBracket(57375, 0.205),
  TaxBracket(114750, 0.26),
  TaxBracket(177882, 0.29),
  TaxBracket(253414, 0.33),
];

/// Provincial/territorial marginal brackets, 2025 tax year.
///
/// SOURCES: provincial finance / CRA. Verified: federal, ON, BC, AB, QC.
/// VERIFY before launch: MB, SK, NS, NB, NL, PE, YT, NT, NU.
/// QC note: provincial brackets only — the 16.5% Quebec federal abatement is
/// NOT applied, so the QC combined estimate is slightly conservative (high).
const Map<Province, List<TaxBracket>> kProvincialBrackets2025 = {
  Province.on: [
    TaxBracket(0, 0.0505),
    TaxBracket(52886, 0.0915),
    TaxBracket(105775, 0.1116),
    TaxBracket(150000, 0.1216),
    TaxBracket(220000, 0.1316),
  ],
  Province.bc: [
    TaxBracket(0, 0.0506),
    TaxBracket(49279, 0.077),
    TaxBracket(98560, 0.105),
    TaxBracket(113158, 0.1229),
    TaxBracket(137407, 0.147),
    TaxBracket(186306, 0.168),
    TaxBracket(259829, 0.205),
  ],
  Province.ab: [
    TaxBracket(0, 0.08),
    TaxBracket(60000, 0.10),
    TaxBracket(151234, 0.12),
    TaxBracket(181481, 0.13),
    TaxBracket(241974, 0.14),
    TaxBracket(362961, 0.15),
  ],
  Province.qc: [
    TaxBracket(0, 0.14),
    TaxBracket(53255, 0.19),
    TaxBracket(106495, 0.24),
    TaxBracket(129590, 0.2575),
  ],
  Province.mb: [
    TaxBracket(0, 0.108),
    TaxBracket(47000, 0.1275),
    TaxBracket(100000, 0.174),
  ],
  Province.sk: [
    TaxBracket(0, 0.105),
    TaxBracket(53463, 0.125),
    TaxBracket(152750, 0.145),
  ],
  Province.ns: [
    TaxBracket(0, 0.0879),
    TaxBracket(30507, 0.1495),
    TaxBracket(61015, 0.1667),
    TaxBracket(95883, 0.175),
    TaxBracket(154650, 0.21),
  ],
  Province.nb: [
    TaxBracket(0, 0.094),
    TaxBracket(51306, 0.14),
    TaxBracket(102614, 0.16),
    TaxBracket(190060, 0.195),
  ],
  Province.nl: [
    TaxBracket(0, 0.087),
    TaxBracket(44192, 0.145),
    TaxBracket(88382, 0.158),
    TaxBracket(157792, 0.178),
    TaxBracket(220910, 0.198),
    TaxBracket(282214, 0.208),
    TaxBracket(564429, 0.213),
    TaxBracket(1128858, 0.218),
  ],
  Province.pe: [
    TaxBracket(0, 0.095),
    TaxBracket(33328, 0.1347),
    TaxBracket(64656, 0.166),
    TaxBracket(105000, 0.1762),
    TaxBracket(140000, 0.19),
  ],
  Province.yt: [
    TaxBracket(0, 0.064),
    TaxBracket(57375, 0.09),
    TaxBracket(114750, 0.109),
    TaxBracket(177882, 0.128),
    TaxBracket(500000, 0.15),
  ],
  Province.nt: [
    TaxBracket(0, 0.059),
    TaxBracket(51964, 0.086),
    TaxBracket(103930, 0.122),
    TaxBracket(168967, 0.1405),
  ],
  Province.nu: [
    TaxBracket(0, 0.04),
    TaxBracket(54707, 0.07),
    TaxBracket(109413, 0.09),
    TaxBracket(177881, 0.115),
  ],
};
