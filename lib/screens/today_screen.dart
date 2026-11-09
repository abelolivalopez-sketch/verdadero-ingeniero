import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/ranks.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';

/// Pestaña "Hoy": estado del usuario, lección del día y examen diario.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onOpenRoadmap});

  final VoidCallback onOpenRoadmap;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<Dashboard> _future = Repo.dashboard();

  Future<void> _reload() async {
    final f = Repo.dashboard();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Dashboard>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(message: Repo.friendlyError(snap.error!), onRetry: _reload);
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [ReadableWidth(child: _content(d))],
            ),
          );
        },
      ),
    );
  }

  Widget _content(Dashboard d) {
    final p = d.profile;
    final rank = rankFor(p.xp);
    final dayShown = p.currentDay > d.totalDays ? d.totalDays : p.currentDay;
    final programProgress = d.totalDays == 0 ? 0.0 : (p.currentDay - 1) / d.totalDays;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ---------------------------------------------------------- cabecera
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hola, ${p.displayName ?? 'ingeniero'}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(d.passedToday ? 'Objetivo de hoy cumplido. Así se construye un ingeniero.' : 'Tu entrenamiento de hoy te espera.',
                style: const TextStyle(color: AppColors.textDim)),
          ]),
        ),
        _StreakBadge(streak: d.effectiveStreak),
      ]),
      const SizedBox(height: 16),

      // ---------------------------------------------------------- rango
      HudCard(
        accent: AppColors.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('NV ${rank.level}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(rank.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Text('${p.xp} XP', style: const TextStyle(color: AppColors.textDim)),
          ]),
          const SizedBox(height: 12),
          GlowBar(value: rank.progress, color: AppColors.gold),
          const SizedBox(height: 6),
          Text('Faltan ${rank.xpToNext} XP para el nivel ${rank.level + 1}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 12),

      // ---------------------------------------------------------- indicadores
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 600 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: w,
              child: StatTile(icon: Icons.calendar_today, value: '$dayShown / ${d.totalDays}', label: 'Día del programa')),
          SizedBox(
              width: w,
              child: StatTile(
                  icon: Icons.speed,
                  value: levelName(p.currentLevel),
                  label: 'Dificultad actual',
                  color: AppColors.forLevel(p.currentLevel))),
          SizedBox(
              width: w,
              child: StatTile(
                  icon: Icons.local_fire_department,
                  value: '${d.effectiveStreak} días',
                  label: 'Mejor racha: ${p.bestStreak}',
                  color: AppColors.red)),
          SizedBox(
              width: w,
              child: StatTile(
                  icon: Icons.replay,
                  value: '${d.reviewsDue}',
                  label: 'Repasos pendientes',
                  color: AppColors.violet)),
        ]);
      }),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: GlowBar(value: programProgress, height: 6)),
        const SizedBox(width: 10),
        Text('${(programProgress * 100).toStringAsFixed(1)} % del programa',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      ]),
      const SizedBox(height: 20),

      if (d.programCompleted) _completedCard() else if (d.lesson != null) ..._lessonAndExam(d, d.lesson!),
    ]);
  }

  List<Widget> _lessonAndExam(Dashboard d, LessonSummary l) {
    final color = AppColors.fromHex(l.moduleColor);
    return [
      const SectionTitle('Lección del día'),
      HudCard(
        accent: color,
        onTap: () => _openLesson(l.dayNumber, d.profile.currentDay),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            Tag('Día ${l.dayNumber}', color: color),
            Tag('${l.moduleId} · ${l.moduleTitle}', color: color),
            Tag('${l.estimatedMinutes} min', color: AppColors.textDim, icon: Icons.timer_outlined),
          ]),
          const SizedBox(height: 12),
          Text(l.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          if (l.objective != null) ...[
            const SizedBox(height: 6),
            Text(l.objective!, style: const TextStyle(color: AppColors.textDim)),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: l.isReady ? () => _openLesson(l.dayNumber, d.profile.currentDay) : null,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l.isReady ? 'Estudiar la teoría' : 'Temario en preparación'),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      const SectionTitle('Examen diario', color: AppColors.gold),
      HudCard(
        accent: d.passedToday ? AppColors.green : AppColors.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(d.passedToday ? Icons.verified : Icons.quiz_outlined,
                color: d.passedToday ? AppColors.green : AppColors.gold, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                d.passedToday
                    ? 'Has aprobado hoy. Si quieres, sigue con el día ${l.dayNumber}.'
                    : '10 preguntas adaptadas a tu nivel${d.reviewsDue > 0 ? ' + repasos de días anteriores' : ''}. Necesitas un 80 % para avanzar.',
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (!l.isReady || l.questionCount == 0)
            Row(children: [
              const Icon(Icons.hourglass_top, color: AppColors.textDim, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('El banco de preguntas de este día aún no está cargado. Mientras tanto, repasa días anteriores.',
                    style: TextStyle(color: AppColors.textDim)),
              ),
              TextButton(onPressed: widget.onOpenRoadmap, child: const Text('Ver programa')),
            ])
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppColors.gold),
              onPressed: _startExam,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Empezar el examen del día ${l.dayNumber}'),
            ),
        ]),
      ),
    ];
  }

  Widget _completedCard() => const HudCard(
        accent: AppColors.violet,
        child: Column(children: [
          Icon(Icons.emoji_events, color: AppColors.gold, size: 64),
          SizedBox(height: 12),
          Text('¡Programa completado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
            'Has superado todos los días. Sigue haciendo exámenes de práctica desde el Programa para mantener el nivel.',
            textAlign: TextAlign.center,
          ),
        ]),
      );

  void _openLesson(int day, int currentDay) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(dayNumber: day, currentDay: currentDay)));
  }

  void _startExam() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExamScreen()));
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final on = streak > 0;
    final c = on ? AppColors.red : AppColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department, color: c),
        const SizedBox(width: 4),
        Text('$streak', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c)),
      ]),
    );
  }
}
