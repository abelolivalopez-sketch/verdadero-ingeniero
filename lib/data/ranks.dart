import 'dart:math' as math;

/// Sistema de rangos por experiencia (XP).
///
/// Nivel L se alcanza con 80·(L−1)² XP. Un examen diario perfecto en dificultad
/// avanzada da ~390 XP (15 preguntas + aprobado), así que el rango máximo solo
/// llega al final del programa con resultados excelentes.
class RankInfo {
  final int level;
  final String title;
  final int xp;
  final int levelStartXp;
  final int nextLevelXp;

  const RankInfo(this.level, this.title, this.xp, this.levelStartXp, this.nextLevelXp);

  double get progress =>
      nextLevelXp == levelStartXp ? 1 : ((xp - levelStartXp) / (nextLevelXp - levelStartXp)).clamp(0.0, 1.0).toDouble();

  int get xpToNext => math.max(0, nextLevelXp - xp);
}

const _titles = <(int, String)>[
  (1, 'Aprendiz'),
  (5, 'Técnico'),
  (10, 'Ingeniero en prácticas'),
  (15, 'Ingeniero junior'),
  (22, 'Ingeniero'),
  (30, 'Ingeniero sénior'),
  (38, 'Ingeniero jefe'),
  (46, 'Verdadero Ingeniero'),
];

int _xpFor(int level) => _k * (level - 1) * (level - 1);

const _k = 80;

RankInfo rankFor(int xp) {
  final level = math.sqrt(math.max(0, xp) / _k).floor() + 1;
  var title = _titles.first.$2;
  for (final t in _titles) {
    if (level >= t.$1) title = t.$2;
  }
  return RankInfo(level, title, xp, _xpFor(level), _xpFor(level + 1));
}

/// Siguiente título por desbloquear (o null si ya es el máximo).
(int, String)? nextTitle(int level) {
  for (final t in _titles) {
    if (t.$1 > level) return t;
  }
  return null;
}
