// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/auth/entities/user.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/presentation/auth/cubit/auth_cubit.dart';
import 'package:vnote/presentation/auth/cubit/auth_state.dart';
import 'package:vnote/presentation/screens/home_screen/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;

  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
    });
    try {
      await context.read<AuthCubit>().checkEmailVerification().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Verification check timed out');
        },
      );

      // Fallback: Reset loading state after a short delay if listener didn't catch it
      // This handles the case where the state is the same and listener doesn't trigger
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _isChecking) {
        setState(() {
          _isChecking = false;
        });
        // Show message to user since listener didn't trigger
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not verified yet. Please check your inbox and click the verification link.',
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check verification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isResending = true;
    });
    await context.read<AuthCubit>().sendEmailVerification();
    setState(() {
      _isResending = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (mounted) {
              setState(() {
                _isChecking = false;
              });
              Navigator.of(
                context,
              ).pushReplacement(FadePageRoute(page: const HomeScreen()));
            }
          } else if (state is AuthError) {
            if (mounted) {
              setState(() {
                _isChecking = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } else if (state is AuthEmailNotVerified) {
            if (mounted) {
              setState(() {
                _isChecking = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Email not verified yet. Please check your inbox and click the verification link.',
                  ),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 4),
                ),
              );
            } else {}
          } else if (state is AuthLoading) {
            // Keep loading indicator visible
          } else {
            // For any other state, reset loading just in case
            if (mounted && _isChecking) {
              setState(() {
                _isChecking = false;
              });
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.email_outlined, size: 100, color: AppColors.green),
                const SizedBox(height: 32),
                Text(
                  'Verify Your Email',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a verification email to:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Please check your email and click the verification link to activate your account.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('I\'ve Verified My Email'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isResending ? null : _resendVerification,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Verification Email'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
