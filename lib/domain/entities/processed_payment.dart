import 'package:equatable/equatable.dart';
import 'payment.dart';

class ProcessedPayment extends Equatable {
  final String title;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final String category;
  final PaymentType type;
  final bool isRecurring;
  final String? recurringFrequency;
  final List<int> notificationDays;

  const ProcessedPayment({
    required this.title,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.category,
    required this.type,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notificationDays = const [],
  });

  @override
  List<Object?> get props => [
    title,
    amount,
    currency,
    dueDate,
    category,
    type,
    isRecurring,
    recurringFrequency,
    notificationDays,
  ];
}
