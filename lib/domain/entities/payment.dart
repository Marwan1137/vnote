import 'package:equatable/equatable.dart';

enum PaymentType { toPay, toReceive }

enum PaymentStatus { due, upcoming, overdue, paid }

class Payment extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final String category;
  final PaymentType type;
  final PaymentStatus status;
  final bool isRecurring;
  final String? recurringFrequency; // 'monthly', 'weekly', 'yearly'
  final List<int>
  notificationDays; // Days before due date to notify (e.g., [0, 1, 7])
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paymentDate; // When payment was actually made
  final String? notes;

  const Payment({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.category,
    required this.type,
    required this.status,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notificationDays = const [],
    required this.createdAt,
    required this.updatedAt,
    this.paymentDate,
    this.notes,
  });

  Payment copyWith({
    String? id,
    String? title,
    double? amount,
    String? currency,
    DateTime? dueDate,
    String? category,
    PaymentType? type,
    PaymentStatus? status,
    bool? isRecurring,
    String? recurringFrequency,
    List<int>? notificationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paymentDate,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      type: type ?? this.type,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      notificationDays: notificationDays ?? this.notificationDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    currency,
    dueDate,
    category,
    type,
    status,
    isRecurring,
    recurringFrequency,
    notificationDays,
    createdAt,
    updatedAt,
    paymentDate,
    notes,
  ];
}
