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
  final _tokenController = TextEditingController();
  String _message = 'Preparing invite...';
  bool _busy = true;
  bool _needsAccountSwitch = false;
  bool _tokenInputMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInvite();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String? _extractToken(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    // Accept either the full deep link or the bare token.
    if (trimmed.contains('://') || trimmed.startsWith('/')) {
      final uri = Uri.tryParse(trimmed);
      final tokenFromQuery = uri?.queryParameters['token']?.trim();
      if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
        return tokenFromQuery;
      }
    }
    return trimmed;
  }

  bool _isEmailMismatchError(Object error) {
    final lower = error.toString().toLowerCase();
    return lower.contains('invite email does not match signed-in user email');
  }

  Future<void> _acceptToken(String token) async {
    try {
      setState(() {
        _busy = true;
        _message = 'Accepting invite...';
        _needsAccountSwitch = false;
      });
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
      final emailMismatch = _isEmailMismatchError(e);
      setState(() {
        _busy = false;
        _needsAccountSwitch = emailMismatch;
        _message = emailMismatch
            ? 'This invite belongs to a different email. Sign out and sign in with the invited account.'
            : 'Failed to accept invite: $e';
      });
    }
  }

  Future<void> _submitManuallyEnteredToken() async {
    final token = _extractToken(_tokenController.text);
    if (token == null || token.isEmpty) {
      setState(() {
        _message = 'Enter a valid invite link or token.';
      });
      return;
    }
    await ref.read(workspaceServiceProvider).setPendingInviteToken(token);
    if (!mounted) {
      return;
    }
    await _processInvite();
  }

  Future<void> _signOutAndSwitchAccount() async {
    final token = _extractToken(_tokenController.text);
    if (token != null && token.isNotEmpty) {
      await ref.read(workspaceServiceProvider).setPendingInviteToken(token);
    }
    await Supabase.instance.client.auth.signOut();
    if (!mounted) {
      return;
    }
    context.go('/auth');
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
    final inviteToken = _extractToken(widget.inviteToken);
    final token = inviteToken ?? await workspaceService.getPendingInviteToken();
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _busy = false;
        _tokenInputMode = true;
        _message = 'Paste an invite link or token to continue.';
      });
      return;
    }
    _tokenController.text = token;

    if (Supabase.instance.client.auth.currentSession == null) {
      await workspaceService.setPendingInviteToken(token);
      setState(() {
        _busy = false;
        _message = 'Sign in to accept this workspace invite. '
            'If you do not have an account yet, use Sign up with the invited '
            'email and choose your own password.';
      });
      return;
    }

    await _acceptToken(token);
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
                  if (_tokenInputMode) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Invite link or token',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _submitManuallyEnteredToken,
                      child: const Text('Continue'),
                    ),
                  ],
                  if (_needsAccountSwitch) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _signOutAndSwitchAccount,
                      child: const Text('Sign out and switch account'),
                    ),
                  ],
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
                          ? 'Go to sign in / sign up'
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
