import 'package:flutter/material.dart';

import '../ui/clinical_theme.dart';
import '../export/export_screen.dart';
import '../plan/plan_screen.dart';
import '../settings/settings_screen.dart';
import 'daily_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = [
    'Daily',
    'History',
    'Plan',
    'Export/Import',
    'Settings'
  ];

  final _pages = const [
    DailyScreen(),
    HistoryScreen(),
    PlanScreen(),
    ExportScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildClinicalTheme(),
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(title: Text(_titles[_index])),
        body: Stack(
          children: [
            const Positioned.fill(child: _ClinicalGradientBackground()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.1, -0.95),
                    radius: 1.45,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
                child: IndexedStack(index: _index, children: _pages)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.today_outlined), label: 'Daily'),
                NavigationDestination(
                    icon: Icon(Icons.history), label: 'History'),
                NavigationDestination(
                    icon: Icon(Icons.event_note_outlined), label: 'Plan'),
                NavigationDestination(
                    icon: Icon(Icons.download_outlined),
                    label: 'Export/Import'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined), label: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicalGradientBackground extends StatelessWidget {
  const _ClinicalGradientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ClinicalPalette.bgTop,
            ClinicalPalette.bgMid,
            ClinicalPalette.bgBottom,
          ],
        ),
      ),
    );
  }
}
