import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_providers.dart';
import '../plan/weekly_plan_prompt_service.dart';
import '../sync/sync_service.dart';
import '../training/exercise_substitution_service.dart';
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
        Text(
          'SYSTEM & CLINICAL CONFIG',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text: 'Clinical Focus: Reliable Local State & Sync Integrity',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              title: 'Mode',
              valueText: settings.localOnly ? 'Local Only' : 'Cloud + Auth',
              subtitleText: settings.unit == UnitPreference.lb
                  ? 'Units: lb'
                  : 'Units: kg',
              leadingIcon: Icons.tune_outlined,
            ),
            MetricTile(
              title: 'Supabase',
              valueText: bootstrap.initialized ? 'Connected' : 'Offline',
              subtitleText:
                  userId == null ? 'No active user' : 'User authenticated',
              leadingIcon: Icons.cloud_done_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Equipment',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in ExerciseSubstitutionService.knownEquipment)
                    FilterChip(
                      label: Text(item),
                      selected: settings.availableEquipment.contains(item),
                      onSelected: (_) => settingsNotifier.toggleEquipment(item),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Movement Contraindications',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final flag
                      in ExerciseSubstitutionService.knownContraindications)
                    FilterChip(
                      label: Text(flag),
                      selected:
                          settings.movementContraindications.contains(flag),
                      onSelected: (_) =>
                          settingsNotifier.toggleContraindication(flag),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'AI Weekly Plan Prompt'),
        const SizedBox(height: 8),
        const _WeeklyPlanPromptCard(),
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
                    ref
                        .read(syncStatusProvider.notifier)
                        .setSyncing(reason: 'manual');
                    final status = await SyncService(
                      db: ref.read(appDbProvider),
                      client: Supabase.instance.client,
                    ).syncNow();
                    ref
                        .read(syncStatusProvider.notifier)
                        .setResult(status, reason: 'manual');
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

class _WeeklyPlanPromptCard extends ConsumerStatefulWidget {
  const _WeeklyPlanPromptCard();

  @override
  ConsumerState<_WeeklyPlanPromptCard> createState() =>
      _WeeklyPlanPromptCardState();
}

class _WeeklyPlanPromptCardState extends ConsumerState<_WeeklyPlanPromptCard> {
  late final TextEditingController _controller;
  bool _loading = true;
  bool _saving = false;
  bool _hasOverride = false;
  String _loadedText = '';
  String? _statusText;

  bool get _isDirty => _controller.text != _loadedText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onPromptChanged);
    _loadPromptTemplate();
  }

  @override
  void dispose() {
    _controller.removeListener(_onPromptChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPromptChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPromptTemplate() async {
    setState(() {
      _loading = true;
      _statusText = 'Loading prompt template...';
    });
    try {
      final service = ref.read(weeklyPlanPromptServiceProvider);
      final hasOverride = await service.hasPromptOverride();
      final effective = await service.getEffectivePromptTemplate();
      if (!mounted) {
        return;
      }
      _controller.text = effective;
      setState(() {
        _loadedText = effective;
        _hasOverride = hasOverride;
        _loading = false;
        _statusText = hasOverride
            ? 'Loaded user override prompt.'
            : 'Loaded default prompt from app assets.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _statusText = 'Failed to load prompt template: $e';
      });
    }
  }

  Future<void> _savePromptOverride() async {
    final text = _controller.text.trimRight();
    if (text.trim().isEmpty) {
      _showMessage('Prompt cannot be empty.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(weeklyPlanPromptServiceProvider).savePromptOverride(text);
      if (!mounted) {
        return;
      }
      setState(() {
        _loadedText = text;
        _hasOverride = true;
        _statusText = 'Saved user prompt override.';
      });
      _showMessage('Weekly plan prompt override saved.');
    } catch (e) {
      _showMessage('Save failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Prompt to Default'),
            content: const Text(
              'This will remove your local override and restore the bundled prompt template.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(weeklyPlanPromptServiceProvider).clearPromptOverride();
      await _loadPromptTemplate();
      _showMessage('Prompt reset to default template.');
    } catch (e) {
      _showMessage('Reset failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    _showMessage('Prompt copied to clipboard.');
  }

  Future<void> _importPrompt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['md', 'txt'],
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final text = await File(path).readAsString();
      if (!mounted) {
        return;
      }
      _controller.text = text;
      setState(() {
        _statusText = 'Imported prompt file: $path';
      });
      _showMessage('Prompt imported. Review and tap Save Override to persist.');
    } catch (e) {
      _showMessage('Import failed: $e');
    }
  }

  Future<void> _exportPrompt() async {
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder for weekly prompt export',
      );
      if (dir == null || dir.isEmpty) {
        return;
      }
      final file = File(
        '$dir/${WeeklyPlanPromptService.weeklyPlanPromptTemplateKey}.override.md',
      );
      await file.writeAsString(_controller.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = 'Exported prompt to ${file.path}';
      });
      _showMessage('Prompt exported to ${file.path}');
    } catch (e) {
      _showMessage('Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _saving;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Plan Prompt (Workbook Text v1)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Chip(
                label: Text(_hasOverride ? 'Override Active' : 'Default'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This prompt is used when building weekly plans with external AI tools so the output includes ranked exercise alternatives that fit the plan intent.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_statusText != null)
            Text(
              _statusText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          if (busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            enabled: !_loading,
            minLines: 10,
            maxLines: 18,
            decoration: const InputDecoration(
              labelText: 'Prompt Template',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy || (!_isDirty && _hasOverride)
                    ? null
                    : _savePromptOverride,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Override'),
              ),
              OutlinedButton.icon(
                onPressed: busy || !_hasOverride ? null : _resetToDefault,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Default'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _copyPrompt,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : _importPrompt,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import'),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _exportPrompt,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : _loadPromptTemplate,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Reload'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
