import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'data_sources/pack_merge.dart';
import 'data_sources/runner.dart';
import 'data_sources/source.dart';
import 'data_sources/sources.dart';

const _packPath = 'web/datapack/pack.json';

Future<void> main() async {
  final pack =
      jsonDecode(File(_packPath).readAsStringSync()) as Map<String, dynamic>;
  final year = DateTime.now().year;
  final sources = watchedSources();

  // Fetch each distinct URL once.
  final bodies = <String, String>{};
  final results = <String, SourceResult>{};
  for (final s in sources) {
    try {
      final key = s.url.toString();
      bodies[key] ??= await _fetch(s.url);
      final current = currentValueFor(pack, s.id, year);
      if (current == null) {
        results[s.id] = SourceResult(SourceResultKind.failure,
            reason: '${s.label}: no current value in pack to compare');
        continue;
      }
      results[s.id] = s.evaluate(bodies[key]!, current: current);
    } catch (e) {
      results[s.id] = SourceResult(SourceResultKind.failure,
          reason: '${s.label}: fetch/parse error: $e');
    }
  }

  final outcome = decideOutcome(results);
  stdout.writeln(outcome.summary);

  if (outcome.exitCode == 10) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updated = applyChange(pack, outcome.changes,
        year: year, newVersion: today);
    File(_packPath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(updated)}\n');
    // Expose the summary to the Action via an output file.
    File('.data-watch-summary.txt').writeAsStringSync(outcome.summary);
  } else if (outcome.exitCode == 20) {
    File('.data-watch-summary.txt').writeAsStringSync(outcome.summary);
  }
  exit(outcome.exitCode);
}

Future<String> _fetch(Uri url) async {
  final res = await http.get(url).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode}', uri: url);
  }
  return res.body;
}
