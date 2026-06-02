import 'package:intl/intl.dart';

/// Locale-aware Canadian-dollar (CAD) formatting for the Maple starter system.
///
/// This is the **app-level** money formatter and the canonical money token for
/// UI. It respects the active locale so the same amount renders as `$1,234.56`
/// in `en_CA` and `1 234,56 $` in `fr_CA` (non-breaking space group separator,
/// comma decimal, trailing symbol) — which is why item 1 (CAD formatting) is
/// coupled to localization (item 3).
///
/// Note: the Canadian data engine ships its own dependency-free
/// `formatDollars()` (see `lib/engine/canadian_data_engine/util/money_format.dart`)
/// so the engine stays self-contained and portable. Use [MapleMoney] in the
/// presentation layer; keep `formatDollars` for pure-Dart engine output.
class MapleMoney {
  MapleMoney._();

  /// Format [amount] as CAD.
  ///
  /// [locale]  — BCP-47 / ICU locale (e.g. `en_CA`, `fr_CA`). Defaults to the
  ///             ambient `Intl.getCurrentLocale()`.
  /// [cents]   — when true, always show two decimals; when false, none.
  /// [symbol]  — when false, omit the `$` (useful in tight UI where the column
  ///             header already implies currency).
  static String cad(
    num amount, {
    String? locale,
    bool cents = true,
    bool symbol = true,
  }) {
    final loc = locale ?? Intl.getCurrentLocale();
    final formatter = NumberFormat.currency(
      locale: loc,
      symbol: symbol ? r'$' : '',
      decimalDigits: cents ? 2 : 0,
    );
    return formatter.format(amount).trim();
  }

  /// Format [amount] as CAD, dropping the decimals when the value is a whole
  /// dollar amount and showing two decimals otherwise.
  ///
  /// Mirrors the engine's `formatDollars` behaviour but locale-aware:
  ///   `MapleMoney.cadAuto(7000)`    → `$7,000`
  ///   `MapleMoney.cadAuto(1234.5)`  → `$1,234.50`
  static String cadAuto(num amount, {String? locale, bool symbol = true}) {
    final hasCents = (amount * 100).round().abs() % 100 != 0;
    return cad(amount, locale: locale, cents: hasCents, symbol: symbol);
  }

  /// Compact CAD for dashboards / charts: `$1.2K`, `$3.4M`.
  /// Falls back to [cad] for values under 1,000.
  static String cadCompact(num amount, {String? locale}) {
    final loc = locale ?? Intl.getCurrentLocale();
    if (amount.abs() < 1000) return cad(amount, locale: loc, cents: false);
    final formatter = NumberFormat.compactCurrency(
      locale: loc,
      symbol: r'$',
      decimalDigits: 1,
    );
    return formatter.format(amount).trim();
  }
}
