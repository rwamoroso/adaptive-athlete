import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today_outlined), label: 'Daily'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined), label: 'Plan'),
          NavigationDestination(
              icon: Icon(Icons.download_outlined), label: 'Export/Import'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
