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
  final String themeMode; // 'system' | 'light' | 'dark'

  const MapleTweaks({
    this.auroraId = 'emerald',
    this.cardStyle = 'minimal',
    this.warmAccents = true,
    this.legend = false,
    this.motion = true,
    this.fab = 'dock',
    this.themeMode = 'dark',
  });

  /// Maps the persisted [themeMode] string to a Flutter [ThemeMode].
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  MapleTweaks copyWith({
    String? auroraId,
    String? cardStyle,
    bool? warmAccents,
    bool? legend,
    bool? motion,
    String? fab,
    String? themeMode,
  }) =>
      MapleTweaks(
        auroraId: auroraId ?? this.auroraId,
        cardStyle: cardStyle ?? this.cardStyle,
        warmAccents: warmAccents ?? this.warmAccents,
        legend: legend ?? this.legend,
        motion: motion ?? this.motion,
        fab: fab ?? this.fab,
        themeMode: themeMode ?? this.themeMode,
      );
}

/// Manages [MapleTweaks] state and persists changes to [SharedPreferences].
class TweaksNotifier extends StateNotifier<MapleTweaks> {
  TweaksNotifier() : super(const MapleTweaks()) {
    _load();
  }

  static const String _k = 'maple_tweaks_v2';

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
        themeMode: p.getString('${_k}_themeMode'),
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
      await p.setString('${_k}_themeMode', state.themeMode);
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

/// Derives the active dark [DesignTheme] from the current tweaks.
final designThemeProvider = Provider<DesignTheme>((ref) {
  final t = ref.watch(tweaksProvider);
  return kDesignThemes[t.auroraId] ?? DesignTheme.fog;
});

/// The dark [ThemeData] for the current tweaks — pass to [MaterialApp.darkTheme].
///
/// Retained under its original name for backwards compatibility; equivalent to
/// [darkThemeDataProvider].
final themeDataProvider = Provider<ThemeData>((ref) {
  final t = ref.watch(tweaksProvider);
  final dt = kDesignThemes[t.auroraId] ?? DesignTheme.fog;
  return mapleThemeData(
    dt,
    warmAccents: t.warmAccents,
    googleFontsEnabled: true,
    brightness: Brightness.dark,
  );
});

/// The dark [ThemeData] for the current tweaks — pass to [MaterialApp.darkTheme].
final darkThemeDataProvider = themeDataProvider;

/// The light [ThemeData] for the current tweaks — pass to [MaterialApp.theme].
final lightThemeDataProvider = Provider<ThemeData>((ref) {
  final t = ref.watch(tweaksProvider);
  final dt = kDesignThemesLight[t.auroraId] ?? DesignTheme.fogLight;
  return mapleThemeData(
    dt,
    warmAccents: t.warmAccents,
    googleFontsEnabled: true,
    brightness: Brightness.light,
  );
});

/// The user's selected [ThemeMode] — pass to [MaterialApp.themeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(tweaksProvider).flutterThemeMode;
});
