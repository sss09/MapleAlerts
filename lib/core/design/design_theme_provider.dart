import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_theme.dart';
import 'maple_theme.dart';

/// User-adjustable design tweaks — persisted to [SharedPreferences].
///
/// All fields have sensible defaults so the app boots immediately without
/// waiting for the async prefs load.
class MapleTweaks {
  final String auroraId;  // 'emerald' | 'teal' | 'arctic' | 'lights'
  final String cardStyle; // 'minimal' | 'bordered' | 'solid'
  final bool warmAccents; // true = warm status colours; false = calm slate
  final bool legend;      // show legend overlay
  final bool motion;      // enable animated aurora
  final String fab;       // 'dock' | 'float' | 'radial'

  const MapleTweaks({
    this.auroraId = 'emerald',
    this.cardStyle = 'minimal',
    this.warmAccents = true,
    this.legend = false,
    this.motion = true,
    this.fab = 'dock',
  });

  MapleTweaks copyWith({
    String? auroraId,
    String? cardStyle,
    bool? warmAccents,
    bool? legend,
    bool? motion,
    String? fab,
  }) =>
      MapleTweaks(
        auroraId: auroraId ?? this.auroraId,
        cardStyle: cardStyle ?? this.cardStyle,
        warmAccents: warmAccents ?? this.warmAccents,
        legend: legend ?? this.legend,
        motion: motion ?? this.motion,
        fab: fab ?? this.fab,
      );
}

/// Manages [MapleTweaks] state and persists changes to [SharedPreferences].
class TweaksNotifier extends StateNotifier<MapleTweaks> {
  TweaksNotifier() : super(const MapleTweaks()) {
    _load();
  }

  static const String _k = 'maple_tweaks_v1';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final a = p.getString('${_k}_aurora');
      final c = p.getString('${_k}_card');
      state = state.copyWith(
        auroraId: a,
        cardStyle: c,
        warmAccents: p.getBool('${_k}_warm'),
        legend: p.getBool('${_k}_legend'),
        motion: p.getBool('${_k}_motion'),
        fab: p.getString('${_k}_fab'),
      );
    } catch (_) {
      // Prefs unavailable (e.g. tests without plugin registration) — keep defaults.
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('${_k}_aurora', state.auroraId);
      await p.setString('${_k}_card', state.cardStyle);
      await p.setBool('${_k}_warm', state.warmAccents);
      await p.setBool('${_k}_legend', state.legend);
      await p.setBool('${_k}_motion', state.motion);
      await p.setString('${_k}_fab', state.fab);
    } catch (_) {
      // Write failures are non-fatal; defaults will be used next launch.
    }
  }

  /// Replace the current tweaks and persist them.
  void set(MapleTweaks t) {
    state = t;
    _save();
  }
}

/// Exposes the user's current [MapleTweaks].
final tweaksProvider =
    StateNotifierProvider<TweaksNotifier, MapleTweaks>((ref) => TweaksNotifier());

/// Derives the active [DesignTheme] from the current tweaks.
final designThemeProvider = Provider<DesignTheme>((ref) {
  final t = ref.watch(tweaksProvider);
  return kDesignThemes[t.auroraId] ?? DesignTheme.fog;
});

/// Derives the active [ThemeData] from the current tweaks — pass to
/// [MaterialApp.theme].
final themeDataProvider = Provider<ThemeData>((ref) {
  final t = ref.watch(tweaksProvider);
  final dt = kDesignThemes[t.auroraId] ?? DesignTheme.fog;
  return mapleThemeData(dt, warmAccents: t.warmAccents, googleFontsEnabled: true);
});
