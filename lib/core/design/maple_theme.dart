import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_theme.dart';

/// Builds a [ThemeData] from a resolved [DesignTheme].
///
/// Registers the three token extensions ([MapleColors], [MapleSemantics],
/// [MapleAurora]) so widgets can look them up via `Theme.of(context).extension<T>()`.
///
/// [warmAccents] — when false the semantic palette signals calm mode (the
///   notifier passes this through; the semantics extension itself handles
///   the per-status desaturation when widgets call `byName`).
///
/// The [googleFontsEnabled] flag exists primarily for unit tests: in plain
/// `test()` blocks the Flutter ServicesBinding is not initialised, so
/// GoogleFonts fires an unhandled async error even when the synchronous call
/// is wrapped in try/catch. Callers that have initialised the binding (or
/// widget tests) can pass `googleFontsEnabled: true`; the real app's
/// [themeDataProvider] passes `true` automatically.
ThemeData mapleThemeData(
  DesignTheme t, {
  bool warmAccents = true,
  bool googleFontsEnabled = false,
}) {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  final TextTheme textTheme = googleFontsEnabled
      ? GoogleFonts.manropeTextTheme(base.textTheme)
      : base.textTheme;

  return base.copyWith(
    scaffoldBackgroundColor: t.colors.canvas,
    textTheme: textTheme.apply(
      bodyColor: t.colors.text,
      displayColor: t.colors.text,
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: t.colors.accent,
      surface: t.colors.surface2,
    ),
    extensions: [t.colors, t.semantics, t.aurora],
  );
}
