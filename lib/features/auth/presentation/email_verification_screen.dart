import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../domain/providers/auth_providers.dart';

/// Email verification screen shown after sign up with email.
///
/// Prompts user to verify their email before accessing the app.
/// Auto-checks verification status periodically.
/// Pauses checking when app is backgrounded to save battery.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _checkTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isCheckingVerification = false;
  bool _isManuallyChecking = false; // For manual "I've verified" button

  @override
  void initState() {
    super.initState();
    // Register for lifecycle events to pause/resume timer
    WidgetsBinding.instance.addObserver(this);
    // Start periodic check for email verification
    _startVerificationCheck();
    // Send verification email after frame is built (avoids provider modification during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationEmail();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause timer when app is backgrounded, resume when foregrounded
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _checkTimer?.cancel();
      _checkTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      // Check immediately when returning to app
      _checkVerificationNow();
      // Restart periodic check
      _startVerificationCheck();
    }
  }

  Future<void> _checkVerificationNow() async {
    final isVerified = await ref
        .read(authNotifierProvider.notifier)
        .checkEmailVerified();
    if (isVerified && mounted) {
      _checkTimer?.cancel();
      // Invalidate authStateProvider to force router to re-check with fresh user data
      ref.invalidate(authStateProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go(Routes.home);
      }
    }
  }

  void _startVerificationCheck() {
    // Cancel existing timer if any
    _checkTimer?.cancel();
    // Check every 3 seconds if user has verified
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Prevent overlapping async checks - if one is still running, skip
      if (_isCheckingVerification) return;
      _performVerificationCheck();
    });
  }

  /// Performs the actual verification check with race condition protection.
  Future<void> _performVerificationCheck() async {
    if (_isCheckingVerification) return;
    // Early return if widget disposed to avoid unnecessary API calls
    if (!mounted) return;
    _isCheckingVerification = true;

    try {
      final isVerified = await ref
          .read(authNotifierProvider.notifier)
          .checkEmailVerified();
      if (isVerified && mounted) {
        _checkTimer?.cancel();
        // Invalidate authStateProvider to force router to re-check with fresh user data
        ref.invalidate(authStateProvider);
        // Small delay to let the provider refresh
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go(Routes.home);
        }
      }
    } finally {
      // Only update flag if widget is still mounted
      if (mounted) {
        _isCheckingVerification = false;
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    // Guard against multiple simultaneous resend attempts
    if (_isResending || _resendCooldown > 0) return;

    setState(() {
      _isResending = true;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendEmailVerification();

    if (mounted) {
      setState(() {
        _isResending = false;
        if (success) {
          _resendCooldown = 60; // 60 second cooldown
          _startCooldown();
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification email sent! Check your inbox.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
      } else {
        // Show error feedback when email fails to send
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send verification email. Please try again.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _cooldownTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _handleSignOut() async {
    _checkTimer?.cancel();
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) {
      context.go(Routes.auth);
    }
  }

  /// Manual verification check when user clicks "I've verified" button
  Future<void> _handleManualVerificationCheck() async {
    if (_isManuallyChecking) return;

    setState(() => _isManuallyChecking = true);

    try {
      final isVerified = await ref
          .read(authNotifierProvider.notifier)
          .checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        _checkTimer?.cancel();
        // Invalidate authStateProvider to force router to re-check with fresh user data
        ref.invalidate(authStateProvider);
        // Small delay to let the provider refresh
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go(Routes.home);
        }
      } else {
        // Show feedback that email is not verified yet
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email not verified yet. Please check your inbox and click the link.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManuallyChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _handleSignOut,
            child: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon with animated ring
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: Icon(
                  LucideIcons.mailCheck,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Title
              Text(
                'Verify Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // Subtitle with email
              Text(
                'We\'ve sent a verification link to',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              // Email address
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  user?.email ?? 'your email',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Instructions
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _InstructionRow(
                      icon: LucideIcons.inbox,
                      text: 'Check your email inbox',
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    _InstructionRow(
                      icon: LucideIcons.mousePointerClick,
                      text: 'Click the verification link',
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    _InstructionRow(
                      icon: LucideIcons.checkCircle,
                      text: 'Tap "I\'ve Verified" below',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Primary action: "I've Verified My Email" button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isManuallyChecking
                      ? null
                      : _handleManualVerificationCheck,
                  icon: _isManuallyChecking
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(LucideIcons.checkCircle, size: 20),
                  label: Text(
                    _isManuallyChecking
                        ? 'Checking...'
                        : 'I\'ve Verified My Email',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _sendVerificationEmail,
                  icon: _isResending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(LucideIcons.send, size: 20),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Verification Email',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // Help text
              Text(
                'Didn\'t receive the email? Check your spam folder.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
