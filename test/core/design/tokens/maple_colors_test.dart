import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';

void main() {
  test('MapleColors holds foundation colors and lerps', () {
    const c = MapleColors.fog;
    expect(c.canvas, const Color(0xFF070D15));
    expect(c.accent, const Color(0xFF5BC6A0));
    final l = c.lerp(c, 0.5) as MapleColors;
    expect(l.canvas, c.canvas);
  });
}
