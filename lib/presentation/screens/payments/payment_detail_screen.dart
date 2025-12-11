import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/constants/currencies.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/presentation/cubit/payments/payments_cubit.dart';
import 'package:vnote/presentation/cubit/payments/payments_state.dart';
import 'package:vnote/presentation/screens/payments/add_payment_screen.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        // Get the updated payment from state if available
        Payment currentPayment = payment;
        if (state is PaymentsLoaded) {
          final updatedPayment = state.payments.firstWhere(
            (p) => p.id == payment.id,
            orElse: () => payment,
          );
          currentPayment = updatedPayment;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final cubit = context.read<PaymentsCubit>();
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: BlocProvider.value(
                        value: cubit,
                        child: AddPaymentScreen(payment: currentPayment),
                      ),
                    ),
                  ).then((result) {
                    if (result == true && context.mounted) {
                      // Reload payments to get updated data
                      cubit.loadPayments();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, currentPayment),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard(
                  context,
                  'Title',
                  currentPayment.title,
                  Icons.title,
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Amount',
                  '${currentPayment.type == PaymentType.toPay ? '-' : '+'}${Currencies.getSymbol(currentPayment.currency)}${currentPayment.amount.toStringAsFixed(2)}',
                  Icons.attach_money,
                  color: currentPayment.type == PaymentType.toPay
                      ? AppColors.red
                      : AppColors.green,
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Type',
                  currentPayment.type == PaymentType.toPay
                      ? 'To Pay'
                      : 'To Receive',
                  currentPayment.type == PaymentType.toPay
                      ? Icons.trending_down
                      : Icons.trending_up,
                  color: currentPayment.type == PaymentType.toPay
                      ? AppColors.red
                      : AppColors.green,
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Status',
                  _getStatusText(currentPayment.status),
                  _getStatusIcon(currentPayment.status),
                  color: _getStatusColor(currentPayment.status),
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Due Date',
                  DateFormat('MMMM d, yyyy').format(currentPayment.dueDate),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Created Date',
                  DateFormat('MMMM d, yyyy').format(currentPayment.createdAt),
                  Icons.access_time,
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  context,
                  'Category',
                  currentPayment.category,
                  Icons.category,
                ),
                if (currentPayment.isRecurring) ...[
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    context,
                    'Recurring',
                    currentPayment.recurringFrequency ?? 'Monthly',
                    Icons.repeat,
                    color: AppColors.purple,
                  ),
                ],
                if (currentPayment.notificationDays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    context,
                    'Notifications',
                    currentPayment.notificationDays
                        .map(
                          (days) => days == 0
                              ? 'Same day'
                              : days == 1
                              ? '1 day before'
                              : '$days days before',
                        )
                        .join(', '),
                    Icons.notifications,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: (color ?? AppColors.purple).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color ?? AppColors.purple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.bodyLarge.copyWith(
                      color: color ?? Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.due:
        return 'Due';
      case PaymentStatus.upcoming:
        return 'Upcoming';
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.overdue:
        return Icons.error;
      case PaymentStatus.due:
        return Icons.schedule;
      case PaymentStatus.upcoming:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.green;
      case PaymentStatus.overdue:
        return AppColors.red;
      case PaymentStatus.due:
        return AppColors.orange;
      case PaymentStatus.upcoming:
        return AppColors.info;
    }
  }

  void _showDeleteDialog(BuildContext context, Payment payment) {
    final cubit = context.read<PaymentsCubit>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete "${payment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.deletePayment(payment.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
