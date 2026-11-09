import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'exam_screen.dart';

/// Teoría + práctica de un día.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.dayNumber, required this.currentDay});

  final int dayNumber;
  final int currentDay;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<DayContent> _future = Repo.day(widget.dayNumber);

  bool get _isToday => widget.dayNumber == widget.currentDay;

  void _startExam() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExamScreen(day: _isToday ? null : widget.dayNumber),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Día ${widget.dayNumber}'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<DayContent>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(
              message: Repo.friendlyError(snap.error!),
              onRetry: () => setState(() => _future = Repo.day(widget.dayNumber)),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final c = snap.data!;
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                ReadableWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      Tag(c.moduleId),
                      Tag('${c.estimatedMinutes} min', color: AppColors.textDim, icon: Icons.timer_outlined),
                      if (!_isToday) const Tag('Repaso', color: AppColors.violet, icon: Icons.replay),
                    ]),
                    const SizedBox(height: 12),
                    Text(c.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                    if (c.objective != null) ...[
                      const SizedBox(height: 12),
                      HudCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.flag_outlined, color: AppColors.arc),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Objetivo: ${c.objective}')),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (!c.isReady)
                      const HudCard(
                        accent: AppColors.textDim,
                        child: Text(
                          'El temario de este día todavía no está cargado. El programa se va ampliando por bloques; '
                          'mientras tanto puedes repasar los días anteriores.',
                        ),
                      )
                    else ...[
                      MathMarkdown(c.bodyMd!),
                      if (c.practiceMd != null && c.practiceMd!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        HudCard(
                          accent: AppColors.gold,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            const Row(children: [
                              Icon(Icons.edit_note, color: AppColors.gold),
                              SizedBox(width: 8),
                              Text('PRÁCTICA CON LÁPIZ Y PAPEL',
                                  style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800, color: AppColors.gold)),
                            ]),
                            const SizedBox(height: 8),
                            MathMarkdown(c.practiceMd!),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: _isToday ? AppColors.gold : AppColors.violet,
                        ),
                        onPressed: _startExam,
                        icon: const Icon(Icons.quiz),
                        label: Text(_isToday ? 'Hacer el examen del día' : 'Examen de práctica de este día'),
                      ),
                      if (!_isToday)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('La práctica no cambia tu progreso y da la mitad de XP.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ),
                    ],
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
