import 'package:flutter/foundation.dart';

/// Se incrementa cada vez que cambia el progreso del usuario (examen entregado,
/// nombre cambiado…). Las pestañas principales lo escuchan para recargarse.
final progressEvents = ValueNotifier<int>(0);

void notifyProgressChanged() => progressEvents.value++;

/// Formatea un número para mostrarlo en español (coma decimal, ~5 cifras).
String fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  if (v == v.roundToDouble() && v.abs() < 1e9) return v.toInt().toString();
  final a = v.abs();
  if (a >= 1e6 || a < 1e-3) {
    final parts = v.toStringAsExponential(3).split('e');
    final mant = parts[0].replaceAll('.', ',');
    final exp = int.parse(parts[1]);
    return '$mant·10^$exp';
  }
  final intDigits = a < 1 ? 1 : a.floor().toString().length;
  final decimals = (5 - intDigits).clamp(0, 5);
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

/// Lee un número escrito por el usuario. Acepta coma o punto decimal, espacios
/// de miles, signo menos tipográfico y notación científica (4e5, 4·10^5, 4x10^5).
double? parseUserNumber(String raw) {
  var t = raw.trim().replaceAll(' ', '').replaceAll('\u00A0', '').replaceAll('\u2212', '-');
  if (t.isEmpty) return null;
  t = t.replaceAll(RegExp(r'[·x×*]10\^'), 'e');
  if (t.contains(',') && t.contains('.')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t);
}
