import 'package:flutter/material.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Estadísticas: resultados, evolución y dominio por módulo.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressData {
  final Dashboard dashboard;
  final List<HistoryEntry> history;
  final List<ModuleStat> stats;
  final List<ModuleInfo> modules;

  _ProgressData(this.dashboard, this.history, this.stats, this.modules);
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<_ProgressData> _future = _load();

  Future<_ProgressData> _load() async {
    final r = await Future.wait([Repo.dashboard(), Repo.history(), Repo.moduleStats(), Repo.modules()]);
    return _ProgressData(
      r[0] as Dashboard,
      r[1] as List<HistoryEntry>,
      r[2] as List<ModuleStat>,
      r[3] as List<ModuleInfo>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_ProgressData>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(
              message: Repo.friendlyError(snap.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return _content(snap.data!);
        },
      ),
    );
  }

  Widget _content(_ProgressData data) {
    final p = data.dashboard.profile;
    final daily = data.history.where((h) => h.mode == 'daily').toList();
    final passedCount = daily.where((h) => h.passed).length;
    final avg = daily.isEmpty ? 0.0 : daily.map((h) => h.score).reduce((a, b) => a + b) / daily.length;
    final passRate = daily.isEmpty ? 0.0 : passedCount / daily.length * 100;
    final statsById = {for (final s in data.stats) s.moduleId: s};
    final started = data.modules.where((m) => m.dayStart <= p.currentDay).toList();
    final recent = data.history.take(20).toList().reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ReadableWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Tu progreso', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 600 ? 3 : 2;
              final w = (c.maxWidth - (cols - 1) * 10) / cols;
              Widget tile(IconData i, String v, String l, Color col) =>
                  SizedBox(width: w, child: StatTile(icon: i, value: v, label: l, color: col));
              return Wrap(spacing: 10, runSpacing: 10, children: [
                tile(Icons.flag, '${p.currentDay - 1}', 'Días superados', AppColors.green),
                tile(Icons.assignment_turned_in, '${data.history.length}', 'Exámenes hechos', AppColors.arc),
                tile(Icons.percent, '${passRate.toStringAsFixed(0)} %', 'Tasa de aprobado', AppColors.gold),
                tile(Icons.analytics_outlined, '${avg.toStringAsFixed(1)} %', 'Nota media (diarios)', AppColors.violet),
                tile(Icons.local_fire_department, '${p.bestStreak}', 'Mejor racha', AppColors.red),
                tile(Icons.star, '${p.xp}', 'XP total', AppColors.gold),
              ]);
            }),
            const SizedBox(height: 20),
            const SectionTitle('Últimos exámenes'),
            HudCard(
              child: recent.isEmpty
                  ? const Text('Aún no has hecho ningún examen. ¡Empieza hoy!')
                  : _ScoreChart(entries: recent),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Dominio por módulo', color: AppColors.gold),
            if (started.isEmpty) const Text('Todavía no has empezado ningún módulo.'),
            for (final m in started) _moduleRow(m, statsById[m.id], p.currentDay),
            const SizedBox(height: 20),
            const SectionTitle('Historial', color: AppColors.violet),
            if (data.history.isEmpty) const Text('Sin exámenes todavía.'),
            for (final h in data.history.take(25)) _historyRow(h),
          ]),
        ),
      ],
    );
  }

  Widget _moduleRow(ModuleInfo m, ModuleStat? s, int currentDay) {
    final color = AppColors.fromHex(m.color);
    final done = (currentDay - m.dayStart).clamp(0, m.length);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HudCard(
        accent: color,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${m.id} · ${m.title}', style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('$done/${m.length} días', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          GlowBar(value: m.length == 0 ? 0 : done / m.length, color: color, height: 6),
          if (s != null) ...[
            const SizedBox(height: 8),
            Text(
              'Media ${s.avgScore.toStringAsFixed(1)} % · mejor ${s.bestScore.toStringAsFixed(0)} % · '
              '${s.passed}/${s.exams} exámenes aprobados',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _historyRow(HistoryEntry h) {
    final c = h.passed ? AppColors.green : AppColors.red;
    final date = h.completedAt;
    final when = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(h.passed ? Icons.check_circle : Icons.cancel, color: c),
      title: Text('Día ${h.dayNumber} · ${h.score.toStringAsFixed(0)} %'),
      subtitle: Text([
        when,
        levelName(h.difficultyLevel),
        if (h.mode == 'practice') 'práctica',
        '+${h.xpEarned} XP',
      ].where((s) => s.isNotEmpty).join(' · ')),
      trailing: h.levelChange == 0
          ? null
          : Icon(h.levelChange > 0 ? Icons.trending_up : Icons.trending_down,
              color: h.levelChange > 0 ? AppColors.gold : AppColors.arc),
    );
  }
}

/// Gráfico de barras sencillo con la línea del aprobado.
class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    const h = 140.0;
    final threshold = AppConfig.passThreshold / 100;
    return SizedBox(
      height: h + 22,
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          top: h * (1 - threshold),
          child: Row(children: [
            Expanded(child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.7))),
            const SizedBox(width: 4),
            const Text('${AppConfig.passThreshold} %', style: TextStyle(fontSize: 10, color: AppColors.gold)),
          ]),
        ),
        Positioned.fill(
          right: 36,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final e in entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Tooltip(
                      message: 'Día ${e.dayNumber}: ${e.score.toStringAsFixed(0)} %',
                      child: Container(
                        height: (h * (e.score / 100)).clamp(3.0, h).toDouble(),
                        decoration: BoxDecoration(
                          color: (e.passed ? AppColors.green : AppColors.red)
                              .withValues(alpha: e.mode == 'practice' ? 0.45 : 0.9),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${e.dayNumber}', style: const TextStyle(fontSize: 9, color: AppColors.textDim)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
