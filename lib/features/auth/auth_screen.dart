import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _message;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _supabaseNotReadyMessage(SupabaseBootstrap bootstrap) {
    final details = bootstrap.error;
    if (details == null || details.isEmpty) {
      return 'Supabase not initialized. Use local-only mode or configure keys.';
    }
    return 'Supabase not initialized: $details';
  }

  Future<void> _signIn() async {
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (!bootstrap.initialized) {
      setState(() => _message = _supabaseNotReadyMessage(bootstrap));
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await ref.read(workspaceServiceProvider).bootstrapAndGetContext();
      if (mounted) {
        final pendingToken =
            await ref.read(workspaceServiceProvider).getPendingInviteToken();
        if (!mounted) {
          return;
        }
        if (pendingToken != null && pendingToken.trim().isNotEmpty) {
          context.go('/join?token=${Uri.encodeComponent(pendingToken)}');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signUp() async {
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (!bootstrap.initialized) {
      setState(() => _message = _supabaseNotReadyMessage(bootstrap));
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() =>
          _message = 'Sign-up requested. Check email confirmation if enabled.');
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _resetRedirectTo() {
    const configuredRedirect =
        String.fromEnvironment('SUPABASE_PASSWORD_RESET_REDIRECT');
    if (configuredRedirect.isNotEmpty) {
      return configuredRedirect;
    }
    if (kIsWeb) {
      return '${Uri.base.origin}/reset-password';
    }
    return 'adaptiveathlete://reset-password';
  }

  Future<void> _sendPasswordReset() async {
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (!bootstrap.initialized) {
      setState(() => _message = _supabaseNotReadyMessage(bootstrap));
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Enter your email first.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: _resetRedirectTo(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _message =
          'Recovery email sent. Open the link from the same browser/app context.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _message = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Adaptive Athlete',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _signIn,
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : _signUp,
                    child: const Text('Sign up'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _sendPasswordReset,
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setLocalOnly(true);
                      context.go('/home');
                    },
                    child: const Text('Skip auth for local-only'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!,
                        style: const TextStyle(color: Colors.orange)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
