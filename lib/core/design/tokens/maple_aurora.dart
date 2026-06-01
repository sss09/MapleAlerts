import 'package:flutter/material.dart';

/// A single radial blob in an aurora background layer.
///
/// [color]    — ARGB color for the radial gradient center
/// [size]     — diameter in logical pixels
/// [position] — normalised Alignment in [-1, 1] space, derived from the
///              percentage (x,y) in ui.jsx via: Alignment(x/100*2-1, y/100*2-1)
class AuroraBlob {
  const AuroraBlob({
    required this.color,
    required this.size,
    required this.position,
  });

  final Color color;
  final double size;
  final Alignment position;
}

/// One complete aurora gradient system (background + atmospheric blobs).
///
/// [id]        — registry key (emerald / teal / arctic / lights)
/// [label]     — human-readable display name
/// [baseStops] — 3 colours extracted from the radial-gradient in ui.jsx AURORAS
/// [blobs]     — 3 [AuroraBlob] instances matching the blobs array in ui.jsx
class MapleAurora extends ThemeExtension<MapleAurora> {
  const MapleAurora({
    required this.id,
    required this.label,
    required this.baseStops,
    required this.blobs,
  });

  final String id;
  final String label;
  final List<Color> baseStops;
  final List<AuroraBlob> blobs;

  @override
  MapleAurora copyWith({
    String? id,
    String? label,
    List<Color>? baseStops,
    List<AuroraBlob>? blobs,
  }) {
    return MapleAurora(
      id: id ?? this.id,
      label: label ?? this.label,
      baseStops: baseStops ?? this.baseStops,
      blobs: blobs ?? this.blobs,
    );
  }

