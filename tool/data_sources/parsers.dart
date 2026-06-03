// CRA figure parsers — pure (htmlBody -> num? / CcbFigures?), offline-testable.
//
// Each extractor anchors on STABLE VISIBLE TEXT (a column header, a benefit
// name, an "is over/up to" phrase) near the figure rather than on brittle tag
// depth, and returns null when its anchor/figure is absent. Captured live on
// 2026-06-03 into test/tool/fixtures/<id>_good.html.
//
// WORKING SOURCE URLS (also needed by sources.dart in Task 3):
//   TFSA annual limit  + RRSP dollar maximum:
//     https://www.canada.ca/en/revenue-agency/services/tax/registered-plans-administrators/pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html
//       NOTE: the plan's TFSA URL
//       (.../tax-free-savings-account/contributions.html) 301-redirects to
//       .../tax-free-savings-account/contributing.html, which NO LONGER shows
//       the dollar limit (it points users to their CRA account). The current
//       authoritative figure lives in the "TFSA and ALDA dollar limits" table
//       on the mp-rrsp-dpsp-tfsa-limits-ympe page above — used for both TFSA
//       and RRSP.
//   OAS recovery threshold (plan URL 301-redirects to this shorter path):
//     https://www.canada.ca/en/services/benefits/publicpensions/old-age-security/recovery-tax.html
//   CCB max + thresholds (plan URL 301-redirects to this "how-much" page):
//     https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit/how-much.html

import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart' show parse;

/// Parsed CCB figures (subset of the engine's CcbParams that index annually).
class CcbFigures {
  final num maxUnder6;
  final num max6to17;
  final num threshold1;
  final num threshold2;
  const CcbFigures(
      this.maxUnder6, this.max6to17, this.threshold1, this.threshold2);
}

/// Strips `$`, commas and whitespace from [raw] and parses to num, or null.
num? _money(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[\$,\s]'), '');
  return num.tryParse(cleaned);
}

/// First dollar amount found anywhere in [text], or null.
num? _firstMoney(String text) {
  final m = RegExp(r'\$\s*([0-9][0-9,]*(?:\.[0-9]+)?)').firstMatch(text);
  return m == null ? null : _money(m.group(1));
}

/// Finds the 0-based index of the column whose header text contains
/// [headerText] (case-insensitive) within [table], or -1.
int _columnIndex(Element table, String headerText) {
  final needle = headerText.toLowerCase();
  for (final th in table.querySelectorAll('th')) {
    if (th.text.toLowerCase().replaceAll(' ', ' ').contains(needle)) {
      // Count preceding <th>/<td> siblings in this header's row.
      final row = th.parent;
      if (row == null) continue;
      var idx = 0;
      for (final cell in row.children) {
        if (cell == th) return idx;
        if (cell.localName == 'th' || cell.localName == 'td') idx++;
      }
    }
  }
  return -1;
}

/// TFSA annual dollar limit: the value in the "TFSA dollar limit" column of the
/// first (latest-year) data row of the "TFSA and ALDA dollar limits" table.
num? parseTfsaLimit(String html) {
  final doc = parse(html);
  for (final table in doc.querySelectorAll('table')) {
    final col = _columnIndex(table, 'tfsa dollar limit');
    if (col < 0) continue;
    // First body row that carries data cells (skip the header row).
    for (final tr in table.querySelectorAll('tr')) {
      final tds = tr.querySelectorAll('td');
      if (tds.isEmpty) continue; // header row
      // Column index counts th + td; the row's leading <th> is the year, so the
      // TFSA <td> is at (col - 1) within the td list.
      final tdIdx = col - 1;
      if (tdIdx < 0 || tdIdx >= tds.length) return null;
      return _money(tds[tdIdx].text);
    }
  }
  return null;
}

