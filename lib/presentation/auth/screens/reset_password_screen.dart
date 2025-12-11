// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/auth/validators/password_validator.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/presentation/auth/cubit/auth_cubit.dart';
import 'package:vnote/presentation/auth/cubit/auth_state.dart';
import 'package:vnote/presentation/auth/screens/sign_in_screen.dart';
import 'package:vnote/presentation/auth/widgets/password_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String actionCode; // Action code from the password reset link

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.actionCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<AuthCubit>().resetPassword(
      widget.email,
      widget.actionCode, // Pass the action code from the email link
      _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is AuthUnauthenticated) {
            // Password reset successful
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Password reset successfully! Please sign in with your new password.',
                ),
                backgroundColor: AppColors.green,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              SlidePageRoute(
                page: BlocProvider(
                  create: (context) => getIt<AuthCubit>(),
                  child: const SignInScreen(),
                ),
              ),
              (route) => false,
            );
          } else if (state is AuthError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.lock_outlined, size: 80, color: AppColors.green),
                  const SizedBox(height: 24),
                  Text(
                    'Create New Password',
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your new password below',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  PasswordTextField(
                    controller: _newPasswordController,
                    labelText: 'New Password',
                    showStrengthIndicator: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      final result = PasswordValidator.validate(value);
                      if (!result.isValid) {
                        return result.errors.first;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  PasswordTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm New Password',
                    getConfirmPassword: () => _newPasswordController.text,
                    onChanged: (_) {
                      // Trigger validation when either field changes
                      if (_formKey.currentState != null) {
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
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
                        : const Text('Reset Password'),
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
