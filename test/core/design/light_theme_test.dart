import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';

void main() {
  group('daylight color tokens', () {
    test('expose a light canvas and AA-deep accent', () {
      const c = MapleColors.daylight;
      expect(c.canvas, const Color(0xFFF4F7F6));
      expect(c.surface1, const Color(0xFFFFFFFF));
      expect(c.accent, const Color(0xFF0E7D52));
      // light canvas is much brighter than the dark fog canvas
      expect(c.canvas.computeLuminance(),
          greaterThan(MapleColors.fog.canvas.computeLuminance()));
    });

    test('lerp returns same instance for identical input', () {
      const c = MapleColors.daylight;
      final l = c.lerp(c, 0.5) as MapleColors;
      expect(l.canvas, c.canvas);
    });
  });

  group('light semantic palette', () {
    test('byName resolves deepened light hues', () {
      const s = MapleSemantics.light;
      expect(s.byName('urgent').color, const Color(0xFFC2492F));
      expect(s.byName('upcoming').label, 'Upcoming');
    });
  });

  group('mapleThemeData(brightness: light)', () {
    test('builds a light-brightness theme with daylight tokens', () {
      final td = mapleThemeData(
        DesignTheme.fogLight,
        brightness: Brightness.light,
      );
      expect(td.brightness, Brightness.light);
      expect(td.scaffoldBackgroundColor, const Color(0xFFF4F7F6));
      expect(td.extension<MapleColors>()!.accent, const Color(0xFF0E7D52));
      expect(td.colorScheme.brightness, Brightness.light);
    });

    test('dark remains the default brightness (back-compat)', () {
      final td = mapleThemeData(DesignTheme.fog);
      expect(td.brightness, Brightness.dark);
    });
  });

  group('light DesignTheme registry', () {
    test('kDesignThemesLight covers all four auroras with daylight colors', () {
      for (final id in ['emerald', 'teal', 'arctic', 'lights']) {
        final dt = kDesignThemesLight[id];
        expect(dt, isNotNull, reason: 'missing light $id');
        expect(dt!.colors, MapleColors.daylight);
      }
    });
  });
}
