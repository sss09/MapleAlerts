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

  /// Default design theme — emerald aurora + fog color tokens.
  static final DesignTheme fog = DesignTheme(
    id: 'emerald',
    colors: MapleColors.fog,
    semantics: MapleSemantics.standard,
    aurora: kAuroras['emerald']!,
  );
}

/// One [DesignTheme] per aurora variant (colors + semantics are shared for now).
final Map<String, DesignTheme> kDesignThemes = {
  for (final entry in kAuroras.entries)
    entry.key: DesignTheme(
      id: entry.key,
      colors: MapleColors.fog,
      semantics: MapleSemantics.standard,
      aurora: entry.value,
    ),
};
