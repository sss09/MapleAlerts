import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/core/design/tokens/maple_aurora.dart';

void main() {
  test('mapleThemeData exposes token extensions + canvas background', () {
    final td = mapleThemeData(DesignTheme.fog);
    expect(td.extension<MapleColors>()!.accent, const Color(0xFF5BC6A0));
    expect(td.extension<MapleSemantics>(), isNotNull);
    expect(td.extension<MapleAurora>(), isNotNull);
    expect(td.scaffoldBackgroundColor, const Color(0xFF070D15));
    expect(td.brightness, Brightness.dark);
  });

  test('kDesignThemes contains the 4 aurora variants', () {
    for (final id in ['emerald', 'teal', 'arctic', 'lights']) {
      expect(kDesignThemes.containsKey(id), isTrue, reason: 'missing $id');
    }
  });
}
