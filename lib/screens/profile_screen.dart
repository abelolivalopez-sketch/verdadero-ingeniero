import 'package:flutter/material.dart';

import '../config.dart';
import '../data/events.dart';
import '../data/models.dart';
import '../data/ranks.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Perfil, rango, explicación del sistema y cierre de sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Dashboard> _future = Repo.dashboard();

  Future<void> _editName(String current) async {
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tu nombre'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await Repo.updateDisplayName(name);
      notifyProgressChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Repo.friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Dashboard>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorRetry(
              message: Repo.friendlyError(snap.error!),
              onRetry: () => setState(() => _future = Repo.dashboard()),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final p = snap.data!.profile;
          final rank = rankFor(p.xp);
          final next = nextTitle(rank.level);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ReadableWidth(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  HudCard(
                    child: Row(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.arc.withValues(alpha: 0.15),
                        child: Text(
                          (p.displayName ?? '?').isEmpty ? '?' : (p.displayName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.arc),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.displayName ?? 'Ingeniero',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text(Repo.user?.email ?? '', style: const TextStyle(color: AppColors.textDim)),
                          const SizedBox(height: 6),
                          Text('NV ${rank.level} · ${rank.title}', style: const TextStyle(color: AppColors.gold)),
                          if (next != null)
                            Text('Siguiente rango: ${next.$2} (nivel ${next.$1})',
                                style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Cambiar nombre',
                        onPressed: () => _editName(p.displayName ?? ''),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Cómo funciona tu entrenamiento'),
                  const HudCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Rule(Icons.menu_book_outlined, 'Cada día',
                          'Dos horas: teoría (≈45 min), taller práctico con cálculo guiado y Python (≈45 min), práctica con lápiz y papel y examen.'),
                      _Rule(Icons.quiz_outlined, 'Examen diario',
                          '15 preguntas del día adaptadas a tu dificultad, más hasta 5 repasos de lo que fallaste antes.'),
                      _Rule(Icons.check_circle_outline, 'Aprobar (≥ ${AppConfig.passThreshold} %)',
                          'Desbloqueas el día siguiente y sumas un día a tu racha.'),
                      _Rule(Icons.trending_up, 'Excelente (≥ 90 %)',
                          'Además sube la dificultad: Básico → Intermedio → Avanzado.'),
                      _Rule(Icons.trending_down, 'Por debajo del 50 %',
                          'Baja la dificultad para consolidar las bases y repites el día con preguntas nuevas.'),
                      _Rule(Icons.replay, 'Repaso espaciado',
                          'Cada fallo vuelve a los 1, 2, 4, 8 y 16 días hasta que lo dominas.'),
                      _Rule(Icons.star_outline, 'Experiencia',
                          '10 XP por acierto × dificultad, +50 XP por aprobar. La práctica da la mitad.'),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                    onPressed: () => Repo.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Verdadero Ingeniero · v1.0',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.arc, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(color: AppColors.textDim)),
          ]),
        ),
      ]),
    );
  }
}
