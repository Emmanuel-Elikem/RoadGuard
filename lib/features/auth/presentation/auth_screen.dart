import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

/// Auth screen with sign in/up toggle.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
  }

  void _handleSubmit() {
    // TODO: Implement Firebase auth
    context.go(Routes.home);
  }

  void _handleGoogleSignIn() {
    // TODO: Implement Google sign in
    context.go(Routes.home);
  }

  void _handleGuestMode() {
    // TODO: Implement anonymous auth
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spacingXl),

              // Logo with modern rounded design
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.shield,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Title
              Text(
                _isSignUp ? 'Create Account' : 'Welcome Back',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                _isSignUp ? 'Sign up to start tracking' : 'Sign in to continue',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Email field
              _AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDimensions.spacingMd),

              // Password field
              _AuthTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: LucideIcons.lock,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (!_isSignUp) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Password reset
                    },
                    child: Text(
                      'Forgot password?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppDimensions.spacingMd),
              ],

              const SizedBox(height: AppDimensions.spacingMd),

              // Submit button with modern style
              SizedBox(
                height: AppDimensions.buttonHeightLg,
                child: FilledButton(
                  onPressed: _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                  ),
                  child: Text(
                    _isSignUp ? 'Sign Up' : 'Sign In',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLg),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                    ),
                    child: Text(
                      'or',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingLg),

              // Google sign in
              SizedBox(
                height: AppDimensions.buttonHeightLg,
                child: OutlinedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(LucideIcons.chrome, size: 20),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // Guest mode
              SizedBox(
                height: AppDimensions.buttonHeightLg,
                child: TextButton(
                  onPressed: _handleGuestMode,
                  child: Text(
                    'Continue as Guest',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Toggle mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account?'
                        : 'Don\'t have an account?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware text field for authentication forms.
class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingMd,
            ),
          ),
        ),
      ],
    );
  }
}
