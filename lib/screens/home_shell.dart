import 'package:flutter/material.dart';

import '../data/events.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'roadmap_screen.dart';
import 'today_screen.dart';

/// Navegación principal: barra inferior en móvil y raíl lateral en escritorio.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Cambia con cada examen entregado para recargar todas las pestañas.
  int _refreshTick = progressEvents.value;

  @override
  void initState() {
    super.initState();
    progressEvents.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    progressEvents.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() => _refreshTick = progressEvents.value);
  }

  static const _destinations = [
    (Icons.bolt_outlined, Icons.bolt, 'Hoy'),
    (Icons.map_outlined, Icons.map, 'Programa'),
    (Icons.insights_outlined, Icons.insights, 'Progreso'),
    (Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayScreen(key: ValueKey('today$_refreshTick'), onOpenRoadmap: () => setState(() => _index = 1)),
      RoadmapScreen(key: ValueKey('map$_refreshTick')),
      ProgressScreen(key: ValueKey('progress$_refreshTick')),
      ProfileScreen(key: ValueKey('profile$_refreshTick')),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = IndexedStack(index: _index, children: pages);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.surface,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.precision_manufacturing_outlined, color: AppColors.arc, size: 32),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: body),
        ]),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
        ],
      ),
    );
  }
}
