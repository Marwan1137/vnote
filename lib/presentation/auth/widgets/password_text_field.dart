// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/auth/validators/password_validator.dart';
import 'password_strength_indicator.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? labelText;
  final String? hintText;
  final bool showStrengthIndicator;
  final String? confirmPassword; // For confirm password field (static value)
  final String? Function()?
  getConfirmPassword; // Callback to get current password value

  const PasswordTextField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.showStrengthIndicator = false,
    this.confirmPassword,
    this.getConfirmPassword,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  PasswordValidationResult? _validationResult;
  String? _validatorError;

  @override
  void didUpdateWidget(PasswordTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check password match when widget updates (e.g., when password field changes)
    if (widget.getConfirmPassword != null || widget.confirmPassword != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentValue = widget.controller.text;
        _checkPasswordMatch(currentValue);
      });
    }
  }

  void _checkPasswordMatch(String value) {
    String? passwordToCompare;
    if (widget.getConfirmPassword != null) {
      passwordToCompare = widget.getConfirmPassword!();
    } else if (widget.confirmPassword != null) {
      passwordToCompare = widget.confirmPassword;
    } else {}

    if (passwordToCompare == null) {
      setState(() {
        _validationResult = null;
      });
      return;
    }

    // Store in local variable to satisfy null safety
    final password = passwordToCompare;
    final doMatch = value == password;
    if (!doMatch && value.isNotEmpty && password.isNotEmpty) {
    } else if (doMatch) {}

    setState(() {
      if (value.isNotEmpty && password.isNotEmpty) {
        if (value != password) {
          _validationResult = PasswordValidationResult(
            isValid: false,
            errors: ['Passwords do not match'],
            requirements: {},
            strength: PasswordStrength.weak,
          );
        } else {
          _validationResult = null; // Clear error when passwords match
        }
      } else {
        _validationResult = null; // Clear error when either field is empty
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final error = widget.validator?.call(value);
            setState(() {
              _validatorError = error;
            });
            return error;
          },
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Password',
            hintText: widget.hintText ?? 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            errorText: _validationResult?.errors.isNotEmpty == true
                ? _validationResult!.errors.first
                : _validatorError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            if (widget.showStrengthIndicator) {
              setState(() {
                _validationResult = PasswordValidator.validate(value);
                // Clear validator error when user types
                _validatorError = null;
              });
            } else if (widget.confirmPassword != null ||
                widget.getConfirmPassword != null) {
              // For confirm password field - compare with current password value
              _checkPasswordMatch(value);
              // Clear validator error when user types
              setState(() {
                _validatorError = null;
              });
            } else {
              // Clear validator error when user types
              setState(() {
                _validatorError = null;
              });
            }
            widget.onChanged?.call(value);
          },
        ),
        if (widget.showStrengthIndicator && _validationResult != null) ...[
          const SizedBox(height: 8),
          PasswordStrengthIndicator(
            strength: _validationResult!.strength,
            requirements: _validationResult!.requirements,
          ),
        ],
      ],
    );
  }
}