  /// The aurora palette is a discrete set of design tokens; lerp returns [this].
  @override
  ThemeExtension<MapleAurora> lerp(
    ThemeExtension<MapleAurora>? other,
    double t,
  ) {
    return this;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aurora registry — sourced from ui.jsx AURORAS constant.
//
// baseStops: the 3 colour positions in the radial-gradient string
//   radial-gradient(130% 95% at 50% -12%, <stop0> 0%, <stop1> 48%, <stop2> 100%)
//
// blobs: { c: rgba(...), s: px, x: '?%', y: '?%' }
//   → AuroraBlob(color: <rgba→Color>, size: <px>.0,
//                position: Alignment(x/100*2-1, y/100*2-1))
//
// Alpha conversions (alpha × 255, rounded to nearest integer → hex):
//   0.30→0x4D  0.26→0x42  0.22→0x38  0.28→0x47  0.24→0x3D
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, MapleAurora> kAuroras = {
  'emerald': MapleAurora(
    id: 'emerald',
    label: 'Aurora Fog',
    // base: radial-gradient(130% 95% at 50% -12%, #143029 0%, #0b1a26 48%, #070e16 100%)
    baseStops: [
      Color(0xFF143029),
      Color(0xFF0B1A26),
      Color(0xFF070E16),
    ],
    blobs: [
      // rgba(74,176,140,0.30)  s=420  x=6%  y=4%
      // alpha: 0.30×255≈77≈0x4D  RGB: 4A B0 8C
      AuroraBlob(
        color: Color(0x4D4AB08C),
        size: 420.0,
        // x=6%  → 0.06*2-1 = -0.88
        // y=4%  → 0.04*2-1 = -0.92
        position: Alignment(-0.88, -0.92),
      ),
      // rgba(52,116,128,0.26)  s=460  x=80%  y=0%
      // alpha: 0.26×255≈66≈0x42  RGB: 34 74 80
      AuroraBlob(
        color: Color(0x42347480),
        size: 460.0,
        // x=80% → 0.80*2-1 =  0.60
        // y=0%  → 0.00*2-1 = -1.00
        position: Alignment(0.60, -1.00),
      ),
      // rgba(58,96,142,0.22)   s=480  x=58%  y=64%
      // alpha: 0.22×255≈56≈0x38  RGB: 3A 60 8E
      AuroraBlob(
        color: Color(0x383A608E),
        size: 480.0,
        // x=58% → 0.58*2-1 =  0.16
        // y=64% → 0.64*2-1 =  0.28
        position: Alignment(0.16, 0.28),
      ),
    ],
  ),

  'teal': MapleAurora(
    id: 'teal',
    label: 'Teal Frost',
    // base: radial-gradient(130% 95% at 50% -12%, #103a3a 0%, #0a2230 48%, #060c14 100%)
    baseStops: [
      Color(0xFF103A3A),
      Color(0xFF0A2230),
      Color(0xFF060C14),
    ],
    blobs: [
      // rgba(58,186,168,0.30)  s=420  x=10%  y=2%
      // alpha: 0x4D  RGB: 3A BA A8
      AuroraBlob(
        color: Color(0x4D3ABAA8),
        size: 420.0,
        // x=10% → -0.80   y=2% → -0.96
        position: Alignment(-0.80, -0.96),
      ),
      // rgba(40,128,140,0.26)  s=450  x=82%  y=6%
      // alpha: 0x42  RGB: 28 80 8C
      AuroraBlob(
        color: Color(0x4228808C),
        size: 450.0,
        // x=82% → 0.64   y=6% → -0.88
        position: Alignment(0.64, -0.88),
      ),
      // rgba(48,104,150,0.22)  s=470  x=52%  y=62%
      // alpha: 0x38  RGB: 30 68 96
      AuroraBlob(
        color: Color(0x38306896),
        size: 470.0,
        // x=52% → 0.04   y=62% → 0.24
        position: Alignment(0.04, 0.24),
      ),
    ],
  ),

  'arctic': MapleAurora(
    id: 'arctic',
    label: 'Arctic Steel',
    // base: radial-gradient(130% 95% at 50% -12%, #15324e 0%, #0c2036 48%, #060d18 100%)
    baseStops: [
      Color(0xFF15324E),
      Color(0xFF0C2036),
      Color(0xFF060D18),
    ],
    blobs: [
      // rgba(74,148,200,0.28)  s=420  x=8%   y=4%
      // alpha: 0.28×255≈71≈0x47  RGB: 4A 94 C8
      AuroraBlob(
        color: Color(0x474A94C8),
        size: 420.0,
        // x=8%  → -0.84   y=4% → -0.92
        position: Alignment(-0.84, -0.92),
      ),
      // rgba(86,116,190,0.24)  s=450  x=82%  y=2%
      // alpha: 0x3D  RGB: 56 74 BE
      AuroraBlob(
        color: Color(0x3D5674BE),
        size: 450.0,
        // x=82% → 0.64   y=2% → -0.96
        position: Alignment(0.64, -0.96),
      ),
      // rgba(52,150,160,0.22)  s=450  x=58%  y=66%
      // alpha: 0x38  RGB: 34 96 A0
      AuroraBlob(
        color: Color(0x383496A0),
        size: 450.0,
        // x=58% → 0.16   y=66% → 0.32
        position: Alignment(0.16, 0.32),
      ),
    ],
  ),

  'lights': MapleAurora(
    id: 'lights',
    label: 'Northern Lights',
    // base: radial-gradient(130% 95% at 50% -12%, #133436 0%, #0b1f2e 46%, #080d1a 100%)
    baseStops: [
      Color(0xFF133436),
      Color(0xFF0B1F2E),
      Color(0xFF080D1A),
    ],
    blobs: [
      // rgba(70,184,150,0.28)   s=420  x=4%   y=6%
      // alpha: 0x47  RGB: 46 B8 96
      AuroraBlob(
        color: Color(0x4746B896),
        size: 420.0,
        // x=4%  → -0.92   y=6% → -0.88
        position: Alignment(-0.92, -0.88),
      ),
      // rgba(126,108,196,0.22)  s=450  x=84%  y=4%
      // alpha: 0x38  RGB: 7E 6C C4
      AuroraBlob(
        color: Color(0x387E6CC4),
        size: 450.0,
        // x=84% → 0.68   y=4% → -0.92
        position: Alignment(0.68, -0.92),
      ),
      // rgba(48,150,156,0.22)   s=440  x=54%  y=60%
      // alpha: 0x38  RGB: 30 96 9C
      AuroraBlob(
        color: Color(0x3830969C),
        size: 440.0,
        // x=54% → 0.08   y=60% → 0.20
        position: Alignment(0.08, 0.20),
      ),
    ],
  ),
};
