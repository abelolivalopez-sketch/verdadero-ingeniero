import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';

/// Mapa completo del programa: fases → módulos → días.
class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapData {
  final List<Phase> phases;
  final List<ModuleInfo> modules;
  final List<DaySummary> days;
  final Dashboard dashboard;

  _RoadmapData(this.phases, this.modules, this.days, this.dashboard);
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  late Future<_RoadmapData> _future = _load();
  String _query = '';

  Future<_RoadmapData> _load() async {
    final results = await Future.wait([Repo.phases(), Repo.modules(), Repo.days(), Repo.dashboard()]);
    return _RoadmapData(
      results[0] as List<Phase>,
      results[1] as List<ModuleInfo>,
      results[2] as List<DaySummary>,
      results[3] as Dashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_RoadmapData>(
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

  Widget _content(_RoadmapData data) {
    final current = data.dashboard.profile.currentDay;
    final total = data.days.length;
    final ready = data.days.where((d) => d.isReady).length;
    final byModule = <String, List<DaySummary>>{};
    for (final d in data.days) {
      byModule.putIfAbsent(d.moduleId, () => []).add(d);
    }
    final q = _query.trim().toLowerCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ReadableWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Programa completo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$total días · ${data.modules.length} módulos · $ready días con temario cargado',
                style: const TextStyle(color: AppColors.textDim)),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar un tema (p. ej. Coriolis, Bernoulli, PID…)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            if (q.isNotEmpty)
              ..._searchResults(data, q, current)
            else
              for (final phase in data.phases) ...[
                const SizedBox(height: 12),
                SectionTitle('Fase ${phase.id} · ${phase.title}', color: _phaseColor(phase.id)),
                if (phase.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(phase.description!, style: const TextStyle(color: AppColors.textDim)),
                  ),
                for (final m in data.modules.where((m) => m.phaseId == phase.id))
                  _ModuleTile(module: m, days: byModule[m.id] ?? const [], currentDay: current),
              ],
          ]),
        ),
      ],
    );
  }

  List<Widget> _searchResults(_RoadmapData data, String q, int current) {
    final hits = data.days
        .where((d) => d.title.toLowerCase().contains(q) || (d.objective ?? '').toLowerCase().contains(q))
        .toList();
    if (hits.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(24), child: Text('Sin resultados.'))];
    }
    return [for (final d in hits) _DayRow(day: d, currentDay: current)];
  }

  Color _phaseColor(int id) => switch (id) {
        1 => AppColors.arc,
        2 => AppColors.gold,
        3 => AppColors.red,
        4 => AppColors.green,
        _ => AppColors.violet,
      };
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.days, required this.currentDay});

  final ModuleInfo module;
  final List<DaySummary> days;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(module.color);
    final done = (currentDay - module.dayStart).clamp(0, module.length);
    final isCurrent = currentDay >= module.dayStart && currentDay <= module.dayEnd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCurrent ? color : AppColors.border, width: isCurrent ? 1.5 : 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isCurrent,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(module.id.replaceAll('M', ''),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            ),
            title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Días ${module.dayStart}–${module.dayEnd} · $done/${module.length} superados',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 6),
                GlowBar(value: module.length == 0 ? 0 : done / module.length, color: color, height: 5),
              ]),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            children: [
              if (module.description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(module.description!, style: const TextStyle(color: AppColors.textDim)),
                ),
              if (module.tools.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final t in module.tools) Tag(t, color: color, icon: Icons.build_outlined),
                  ]),
                ),
              for (final d in days) _DayRow(day: d, currentDay: currentDay),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.currentDay});

  final DaySummary day;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final n = day.dayNumber;
    final done = n < currentDay;
    final isToday = n == currentDay;
    final locked = n > currentDay;
    final integration = n % 7 == 0;

    final (IconData icon, Color color) = done
        ? (Icons.check_circle, AppColors.green)
        : isToday
            ? (Icons.play_circle_fill, AppColors.gold)
            : (Icons.lock_outline, AppColors.textDim);

    final canOpen = !locked && day.isReady;
    return ListTile(
      dense: true,
      enabled: canOpen || isToday,
      leading: Icon(icon, color: color),
      title: Text('Día $n · ${day.title}',
          style: TextStyle(fontWeight: isToday ? FontWeight.w800 : FontWeight.w500)),
      subtitle: Text(
        [
          if (day.objective != null) day.objective!,
          if (!day.isReady) 'Temario en preparación',
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: integration ? const Tag('Integración', color: AppColors.violet) : null,
      onTap: canOpen
          ? () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => LessonScreen(dayNumber: n, currentDay: currentDay)))
          : null,
    );
  }
}
