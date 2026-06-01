import 'package:flutter/material.dart';

/// A single named status in the MapleAlerts semantic palette.
///
/// [color]  — primary badge / icon color (full opacity)
/// [edge]   — border / edge highlight (partial opacity)
/// [glow]   — box-shadow glow (lower opacity)
/// [soft]   — subtle background tint (lowest opacity)
/// [label]  — human-readable display string
class MapleStatus {
  const MapleStatus({
    required this.color,
    required this.edge,
    required this.glow,
    required this.soft,
    required this.label,
  });

  final Color color;
  final Color edge;
  final Color glow;
  final Color soft;
  final String label;

  MapleStatus copyWith({
    Color? color,
    Color? edge,
    Color? glow,
    Color? soft,
    String? label,
  }) {
    return MapleStatus(
      color: color ?? this.color,
      edge: edge ?? this.edge,
      glow: glow ?? this.glow,
      soft: soft ?? this.soft,
      label: label ?? this.label,
    );
  }
}

/// Semantic status palette for MapleAlerts.
///
/// Values sourced from `docs/design/ux-design-1/ui.jsx` (constant `SEM`).
///
/// Use [byName] to resolve a status by its string key, with optional calm-mode
/// desaturation via [warmAccents] = false.
class MapleSemantics extends ThemeExtension<MapleSemantics> {
  const MapleSemantics({
    required this.urgent,
    required this.attention,
    required this.upcoming,
    required this.info,
    required this.planning,
    required this.done,
  });

  final MapleStatus urgent;
  final MapleStatus attention;
  final MapleStatus upcoming;
  final MapleStatus info;
  final MapleStatus planning;
  final MapleStatus done;

  /// Default semantic palette — sourced from ui.jsx SEM constant.
  static const MapleSemantics standard = MapleSemantics(
    urgent: MapleStatus(
      color: Color(0xFFE78B7B),
      edge: Color(0x8CE78B7B),   // rgba(231,139,123,0.55) → 0.55×255≈140≈0x8C
      glow: Color(0x4DE78B7B),   // rgba(231,139,123,0.30) → 0.30×255≈77≈0x4D
      soft: Color(0x21E78B7B),   // rgba(231,139,123,0.13) → 0.13×255≈33≈0x21
      label: 'Urgent',
    ),
    attention: MapleStatus(
      color: Color(0xFFE4B469),
      edge: Color(0x8CE4B469),   // rgba(228,180,105,0.55) → 0x8C
      glow: Color(0x42E4B469),   // rgba(228,180,105,0.26) → 0.26×255≈66≈0x42
      soft: Color(0x1FE4B469),   // rgba(228,180,105,0.12) → 0.12×255≈31≈0x1F
      label: 'Needs attention',
    ),
    upcoming: MapleStatus(
      color: Color(0xFF5FC6A0),
      edge: Color(0x805FC6A0),   // rgba(95,198,160,0.50) → 0x80
      glow: Color(0x3D5FC6A0),   // rgba(95,198,160,0.24) → 0.24×255≈61≈0x3D
      soft: Color(0x1C5FC6A0),   // rgba(95,198,160,0.11) → 0.11×255≈28≈0x1C
      label: 'Upcoming',
    ),
    info: MapleStatus(
      color: Color(0xFF71C3D6),
      edge: Color(0x8071C3D6),   // rgba(113,195,214,0.50) → 0x80
      glow: Color(0x3D71C3D6),   // rgba(113,195,214,0.24) → 0x3D
      soft: Color(0x1C71C3D6),   // rgba(113,195,214,0.11) → 0x1C
      label: 'Good to know',
    ),
    planning: MapleStatus(
      color: Color(0xFFA79CE2),
      edge: Color(0x75A79CE2),   // rgba(167,156,226,0.46) → 0.46×255≈117≈0x75
      glow: Color(0x38A79CE2),   // rgba(167,156,226,0.22) → 0.22×255≈56≈0x38
      soft: Color(0x1CA79CE2),   // rgba(167,156,226,0.11) → 0x1C
      label: 'Planning ahead',
    ),
    done: MapleStatus(
      color: Color(0xFF8A99AC),
      edge: Color(0x598A99AC),   // rgba(138,153,172,0.35) → 0.35×255≈89≈0x59
      glow: Color(0x298A99AC),   // rgba(138,153,172,0.16) → 0.16×255≈41≈0x29
      soft: Color(0x1A8A99AC),   // rgba(138,153,172,0.10) → 0x1A
      label: 'Handled',
    ),
  );

  /// The calm-mode slate used when [warmAccents] = false for warm statuses.
  static const Color _calmSlate = Color(0xFF8FA8C0);

  /// Resolve a [MapleStatus] by its string [name].
  ///
  /// Falls back to [upcoming] for unknown names. When [warmAccents] is false,
  /// the `urgent` and `attention` statuses have their [MapleStatus.color]
  /// replaced with a cool slate; all other fields are preserved.
  MapleStatus byName(String name, {bool warmAccents = true}) {
    final MapleStatus status;
    switch (name) {
      case 'urgent':
        status = urgent;
      case 'attention':
        status = attention;
      case 'upcoming':
        status = upcoming;
      case 'info':
        status = info;
      case 'planning':
        status = planning;
      case 'done':
        status = done;
      default:
        status = upcoming;
    }

    if (!warmAccents && (name == 'urgent' || name == 'attention')) {
      return status.copyWith(color: _calmSlate);
    }
    return status;
  }

  @override
  MapleSemantics copyWith({
    MapleStatus? urgent,
    MapleStatus? attention,
    MapleStatus? upcoming,
    MapleStatus? info,
    MapleStatus? planning,
    MapleStatus? done,
  }) {
    return MapleSemantics(
      urgent: urgent ?? this.urgent,
      attention: attention ?? this.attention,
      upcoming: upcoming ?? this.upcoming,
      info: info ?? this.info,
      planning: planning ?? this.planning,
      done: done ?? this.done,
    );
  }

  /// The palette is a discrete set of design tokens; lerp returns [this].
  @override
  ThemeExtension<MapleSemantics> lerp(
    ThemeExtension<MapleSemantics>? other,
    double t,
  ) {
    return this;
  }
}
