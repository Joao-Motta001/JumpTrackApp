import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      _showMessage('Enter a valid email and a password with at least 6 characters.');
      return;
    }

    final success = _isLogin
        ? await app.signInWithEmail(email: email, password: password)
        : await app.registerWithEmail(email: email, password: password);

    if (!success && mounted && app.lastError != null) {
      _showMessage(app.lastError!);
    }
  }

  Future<void> _google() async {
    final app = context.read<AppState>();
    final success = await app.signInWithGoogle();
    if (!success && mounted && app.lastError != null) {
      _showMessage(app.lastError!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B0003), AppTheme.background],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Icon(
                          Icons.sports_volleyball_rounded,
                          size: 72,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'JumpTrack',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 38,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Volleyball performance, jump analytics, workouts, macros, hydration, and weekly routines in one elite mobile app.',
                          style: TextStyle(color: AppTheme.subtleText, fontSize: 16),
                        ),
                        const SizedBox(height: 22),
                        GlowCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Login')),
                                      selected: _isLogin,
                                      onSelected: (_) => setState(() => _isLogin = true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Create Account')),
                                      selected: !_isLogin,
                                      onSelected: (_) => setState(() => _isLogin = false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: app.isBusy || !app.isCloudEnabled ? null : _submit,
                                  child: Text(_isLogin ? 'Login' : 'Create Account'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: app.isBusy || !app.isCloudEnabled ? null : _google,
                                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                                  label: const Text('Continue with Google'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: app.isBusy
                                      ? null
                                      : () async {
                                          await app.continueInDemoMode();
                                        },
                                  child: const Text('Enter Demo Mode'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlowCard(
                          accent: app.isCloudEnabled ? AppTheme.success : AppTheme.warning,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                app.isCloudEnabled ? Icons.cloud_done_rounded : Icons.info_outline_rounded,
                                color: app.isCloudEnabled ? AppTheme.success : AppTheme.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  app.isCloudEnabled
                                      ? 'Firebase is configured. Email login, Google login, Firestore sync, messaging, and storage are ready once your device permissions are granted.'
                                      : 'Firebase placeholder configuration detected. You can still open the app in demo mode immediately. Replace lib/firebase_options.dart and add the GoogleService files to enable real authentication and cloud sync.',
                                  style: const TextStyle(color: AppTheme.subtleText, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (app.isBusy) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
