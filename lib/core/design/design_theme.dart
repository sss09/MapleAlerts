import 'tokens/maple_colors.dart';
import 'tokens/maple_semantics.dart';
import 'tokens/maple_aurora.dart';

/// A fully resolved design theme: color tokens + semantic palette + aurora.
///
/// [kDesignThemes] maps the four aurora IDs to their [DesignTheme] instances.
/// [DesignTheme.fog] is the default emerald/fog variant.
class DesignTheme {
  final String id;
  final MapleColors colors;
  final MapleSemantics semantics;
  final MapleAurora aurora;

  const DesignTheme({
    required this.id,
    required this.colors,
    required this.semantics,
    required this.aurora,
  });

  /// Default dark design theme — emerald aurora + fog color tokens.
  static final DesignTheme fog = DesignTheme(
    id: 'emerald',
    colors: MapleColors.fog,
    semantics: MapleSemantics.standard,
    aurora: kAuroras['emerald']!,
  );

  /// Default light design theme — emerald aurora + daylight color tokens.
  ///
  /// The aurora art is shared with the dark variant; [AuroraBackground] and the
  /// glass widgets read the ambient [Brightness] to render a light wash rather
  /// than a dark night sky.
  static final DesignTheme fogLight = DesignTheme(
    id: 'emerald',
    colors: MapleColors.daylight,
    semantics: MapleSemantics.light,
    aurora: kAuroras['emerald']!,
  );
}

/// One dark [DesignTheme] per aurora variant (colors + semantics shared for now).
final Map<String, DesignTheme> kDesignThemes = {
  for (final entry in kAuroras.entries)
    entry.key: DesignTheme(
      id: entry.key,
      colors: MapleColors.fog,
      semantics: MapleSemantics.standard,
      aurora: entry.value,
    ),
};

/// One light [DesignTheme] per aurora variant — daylight colors + light semantics.
final Map<String, DesignTheme> kDesignThemesLight = {
  for (final entry in kAuroras.entries)
    entry.key: DesignTheme(
      id: entry.key,
      colors: MapleColors.daylight,
      semantics: MapleSemantics.light,
      aurora: entry.value,
    ),
};
