// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';

class EmptyState extends StatelessWidget {
  final String? message;

  const EmptyState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_outlined, size: 64, color: AppColors.red),
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'No notes yet',
              style: AppTypography.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message == null
                  ? 'Tap the microphone button to create your first note'
                  : 'Try adjusting your search or tap the microphone to create a new note',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
