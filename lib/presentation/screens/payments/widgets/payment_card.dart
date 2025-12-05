// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/constants/currencies.dart';
import 'package:vnote/domain/entities/payment.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback? onMarkPaid;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    // Border color based on payment type, not status
    final borderColor = payment.type == PaymentType.toPay
        ? AppColors.red
        : AppColors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.title,
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (payment.isRecurring) _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    payment.category,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${payment.type == PaymentType.toPay ? '-' : '+'}${Currencies.getSymbol(payment.currency)}${payment.amount.toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(
                  color: payment.type == PaymentType.toPay
                      ? AppColors.red
                      : AppColors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (payment.isRecurring) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM d, yyyy').format(payment.dueDate)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.repeat, size: 16, color: AppColors.purple),
                    const SizedBox(width: 4),
                    Text(
                      payment.recurringFrequency ?? 'Monthly',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('MMM d, yyyy').format(payment.createdAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray,
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

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData icon;

    switch (payment.status) {
      case PaymentStatus.paid:
        badgeColor = AppColors.green;
        statusText = 'Paid';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.overdue:
        badgeColor = AppColors.red;
        statusText = 'Overdue';
        icon = Icons.error;
        break;
      case PaymentStatus.due:
        badgeColor = AppColors.orange;
        statusText = 'Due';
        icon = Icons.schedule;
        break;
      case PaymentStatus.upcoming:
        badgeColor = AppColors.info;
        statusText = 'Upcoming';
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: AppTypography.bodySmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
