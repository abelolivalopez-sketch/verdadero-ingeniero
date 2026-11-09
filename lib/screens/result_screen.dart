import 'package:flutter/material.dart';

import '../config.dart';
import '../data/events.dart';
import '../data/models.dart';
import '../data/ranks.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Resultado del examen con la corrección detallada de cada pregunta.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result, required this.elapsed});

  final ExamResult result;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final rank = rankFor(r.profile.xp);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text(r.mode == 'practice' ? 'Resultado de la práctica' : 'Resultado · Día ${r.dayNumber}'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            ReadableWidth(
              maxWidth: 780,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: ScoreRing(score: r.score, threshold: AppConfig.passThreshold.toDouble())),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  Tag('${r.correct} / ${r.total} correctas', color: r.passed ? AppColors.green : AppColors.red),
                  Tag('+${r.xpEarned} XP', color: AppColors.gold, icon: Icons.star),
                  Tag('${minutes}m ${seconds.toString().padLeft(2, '0')}s', color: AppColors.textDim, icon: Icons.timer),
                ]),
                const SizedBox(height: 18),
                ..._messages(r),
                const SizedBox(height: 8),
                HudCard(
                  accent: AppColors.gold,
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Text('NV ${rank.level}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.gold)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(rank.title)),
                    SizedBox(width: 120, child: GlowBar(value: rank.progress, color: AppColors.gold, height: 8)),
                  ]),
                ),
                const SizedBox(height: 22),
                const SectionTitle('Corrección'),
                for (var i = 0; i < r.results.length; i++) _QuestionReview(index: i + 1, q: r.results[i]),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Volver al inicio'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _messages(ExamResult r) {
    final out = <Widget>[];
    void add(IconData icon, Color color, String text) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HudCard(
          accent: color,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ]),
        ),
      ));
    }

    if (r.mode == 'practice') {
      add(Icons.school_outlined, AppColors.violet,
          'Examen de práctica: tu día y tu dificultad no cambian. Las preguntas falladas se añaden a tu repaso.');
    } else if (r.dayAdvanced) {
      add(Icons.rocket_launch_outlined, AppColors.green,
          '¡Día ${r.dayNumber} superado! Desbloqueado el día ${r.profile.currentDay}. Racha actual: ${r.profile.streak} 🔥');
    } else if (!r.passed) {
      add(Icons.replay, AppColors.red,
          'Necesitas un ${AppConfig.passThreshold} %. Repasa la teoría y vuelve a intentarlo: recibirás preguntas distintas. '
          'Lo que has fallado volverá en tus repasos de los próximos días.');
    }
    if (r.levelChange > 0) {
      add(Icons.trending_up, AppColors.gold,
          'Rendimiento excelente: la dificultad sube a ${levelName(r.profile.currentLevel)}.');
    } else if (r.levelChange < 0) {
      add(Icons.trending_down, AppColors.arc,
          'Ajustamos la dificultad a ${levelName(r.profile.currentLevel)} para consolidar las bases. Así se progresa de verdad.');
    }
    return out;
  }
}

class _QuestionReview extends StatelessWidget {
  const _QuestionReview({required this.index, required this.q});

  final int index;
  final QuestionResult q;

  String _yourAnswer() {
    if (!q.answered) return 'Sin responder';
    if (q.isNumeric) return '${fmtNum(q.yourValue!)}${q.unit != null ? ' ${q.unit}' : ''}';
    final i = q.yourChoice!;
    return i >= 0 && i < q.options.length ? q.options[i] : 'Opción $i';
  }

  String _correctAnswer() {
    if (q.isNumeric) {
      return '${fmtNum(q.answerValue ?? 0)}${q.unit != null ? ' ${q.unit}' : ''}  (±${fmtNum(q.tolerancePct)} %)';
    }
    final i = q.correctIndex ?? 0;
    return i >= 0 && i < q.options.length ? q.options[i] : '';
  }

  @override
  Widget build(BuildContext context) {
    final color = q.isCorrect ? AppColors.green : AppColors.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: !q.isCorrect,
            leading: Icon(q.isCorrect ? Icons.check_circle : Icons.cancel, color: color),
            title: Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('Pregunta $index', style: const TextStyle(fontWeight: FontWeight.w700)),
              DifficultyDots(q.difficulty),
              if (q.isReview) Tag('Repaso · día ${q.sourceDay}', color: AppColors.violet),
            ]),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MathMarkdown(q.promptMd),
              const SizedBox(height: 12),
              _AnswerRow(label: 'Tu respuesta', value: _yourAnswer(), color: color),
              if (!q.isCorrect) ...[
                const SizedBox(height: 6),
                _AnswerRow(label: 'Correcta', value: _correctAnswer(), color: AppColors.green),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('EXPLICACIÓN',
                      style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  MathMarkdown(q.explanationMd),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 110,
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
      Expanded(child: MathMarkdown(value)),
    ]);
  }
}
