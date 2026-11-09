import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/app_theme.dart';

/// Tarjeta con estilo HUD: borde fino luminoso y esquinas recortadas suaves.
class HudCard extends StatelessWidget {
  const HudCard({super.key, required this.child, this.accent, this.padding, this.onTap});

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.arc;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 1)],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: content),
    );
  }
}

/// Renderiza Markdown con fórmulas LaTeX: inline \( … \) y en bloque \[ … \].
/// Toda la app usa este widget: si cambias de librería de Markdown, cámbialo solo aquí.
class MathMarkdown extends StatelessWidget {
  const MathMarkdown(this.data, {super.key, this.style});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55, color: AppColors.text);
    return GptMarkdown(data, style: base);
  }
}

/// Etiqueta pequeña tipo "chip".
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = AppColors.arc, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Tres puntos que indican la dificultad (1–3).
class DifficultyDots extends StatelessWidget {
  const DifficultyDots(this.level, {super.key, this.size = 8});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.forLevel(level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < level;
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? c : Colors.transparent,
            border: Border.all(color: c.withValues(alpha: on ? 1 : 0.5)),
          ),
        );
      }),
    );
  }
}

/// Barra de progreso luminosa.
class GlowBar extends StatelessWidget {
  const GlowBar({super.key, required this.value, this.color = AppColors.arc, this.height = 10});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * value.clamp(0.0, 1.0).toDouble();
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          width: w,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
          ),
        ),
      );
    });
  }
}

/// Indicador numérico compacto (icono + valor + etiqueta).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.value, required this.label, this.color = AppColors.arc});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
          ]),
        ),
      ]),
    );
  }
}

/// Anillo de puntuación tipo "reactor".
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 160, this.threshold = 80});

  final double score; // 0–100
  final double size;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final passed = score >= threshold;
    final color = passed ? AppColors.green : AppColors.red;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, color, threshold / 100),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(v * 100).round()}%',
                  style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.w900, color: color)),
              Text(passed ? 'APROBADO' : 'SUSPENSO',
                  style: TextStyle(fontSize: size * 0.075, letterSpacing: 2, color: AppColors.textDim)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.threshold);

  final double value;
  final Color color;
  final double threshold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final bg = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * value, false, fg);
    // marca del umbral de aprobado
    final a = -math.pi / 2 + 2 * math.pi * threshold;
    final p1 = center + Offset(math.cos(a), math.sin(a)) * (radius - 10);
    final p2 = center + Offset(math.cos(a), math.sin(a)) * (radius + 10);
    canvas.drawLine(p1, p2, Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

/// Ancho máximo cómodo de lectura en escritorio.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 860});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// Vista de error con botón de reintento.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ]),
      ),
    );
  }
}

/// Título de sección.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color = AppColors.arc});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text.toUpperCase(),
            style: const TextStyle(letterSpacing: 1.6, fontWeight: FontWeight.w700, color: AppColors.textDim, fontSize: 13)),
      ]),
    );
  }
}
