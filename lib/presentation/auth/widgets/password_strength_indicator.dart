// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/auth/validators/password_validator.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final Map<String, bool> requirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    required this.requirements,
  });

  Color _getStrengthColor() {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return AppColors.green;
    }
  }

  String _getStrengthText() {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: _getStrengthColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStrengthText(),
              style: AppTypography.bodySmall.copyWith(
                color: _getStrengthColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...requirements.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: entry.value
                      ? AppColors.green
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: AppTypography.bodySmall.copyWith(
                    color: entry.value
                        ? AppColors.green
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
