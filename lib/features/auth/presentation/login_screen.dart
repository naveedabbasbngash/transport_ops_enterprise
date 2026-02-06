import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_routes.dart';
import 'auth_view_model.dart';

/// ===============================================================
/// LOGIN SCREEN — V1 (FOUNDATION)
/// ===============================================================
/// - Enterprise-grade first impression
/// - Dummy authentication only (V1)
/// - Fully wired to AuthViewModel (Riverpod)
/// - Subtle animation (professional, calm)
/// - Web + Mobile responsive
/// ===============================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(theme),
                      const SizedBox(height: 32),
                      _LoginCard(
                        theme: theme,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        isLoading: authState.isLoading,
                        emailErrorText: authState.fieldErrors['email'],
                        passwordErrorText: authState.fieldErrors['password'],
                        errorText: authState.error,
                        onLoginPressed: () async {
                          await ref
                              .read(authViewModelProvider.notifier)
                              .login(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );

                          final nextState = ref.read(authViewModelProvider);
                          if (nextState.user == null) return;
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.dashboard,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// HEADER
/// ===============================================================

class _Header extends StatelessWidget {
  final ThemeData theme;
  const _Header(this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_shipping_outlined,
            size: 36,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'TransportOps',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Enterprise Transport & Logistics',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// ===============================================================
/// LOGIN CARD
/// ===============================================================

class _LoginCard extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? emailErrorText;
  final String? passwordErrorText;
  final String? errorText;
  final Future<void> Function() onLoginPressed;

  const _LoginCard({
    required this.theme,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.emailErrorText,
    required this.passwordErrorText,
    required this.errorText,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            /// EMAIL
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'admin@company.com',
                errorText: emailErrorText,
              ),
            ),

            const SizedBox(height: 16),

            /// PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: passwordErrorText,
              ),
            ),

            if (errorText != null && errorText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 24),

            /// LOGIN BUTTON
            FilledButton(
              onPressed: isLoading ? null : () => onLoginPressed(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Continue'),
            ),

            const SizedBox(height: 12),

            Text(
              'Owner accounts are read-only by design',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
