import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_providers.dart';
import '../sync/sync_service.dart';
import '../ui/clinical_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final bootstrap = ref.watch(supabaseBootstrapProvider);

    String? userId;
    if (bootstrap.initialized) {
      userId = Supabase.instance.client.auth.currentUser?.id;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const SectionHeader(text: 'Preferences'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Local-only mode'),
                subtitle: const Text(
                    'When enabled, auth is optional and app runs with local DB only.'),
                value: settings.localOnly,
                onChanged: settingsNotifier.setLocalOnly,
              ),
              DropdownButtonFormField<UnitPreference>(
                value: settings.unit,
                decoration: const InputDecoration(labelText: 'Units'),
                items: const [
                  DropdownMenuItem(value: UnitPreference.lb, child: Text('lb')),
                  DropdownMenuItem(value: UnitPreference.kg, child: Text('kg')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    settingsNotifier.setUnit(v);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Supabase'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'initialized: ${bootstrap.initialized}\nuser id: ${userId ?? 'none'}',
              ),
              if (bootstrap.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Init error: ${bootstrap.error}',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Actions'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Sign out',
                  variant: PillButtonVariant.tonal,
                  onPressed: !bootstrap.initialized
                      ? null
                      : () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Signed out.')));
                          }
                        },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Sync Now',
                  variant: PillButtonVariant.outlined,
                  onPressed: () async {
                    final status = await SyncService(
                      db: ref.read(appDbProvider),
                      client: Supabase.instance.client,
                    ).syncNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(status)));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
