// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/auth/validators/email_validator.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';

class EmailTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? labelText;
  final String? hintText;

  const EmailTextField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.labelText,
    this.hintText,
  });

  @override
  State<EmailTextField> createState() => _EmailTextFieldState();
}

class _EmailTextFieldState extends State<EmailTextField> {
  String? _errorText;
  String? _suggestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Email',
            hintText: widget.hintText ?? 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            final result = EmailValidator.validateWithSuggestion(value);
            setState(() {
              _errorText = result.error;
              _suggestion = result.suggestion;
            });
            widget.onChanged?.call(value);
          },
        ),
        if (_suggestion != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: AppColors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Did you mean $_suggestion?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.green,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.controller.text = _suggestion!;
                  setState(() {
                    _suggestion = null;
                    _errorText = null;
                  });
                  widget.onChanged?.call(_suggestion!);
                },
                child: const Text('Use this'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
