// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  Color _getCategoryColor() {
    switch (note.categoryColor) {
      case 'blue':
        return AppColors.purple;
      case 'green':
        return AppColors.green;
      case 'purple':
        return AppColors.purple;
      case 'orange':
        return AppColors.orange;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category indicator
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: AppTypography.noteTitle.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.preview,
                          style: AppTypography.notePreview.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: note.isFavorite ? AppColors.red : null,
                      size: 20,
                    ),
                    onPressed: onFavoriteToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tags and timestamp row
              Row(
                children: [
                  // Tags
                  if (note.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: note.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: AppTypography.noteTag.copyWith(
                                color: categoryColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Timestamp
                  Text(
                    note.timeAgo,
                    style: AppTypography.noteTimestamp.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
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
