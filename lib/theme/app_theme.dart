import 'package:flutter/material.dart';

/// Paleta "HUD": fondo azul noche, acento reactor cian, dorado y rojo.
class AppColors {
  static const background = Color(0xFF070B16);
  static const surface = Color(0xFF0F172A);
  static const surfaceHigh = Color(0xFF17213A);
  static const border = Color(0xFF243150);
  static const arc = Color(0xFF4FD1FF); // acento principal
  static const gold = Color(0xFFF2B400);
  static const red = Color(0xFFFF5A5F);
  static const green = Color(0xFF7CFFB2);
  static const violet = Color(0xFFB98CFF);
  static const text = Color(0xFFE6EDF7);
  static const textDim = Color(0xFF8C9BB8);

  static Color fromHex(String? hex, {Color fallback = arc}) {
    if (hex == null) return fallback;
    final h = hex.replaceAll('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return v == null ? fallback : Color(v);
  }

  static Color forLevel(int level) => switch (level) {
        1 => green,
        2 => gold,
        _ => red,
      };
}

String levelName(int level) => switch (level) {
      1 => 'Básico',
      2 => 'Intermedio',
      _ => 'Avanzado',
    };

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.arc,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.arc,
    onPrimary: AppColors.background,
    secondary: AppColors.gold,
    onSecondary: AppColors.background,
    error: AppColors.red,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}
