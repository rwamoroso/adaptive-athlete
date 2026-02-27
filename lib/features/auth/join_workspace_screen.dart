import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_providers.dart';

class JoinWorkspaceScreen extends ConsumerStatefulWidget {
  const JoinWorkspaceScreen({
    super.key,
    required this.inviteToken,
  });

  final String? inviteToken;

  @override
  ConsumerState<JoinWorkspaceScreen> createState() =>
      _JoinWorkspaceScreenState();
}

class _JoinWorkspaceScreenState extends ConsumerState<JoinWorkspaceScreen> {
  String _message = 'Preparing invite...';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInvite();
    });
  }

  Future<void> _processInvite() async {
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (!bootstrap.initialized) {
      setState(() {
        _busy = false;
        _message = 'Supabase is not initialized. Configure cloud first.';
      });
      return;
    }

    final workspaceService = ref.read(workspaceServiceProvider);
    final inviteToken = widget.inviteToken?.trim().isNotEmpty == true
        ? widget.inviteToken!
        : null;
    final token = inviteToken ?? await workspaceService.getPendingInviteToken();
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _busy = false;
        _message = 'Missing invite token.';
      });
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      await workspaceService.setPendingInviteToken(token);
      setState(() {
        _busy = false;
        _message = 'Sign in to accept this workspace invite.';
      });
      return;
    }

    try {
      await ref.read(inviteServiceProvider).acceptInvite(token);
      ref.invalidate(activeWorkspaceContextProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = 'Invite accepted. Redirecting to home...';
      });
      context.go('/home');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = 'Failed to accept invite: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Workspace',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  Text(_message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (Supabase.instance.client.auth.currentSession ==
                                null) {
                              context.go('/auth');
                            } else {
                              context.go('/home');
                            }
                          },
                    child: Text(
                      Supabase.instance.client.auth.currentSession == null
                          ? 'Go to sign in'
                          : 'Go home',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
