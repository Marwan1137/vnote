import 'package:hive/hive.dart';
import '../../domain/entities/payment.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 1)
class PaymentModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final DateTime dueDate;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final int type; // 0 = toPay, 1 = toReceive

  @HiveField(7)
  final int status; // 0 = due, 1 = upcoming, 2 = overdue, 3 = paid

  @HiveField(8)
  final bool isRecurring;

  @HiveField(9)
  final String? recurringFrequency;

  @HiveField(10)
  final List<int> notificationDays;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final DateTime? paymentDate;

  @HiveField(14)
  final String? notes;

  const PaymentModel({
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

  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      id: payment.id,
      title: payment.title,
      amount: payment.amount,
      currency: payment.currency,
      dueDate: payment.dueDate,
      category: payment.category,
      type: payment.type == PaymentType.toPay ? 0 : 1,
      status: payment.status == PaymentStatus.due
          ? 0
          : payment.status == PaymentStatus.upcoming
          ? 1
          : payment.status == PaymentStatus.overdue
          ? 2
          : 3,
      isRecurring: payment.isRecurring,
      recurringFrequency: payment.recurringFrequency,
      notificationDays: payment.notificationDays,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      paymentDate: payment.paymentDate,
      notes: payment.notes,
    );
  }

  Payment toEntity() {
    return Payment(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      dueDate: dueDate,
      category: category,
      type: type == 0 ? PaymentType.toPay : PaymentType.toReceive,
      status: status == 0
          ? PaymentStatus.due
          : status == 1
          ? PaymentStatus.upcoming
          : status == 2
          ? PaymentStatus.overdue
          : PaymentStatus.paid,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      notificationDays: notificationDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentDate: paymentDate,
      notes: notes,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      category: json['category'] as String,
      type: json['type'] as int,
      status: json['status'] as int,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String?,
      notificationDays:
          (json['notificationDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'type': type,
      'status': status,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'notificationDays': notificationDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? currency,
    DateTime? dueDate,
    String? category,
    int? type,
    int? status,
    bool? isRecurring,
    String? recurringFrequency,
    List<int>? notificationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paymentDate,
    String? notes,
  }) {
    return PaymentModel(
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
}
