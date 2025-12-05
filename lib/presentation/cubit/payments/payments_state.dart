import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<Payment> payments;
  final List<Payment> filteredPayments;
  final PaymentFilter filter;
  final int? selectedYear;
  final int? selectedMonth;

  const PaymentsLoaded({
    required this.payments,
    required this.filteredPayments,
    this.filter = PaymentFilter.all,
    this.selectedYear,
    this.selectedMonth,
  });

  @override
  List<Object?> get props => [
    payments,
    filteredPayments,
    filter,
    selectedYear,
    selectedMonth,
  ];

  PaymentsLoaded copyWith({
    List<Payment>? payments,
    List<Payment>? filteredPayments,
    PaymentFilter? filter,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return PaymentsLoaded(
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      filter: filter ?? this.filter,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class PaymentsEmpty extends PaymentsState {}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

enum PaymentFilter { all, toPay, toReceive }
