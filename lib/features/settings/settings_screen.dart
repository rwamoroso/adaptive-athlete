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
import '../workspace/workspace_models.dart';
import 'app_release.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final bootstrap = ref.watch(supabaseBootstrapProvider);
    final workspaceContextAsync = ref.watch(activeWorkspaceContextProvider);
    final plannerService = ref.watch(weeklyPlannerServiceProvider);
    final syncStatus = ref.watch(syncStatusProvider);

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
        const AppReleaseCard(),
        const SizedBox(height: 12),
        const SyncReviewCard(),
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
              valueText: settings.localOnly
                  ? 'Local only'
                  : (userId != null ? 'Signed in' : 'Not signed in'),
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
                key: ValueKey(settings.unit),
                initialValue: settings.unit,
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
        const SectionHeader(text: 'Advanced Prompt Defaults'),
        const SizedBox(height: 8),
        const _WeeklyPlanPromptCard(),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Planner Backend'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plannerService.isServerSideAiEnabled
                    ? 'Server-side AI: enabled'
                    : 'Server-side AI: disabled',
              ),
              const SizedBox(height: 6),
              Text(
                plannerService.isServerSideAiEnabled
                    ? 'Edge function route: generate-weekly-plan'
                    : 'Sign in and configure edge function to enable one-tap AI.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Cloud Sync'),
        const SizedBox(height: 8),
        GlassCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(syncStatus.phase == AppSyncPhase.error
              ? syncStatus.label
              : 'Your changes are saved on this device.'),
          if (syncStatus.detail != null) Text(syncStatus.detail!),
          Text(syncStatus.lastSuccessAtMs == null
              ? 'No successful cloud sync recorded on this device.'
              : 'Last successful cloud sync: ${DateTime.fromMillisecondsSinceEpoch(syncStatus.lastSuccessAtMs!).toLocal().toString().split(".").first}'),
        ])),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Connection Details'),
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
        const SectionHeader(text: 'Workspace'),
        const SizedBox(height: 8),
        GlassCard(
          child: workspaceContextAsync.when(
            loading: () => const Text('Loading workspace context...'),
            error: (error, _) => Text('Workspace context error: $error'),
            data: (ctx) {
              if (ctx == null) {
                return const Text(
                  'No workspace context. Sign in and sync once to bootstrap.',
                );
              }
              final workspace = ctx.workspaces
                  .where((w) => w.id == ctx.workspaceId)
                  .cast<WorkspaceSummary?>()
                  .firstWhere((_) => true, orElse: () => null);
              final profiles = ctx.activeWorkspaceProfiles;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspace: ${workspace?.name ?? ctx.workspaceId}\nRole: ${ctx.role}\nActive profile: ${ctx.profileId}',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'profile_${ctx.profileId}_${syncStatus.updatedAtMs}'),
                    initialValue: profiles.any((p) => p.id == ctx.profileId)
                        ? ctx.profileId
                        : (profiles.isNotEmpty ? profiles.first.id : null),
                    decoration:
                        const InputDecoration(labelText: 'Active profile'),
                    items: profiles
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: profiles.isEmpty ||
                            syncStatus.phase == AppSyncPhase.syncing
                        ? null
                        : (selectedProfileId) async {
                            if (selectedProfileId == null ||
                                selectedProfileId == ctx.profileId) {
                              return;
                            }
                            try {
                              final notifier =
                                  ref.read(syncStatusProvider.notifier);
                              final service = SyncService(
                                  db: ref.read(appDbProvider),
                                  client: Supabase.instance.client,
                                  workspaceService:
                                      ref.read(workspaceServiceProvider));
                              notifier.setSyncing(
                                  reason: 'before_profile_switch');
                              final saved = await service.syncNow();
                              if (!context.mounted) return;
                              if (!SyncService.succeeded(saved)) {
                                notifier.setResult(saved,
                                    reason: 'before_profile_switch');
                                ref.invalidate(syncConflictsProvider);
                                throw StateError(
                                    'Current profile remains selected. Resolve sync issues before switching. $saved');
                              }
                              await ref
                                  .read(workspaceServiceProvider)
                                  .switchActiveProfile(
                                    workspaceId: ctx.workspaceId,
                                    profileId: selectedProfileId,
                                    cloudSyncConfirmed: true,
                                  );
                              if (!context.mounted) return;
                              final status = await SyncService(
                                db: ref.read(appDbProvider),
                                client: Supabase.instance.client,
                                workspaceService:
                                    ref.read(workspaceServiceProvider),
                              ).syncNow();
                              if (!context.mounted) return;
                              ref
                                  .read(syncStatusProvider.notifier)
                                  .setResult(status, reason: 'profile_switch');
                              ref.invalidate(activeWorkspaceContextProvider);
                              ref.invalidate(syncConflictsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(status)),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ref.read(syncStatusProvider.notifier).setError(
                                    label: 'Profile switch failed',
                                    detail: '$e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Profile switch failed: $e'),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  if (ctx.role.toLowerCase() == 'owner' &&
                      profiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _WorkspaceInviteCard(
                      workspaceId: ctx.workspaceId,
                      profiles: profiles,
                    ),
                  ],
                ],
              );
            },
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
                  text: syncStatus.phase == AppSyncPhase.syncing
                      ? 'Syncing…'
                      : 'Sync Now',
                  variant: PillButtonVariant.outlined,
                  onPressed: !bootstrap.initialized ||
                          settings.localOnly ||
                          userId == null ||
                          syncStatus.phase == AppSyncPhase.syncing
                      ? null
                      : () => _syncFromSettings(context, ref),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceInviteCard extends ConsumerStatefulWidget {
  const _WorkspaceInviteCard({
    required this.workspaceId,
    required this.profiles,
  });

  final String workspaceId;
  final List<AthleteProfileSummary> profiles;

  @override
  ConsumerState<_WorkspaceInviteCard> createState() =>
      _WorkspaceInviteCardState();
}

class _WorkspaceInviteCardState extends ConsumerState<_WorkspaceInviteCard> {
  final TextEditingController _emailController = TextEditingController();
  String _role = 'coach';
  final Set<String> _selectedProfileIds = <String>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedProfileIds.addAll(widget.profiles.map((p) => p.id));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite user',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'User email'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: 'coach', child: Text('coach')),
            DropdownMenuItem(value: 'athlete', child: Text('athlete')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _role = value);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.profiles
              .map(
                (profile) => FilterChip(
                  label: Text(profile.name),
                  selected: _selectedProfileIds.contains(profile.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedProfileIds.add(profile.id);
                      } else {
                        _selectedProfileIds.remove(profile.id);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Creates a shareable invite link and copies it to your clipboard. '
          'It does not send an email or create a password for the new user.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: _submitting
                ? 'Creating invite...'
                : 'Create & copy invite link',
            variant: PillButtonVariant.outlined,
            onPressed: _submitting
                ? null
                : () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter an email address.')),
                      );
                      return;
                    }
                    if (!email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a valid email address.')),
                      );
                      return;
                    }
                    if (_selectedProfileIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Select at least one athlete profile for this invite.')),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    try {
                      final invite = await ref
                          .read(inviteServiceProvider)
                          .createInvite(
                            InviteCreateRequest(
                              workspaceId: widget.workspaceId,
                              email: email,
                              role: _role,
                              assignedProfileIds: _selectedProfileIds.toList(),
                            ),
                          );
                      await Clipboard.setData(
                          ClipboardData(text: invite.deepLink));
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invite link copied. Share it with ${invite.email}; '
                            'they will create their own password after opening it.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      final errorText = e is PostgrestException
                          ? () {
                              final details = e.details?.toString();
                              if (details != null && details.isNotEmpty) {
                                return '${e.message} ($details)';
                              }
                              return e.message;
                            }()
                          : e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invite failed: $errorText')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _submitting = false);
                      }
                    }
                  },
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
                  'Advanced Weekly Plan Prompt (Workbook Text v1)',
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

Future<void> _syncFromSettings(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(syncStatusProvider.notifier);
  final service = SyncService(
      db: ref.read(appDbProvider),
      client: Supabase.instance.client,
      workspaceService: ref.read(workspaceServiceProvider));
  notifier.setSyncing(reason: 'manual');
  final status = await service.syncNow();
  if (!context.mounted) return;
  if (notifier.mounted) notifier.setResult(status, reason: 'manual');
  ref.invalidate(syncConflictsProvider);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
}

class SyncReviewCard extends ConsumerWidget {
  const SyncReviewCard({super.key});
  Future<void> _resolve(BuildContext context, WidgetRef ref,
      SyncConflict conflict, bool keepDevice) async {
    final service = SyncService(
        db: ref.read(appDbProvider),
        client: Supabase.instance.client,
        workspaceService: ref.read(workspaceServiceProvider));
    final notifier = ref.read(syncStatusProvider.notifier);
    notifier.setSyncing(reason: 'resolve_conflict');
    try {
      await service.resolve(conflict, keepDevice: keepDevice);
      final result = await service.syncNow();
      if (!context.mounted) return;
      if (notifier.mounted) {
        notifier.setResult(result, reason: 'resolve_conflict');
      }
      ref.invalidate(syncConflictsProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } catch (e) {
      if (!context.mounted) return;
      if (notifier.mounted) {
        notifier.setError(label: 'Review sync', detail: '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(syncStatusProvider).phase == AppSyncPhase.syncing;
    return ref.watch(syncConflictsProvider).when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text(
              'Sync review is unavailable. Try Sync Now to reconnect.'),
          data: (conflicts) => conflicts.isEmpty
              ? const SizedBox.shrink()
              : GlassCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text('Review Sync Changes (${conflicts.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Text(
                          'Both copies are preserved until you choose which version to keep.'),
                      for (final conflict in conflicts)
                        ExpansionTile(title: Text(conflict.label), children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('On this device',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                  conflict.describe(conflict.local))),
                          const SizedBox(height: 8),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('In the cloud',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                  conflict.describe(conflict.cloud))),
                          Wrap(spacing: 8, children: [
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () =>
                                        _resolve(context, ref, conflict, true),
                                child: const Text('Keep Device Version')),
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () =>
                                        _resolve(context, ref, conflict, false),
                                child: const Text('Use Cloud Version')),
                          ]),
                        ]),
                    ])),
        );
  }
}
