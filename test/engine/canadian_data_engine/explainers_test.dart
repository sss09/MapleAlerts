import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  test('every money card topic has a linked explainer', () {
    for (final id in ['tfsa_room', 'rrsp_room', 'fhsa', 'ccb', 'oas', 'gic']) {
      final e = explainerForInsightId(id);
      expect(e, isNotNull, reason: 'no explainer for $id');
      expect(e!.title, isNotEmpty);
      expect(e.points, isNotEmpty);
      expect(e.sources, isNotEmpty);
    }
  });

  test('includes jargon explainers not tied to a card', () {
    final jargon = kExplainers.where((e) => e.topicInsightId == null).toList();
    expect(jargon, isNotEmpty);
    expect(jargon.any((e) => e.id == 'marginal_rate'), isTrue);
  });

  test('unknown insight id has no explainer', () {
    expect(explainerForInsightId('nope'), isNull);
  });

  test('every explainer has a title, summary, points and a source', () {
    expect(kExplainers, isNotEmpty);
    for (final e in kExplainers) {
      expect(e.title, isNotEmpty, reason: e.id);
      expect(e.summary, isNotEmpty, reason: e.id);
      expect(e.points, isNotEmpty, reason: e.id);
      expect(e.sources, isNotEmpty, reason: e.id);
    }
  });
}
