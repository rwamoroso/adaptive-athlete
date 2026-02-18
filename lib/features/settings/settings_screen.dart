import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_providers.dart';
import '../sync/sync_service.dart';

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
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Local-only mode'),
          subtitle: const Text(
              'When enabled, auth is optional and app runs with local DB only.'),
          value: settings.localOnly,
          onChanged: settingsNotifier.setLocalOnly,
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Supabase status'),
          subtitle: Text(
              'initialized: ${bootstrap.initialized}\nuser id: ${userId ?? 'none'}'),
        ),
        if (bootstrap.error != null)
          Text('Init error: ${bootstrap.error}',
              style: const TextStyle(color: Colors.orange)),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: !bootstrap.initialized
              ? null
              : () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out.')));
                  }
                },
          child: const Text('Sign out'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
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
          child: const Text('Sync Now'),
        ),
      ],
    );
  }
}
