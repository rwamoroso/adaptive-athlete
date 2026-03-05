import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../ai/ai_weekly_explanation_screen.dart';
import '../ui/clinical_theme.dart';
import '../plan/plan_screen.dart';
import '../settings/settings_screen.dart';
import 'daily_screen.dart';
import 'history_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  int _dailyResetToken = 0;

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final pages = [
      DailyScreen(resetToken: _dailyResetToken),
      const HistoryScreen(),
      const PlanScreen(),
      const AiWeeklyExplanationScreen(),
      const SettingsScreen(),
    ];
    return Theme(
      data: buildClinicalTheme(),
      child: Scaffold(
        extendBody: true,
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
              child: SafeArea(
                bottom: false,
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
            if (syncStatus.phase != AppSyncPhase.idle)
              Positioned.fill(
                child: IgnorePointer(
                  child: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: _SyncStatusPill(status: syncStatus),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() {
                final comingToDaily = index == 0 && _index != 0;
                _index = index;
                if (comingToDaily) {
                  _dailyResetToken++;
                }
              }),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.today_outlined), label: 'Daily'),
                NavigationDestination(
                    icon: Icon(Icons.history), label: 'History'),
                NavigationDestination(
                    icon: Icon(Icons.event_note_outlined), label: 'Plan'),
                NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined), label: 'AI'),
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

class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({required this.status});

  final AppSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (status.phase) {
      AppSyncPhase.syncing => (
          Icons.sync_rounded,
          const Color(0x223FA7FF),
          const Color(0xFFBFE2FF)
        ),
      AppSyncPhase.success => (
          Icons.cloud_done_outlined,
          const Color(0x2230D17C),
          const Color(0xFFB5F5D2)
        ),
      AppSyncPhase.error => (
          Icons.cloud_off_outlined,
          const Color(0x22FF9F43),
          const Color(0xFFFFD8B0)
        ),
      AppSyncPhase.idle => (
          Icons.cloud_outlined,
          Colors.transparent,
          Colors.white70
        ),
    };

    return Tooltip(
      message: status.detail ?? status.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
