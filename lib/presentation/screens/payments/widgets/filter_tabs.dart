// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/presentation/cubit/payments/payments_state.dart';

class FilterTabs extends StatelessWidget {
  final PaymentFilter currentFilter;
  final Function(PaymentFilter) onFilterChanged;

  const FilterTabs({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTab(
            context,
            'All',
            PaymentFilter.all,
            currentFilter == PaymentFilter.all,
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            'To Pay',
            PaymentFilter.toPay,
            currentFilter == PaymentFilter.toPay,
          ),
          const SizedBox(width: 8),
          _buildTab(
            context,
            'To Receive',
            PaymentFilter.toReceive,
            currentFilter == PaymentFilter.toReceive,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    PaymentFilter filter,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.purple
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.purple : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
