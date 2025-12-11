// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/presentation/cubit/notes/notes_state.dart';

class FilterChips extends StatelessWidget {
  final NotesFilter currentFilter;
  final Function(NotesFilter) onFilterChanged;

  const FilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              label: 'All',
              filter: NotesFilter.all,
              icon: Icons.list,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Recent',
              filter: NotesFilter.recent,
              icon: Icons.access_time,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Favorites',
              filter: NotesFilter.favorites,
              icon: Icons.favorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required NotesFilter filter,
    required IconData icon,
  }) {
    final isSelected = currentFilter == filter;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(filter);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: AppColors.red,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.red.withOpacity(0.6)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