/// RRSP dollar maximum: the "RRSP dollar limit" column value from the latest
/// row that is *complete* (its "MP limit" column holds a dollar amount). The
/// announced-but-incomplete future year (e.g. 2027, MP limit = "-") is skipped.
num? parseRrspMax(String html) {
  final doc = parse(html);
  for (final table in doc.querySelectorAll('table')) {
    final rrspCol = _columnIndex(table, 'rrsp dollar limit');
    final mpCol = _columnIndex(table, 'mp limit');
    if (rrspCol < 0 || mpCol < 0) continue;
    for (final tr in table.querySelectorAll('tr')) {
      final tds = tr.querySelectorAll('td');
      if (tds.isEmpty) continue;
      final mpIdx = mpCol - 1;
      final rrspIdx = rrspCol - 1;
      if (mpIdx < 0 || mpIdx >= tds.length) continue;
      if (rrspIdx < 0 || rrspIdx >= tds.length) continue;
      // Skip future/incomplete rows where MP limit is not a dollar amount.
      if (_money(tds[mpIdx].text) == null) continue;
      return _money(tds[rrspIdx].text);
    }
    return null; // found the columns but no complete row
  }
  return null;
}

/// OAS minimum income recovery threshold for the latest *final* income year.
/// The table pairs an "Income year" cell with a "Minimum income recovery
/// threshold" cell (tagged `headers="...tbl-0017..."` / or by column header).
/// Rows whose figures are estimates carry a `<sup>` marker — those are skipped,
/// so we return the threshold for the highest non-estimate income year.
num? parseOasRecoveryThreshold(String html) {
  final doc = parse(html);
  for (final table in doc.querySelectorAll('table')) {
    final yearCol = _columnIndex(table, 'income year');
    final minCol = _columnIndex(table, 'minimum income recovery threshold');
    if (yearCol < 0 || minCol < 0) continue;

    num? best;
    int bestYear = -1;
    for (final tr in table.querySelectorAll('tr')) {
      final tds = tr.querySelectorAll('td');
      if (tds.isEmpty) continue;
      // These cells are plain <td> with no leading <th>, so the data column
      // index equals the header column index.
      if (yearCol >= tds.length || minCol >= tds.length) continue;
      // Estimate rows are flagged with a <sup> footnote marker — skip them.
      if (tr.querySelector('sup') != null) continue;
      final year = int.tryParse(tds[yearCol].text.trim());
      final threshold = _money(tds[minCol].text);
      if (year == null || threshold == null) continue;
      if (year > bestYear) {
        bestYear = year;
        best = threshold;
      }
    }
    return best;
  }
  return null;
}

/// CCB maximum amounts + phase-out thresholds for the current payment period.
/// Anchors on the benefit-age labels ("under 6 years of age", "6 to 17 years
/// of age") and the AFNI phase-out phrases ("is over $X", "up to $Y").
CcbFigures? parseCcb(String html) {
  final doc = parse(html);
  final text = doc.body?.text.replaceAll(' ', ' ') ?? '';

  // Max amounts: first dollar amount following each age label.
  final under6 = _afterLabel(text, RegExp(r'under 6 years of age:?'));
  final age6to17 =
      _afterLabel(text, RegExp(r'(?:aged )?6 to 17 years of age:?'));

  // Phase-out thresholds: "income is over $37,487" and "up to $81,222".
  final t1 = _firstMoney(_sliceAfter(
      text, RegExp(r'start decreasing[^$]*?(?:is )?over'))) ??
      _firstMoney(_sliceAfter(text, RegExp(r'AFNI is under')));
  final t2 = _firstMoney(_sliceAfter(
      text, RegExp(r'greater than \$[0-9,]+ up to')));

  if (under6 == null || age6to17 == null || t1 == null || t2 == null) {
    return null;
  }
  return CcbFigures(under6, age6to17, t1, t2);
}

/// First dollar amount appearing after the first match of [label] in [text].
num? _afterLabel(String text, RegExp label) {
  final tail = _sliceAfter(text, label);
  return tail.isEmpty ? null : _firstMoney(tail);
}

/// Returns the substring of [text] following the first match of [marker], or ''
/// when [marker] is absent.
String _sliceAfter(String text, RegExp marker) {
  final m = marker.firstMatch(text);
  return m == null ? '' : text.substring(m.end);
}
