import 'package:flutter/material.dart';

/// Foundation color tokens for MapleAlerts — cool navy / blue-steel palette.
///
/// Values sourced from `docs/design/ux-design-1/ui.jsx` (constant `C`, `TEXT`,
/// `MUTED`, `FAINT`, `GREEN`, `GREEN_HI`).
class MapleColors extends ThemeExtension<MapleColors> {
  const MapleColors({
    required this.canvas,
    required this.surface1,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentHi,
    required this.slate,
  });

  final Color canvas;
  final Color surface1;
  final Color surface2;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentHi;
  final Color slate;

  /// The default dark fog theme — icy slate / blue-steel, low saturation.
  static const MapleColors fog = MapleColors(
    canvas: Color(0xFF070D15),       // C.bg   #070d15
    surface1: Color(0xFF0B1320),     // C.s1   #0b1320
    surface2: Color(0xFF101D26),     // C.s2   #101d26
    line: Color(0x1A9CB2C8),         // rgba(156,178,200,0.10) → alpha 0.10≈0x1A
    lineStrong: Color(0x2E9CB2C8),   // rgba(156,178,200,0.18) → alpha 0.18≈0x2E
    text: Color(0xFFE6EDF3),         // TEXT   #E6EDF3
    muted: Color(0x9EB4C4D4),        // rgba(180,196,212,0.62) → alpha 0.62≈0x9E
    faint: Color(0x61B4C4D4),        // rgba(180,196,212,0.38) → alpha 0.38≈0x61
    accent: Color(0xFF5BC6A0),       // GREEN  #5BC6A0
    accentHi: Color(0xFF62D2A8),     // GREEN_HI #62D2A8
    slate: Color(0xFF8A99AC),        // C.slate #8A99AC
  );

  /// The light ("daylight") theme — soft cool off-white with a green-steel
  /// tint, designed to pair with [MapleSemantics.light]. Mirrors the [fog]
  /// token roles so widgets that read the extension work unchanged.
  ///
  /// Accent is a deeper emerald than [fog] so it clears WCAG AA contrast on a
  /// near-white surface; [accentHi] is the brighter emerald used for glows and
  /// gradient highlights.
  static const MapleColors daylight = MapleColors(
    canvas: Color(0xFFF4F7F6),       // soft off-white, faint cool tint
    surface1: Color(0xFFFFFFFF),     // pure white cards
    surface2: Color(0xFFEAF0EE),     // raised / inset light surface
    line: Color(0x14122A22),         // rgba(18,42,34,0.08) hairline on light
    lineStrong: Color(0x24122A22),   // rgba(18,42,34,0.14) stronger divider
    text: Color(0xFF0E1A16),         // near-black green-navy ink
    muted: Color(0x99142A22),        // rgba(20,42,34,0.60) secondary text
    faint: Color(0x59142A22),        // rgba(20,42,34,0.35) tertiary text
    accent: Color(0xFF0E7D52),       // deep emerald — AA on white
    accentHi: Color(0xFF13A06C),     // brighter emerald for glow/gradient
    slate: Color(0xFF5E6E7C),        // muted slate ink
  );

  @override
  MapleColors copyWith({
    Color? canvas,
    Color? surface1,
    Color? surface2,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? accentHi,
    Color? slate,
  }) {
    return MapleColors(
      canvas: canvas ?? this.canvas,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      accentHi: accentHi ?? this.accentHi,
      slate: slate ?? this.slate,
    );
  }

  @override
  ThemeExtension<MapleColors> lerp(
    ThemeExtension<MapleColors>? other,
    double t,
  ) {
    if (other is! MapleColors) return this;
    return MapleColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHi: Color.lerp(accentHi, other.accentHi, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
    );
  }
}
