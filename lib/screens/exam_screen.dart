import 'dart:async';

import 'package:flutter/material.dart';

import '../data/events.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Examen: una pregunta por pantalla, test o respuesta numérica.
/// [day] = null → examen diario; un día anterior → examen de práctica.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, this.day});

  final int? day;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Exam? _exam;
  Object? _error;
  bool _submitting = false;
  int _index = 0;
  final Map<String, int> _choices = {};
  final Map<String, TextEditingController> _numbers = {};
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _exam != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _retry() {
    setState(() {
      _error = null;
      _exam = null;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final exam = await Repo.startExam(day: widget.day);
      for (final q in exam.questions.where((q) => q.isNumeric)) {
        _numbers.putIfAbsent(q.id, () => TextEditingController());
      }
      if (!mounted) return;
      setState(() => _exam = exam);
      _clock
        ..reset()
        ..start();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  static double? parseNumber(String raw) => parseUserNumber(raw);

  bool _answered(ExamQuestion q) =>
      q.isNumeric ? parseNumber(_numbers[q.id]?.text ?? '') != null : _choices.containsKey(q.id);

  Future<bool> _confirm(String title, String body, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _submit() async {
    final exam = _exam;
    if (exam == null || _submitting) return;
    final missing = exam.questions.where((q) => !_answered(q)).length;
    if (missing > 0) {
      final go = await _confirm(
        'Faltan $missing ${missing == 1 ? 'pregunta' : 'preguntas'}',
        'Las preguntas sin responder cuentan como falladas. ¿Entregar de todos modos?',
        'Entregar',
      );
      if (!go || !mounted) return;
    }
    setState(() => _submitting = true);
    final answers = <Map<String, dynamic>>[];
    for (final q in exam.questions) {
      if (q.isNumeric) {
        final v = parseNumber(_numbers[q.id]?.text ?? '');
        if (v != null) answers.add({'question_id': q.id, 'value': v});
      } else if (_choices.containsKey(q.id)) {
        answers.add({'question_id': q.id, 'choice': _choices[q.id]});
      }
    }
    try {
      final result = await Repo.submitExam(exam.examId, answers);
      _clock.stop();
      notifyProgressChanged();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, elapsed: _clock.elapsed),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Repo.friendlyError(e))));
    }
  }

  String _elapsed() {
    final s = _clock.elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    return PopScope(
      canPop: exam == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(
          '¿Salir del examen?',
          'El examen queda abierto 6 horas con las mismas preguntas, pero tus respuestas de esta pantalla se perderán.',
          'Salir',
        );
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(exam == null
              ? 'Examen'
              : exam.isPractice
                  ? 'Práctica · Día ${exam.dayNumber}'
                  : 'Examen · Día ${exam.dayNumber}'),
          actions: [
            if (exam != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.textDim),
                    const SizedBox(width: 4),
                    Text(_elapsed()),
                  ]),
                ),
              ),
          ],
        ),
        body: _error != null
            ? ErrorRetry(message: Repo.friendlyError(_error!), onRetry: _retry)
            : exam == null
                ? const Center(child: CircularProgressIndicator())
                : exam.questions.isEmpty
                    ? const Center(child: Text('Este examen no tiene preguntas.'))
                    : _body(exam),
      ),
    );
  }

  Widget _body(Exam exam) {
    final n = exam.questions.length;
    final q = exam.questions[_index];
    final isLast = _index == n - 1;
    return Column(children: [
      LinearProgressIndicator(
        value: (_index + 1) / n,
        minHeight: 4,
        backgroundColor: AppColors.surfaceHigh,
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            ReadableWidth(
              maxWidth: 760,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('PREGUNTA ${_index + 1} DE $n',
                      style: const TextStyle(letterSpacing: 1.5, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                  DifficultyDots(q.difficulty),
                  if (q.isReview) Tag('Repaso · día ${q.sourceDay}', color: AppColors.violet, icon: Icons.replay),
                ]),
                const SizedBox(height: 16),
                MathMarkdown(q.promptMd,
                    style: const TextStyle(fontSize: 18, height: 1.5, color: AppColors.text)),
                const SizedBox(height: 20),
                if (q.isNumeric) _numeric(q) else ..._options(q),
              ]),
            ),
          ],
        ),
      ),
      _navigator(exam, isLast),
    ]);
  }

  List<Widget> _options(ExamQuestion q) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    return [
      for (var i = 0; i < q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OptionTile(
            letter: letters[i % letters.length],
            text: q.options[i],
            selected: _choices[q.id] == i,
            onTap: () => setState(() => _choices[q.id] = i),
          ),
        ),
    ];
  }

  Widget _numeric(ExamQuestion q) {
    final ctrl = _numbers[q.id]!;
    final parsed = parseNumber(ctrl.text);
    final invalid = ctrl.text.trim().isNotEmpty && parsed == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: ValueKey(q.id),
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Tu resultado',
          suffixText: q.unit,
          errorText: invalid ? 'Número no válido' : null,
          filled: true,
          fillColor: AppColors.surfaceHigh,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Usa coma o punto decimal. Notación científica: 4e5 o 4·10^5.'
        '${q.unit != null ? ' Responde en ${q.unit}.' : ''} Se acepta un pequeño margen de redondeo.',
        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
      ),
    ]);
  }

  Widget _navigator(Exam exam, bool isLast) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            for (var i = 0; i < exam.questions.length; i++)
              GestureDetector(
                onTap: () => setState(() => _index = i),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _answered(exam.questions[i]) ? AppColors.arc.withValues(alpha: 0.25) : Colors.transparent,
                    border: Border.all(
                      color: i == _index ? AppColors.gold : AppColors.border,
                      width: i == _index ? 2 : 1,
                    ),
                  ),
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _index > 0 ? () => setState(() => _index--) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            const Spacer(),
            if (isLast)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Entregar'),
              )
            else
              FilledButton.icon(
                onPressed: () => setState(() => _index++),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Siguiente'),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.letter, required this.text, required this.selected, required this.onTap});

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppColors.arc : AppColors.border;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.arc.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c, width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.arc : AppColors.surfaceHigh,
              ),
              child: Text(letter,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: selected ? AppColors.background : AppColors.text)),
            ),
            const SizedBox(width: 12),
            Expanded(child: IgnorePointer(child: MathMarkdown(text))),
          ]),
        ),
      ),
    );
  }
}
