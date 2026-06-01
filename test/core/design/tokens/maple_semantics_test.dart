import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';

void main() {
  const s = MapleSemantics.standard;
  test('exposes 6 statuses with labels', () {
    expect(s.byName('urgent').label, 'Urgent');
    expect(s.byName('upcoming').color, const Color(0xFF5FC6A0));
    expect(s.byName('done').label, 'Handled');
  });
  test('calm mode cools urgent/attention to slate', () {
    expect(s.byName('urgent', warmAccents: false).color, const Color(0xFF8FA8C0));
    expect(s.byName('upcoming', warmAccents: false).color, const Color(0xFF5FC6A0));
  });
  test('unknown status falls back to upcoming', () {
    expect(s.byName('zzz').color, s.byName('upcoming').color);
  });
}
