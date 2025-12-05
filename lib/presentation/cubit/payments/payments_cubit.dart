import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/payments/create_payment_usecase.dart';
import '../../../domain/usecases/payments/delete_payment_usecase.dart';
import '../../../domain/usecases/payments/get_all_payments_usecase.dart';
import '../../../domain/usecases/payments/get_payments_by_month_usecase.dart';
import '../../../domain/usecases/payments/get_payments_by_type_usecase.dart';
import '../../../domain/usecases/payments/mark_payment_paid_usecase.dart';
import '../../../domain/usecases/payments/process_payment_transcription_usecase.dart';
import '../../../domain/usecases/payments/update_payment_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import 'payments_state.dart';

@injectable
class PaymentsCubit extends Cubit<PaymentsState> {
  final GetAllPaymentsUseCase getAllPaymentsUseCase;
  final GetPaymentsByMonthUseCase getPaymentsByMonthUseCase;
  final GetPaymentsByTypeUseCase getPaymentsByTypeUseCase;
  final CreatePaymentUseCase createPaymentUseCase;
  final UpdatePaymentUseCase updatePaymentUseCase;
  final DeletePaymentUseCase deletePaymentUseCase;
  final MarkPaymentPaidUseCase markPaymentPaidUseCase;
  final ProcessPaymentTranscriptionUseCase processPaymentTranscriptionUseCase;

  PaymentsCubit(
    this.getAllPaymentsUseCase,
    this.getPaymentsByMonthUseCase,
    this.getPaymentsByTypeUseCase,
    this.createPaymentUseCase,
    this.updatePaymentUseCase,
    this.deletePaymentUseCase,
    this.markPaymentPaidUseCase,
    this.processPaymentTranscriptionUseCase,
  ) : super(PaymentsInitial());

  Future<void> loadPayments() async {
    emit(PaymentsLoading());

    final result = await getAllPaymentsUseCase(const NoParams());

    result.fold(
      (failure) {
        emit(PaymentsError(failure.message));
      },
      (payments) {
        if (payments.isEmpty) {
          emit(PaymentsEmpty());
        } else {
          emit(PaymentsLoaded(payments: payments, filteredPayments: payments));
        }
      },
    );
  }

  Future<void> loadPaymentsByMonth(int year, int month) async {
    emit(PaymentsLoading());

    final result = await getPaymentsByMonthUseCase(
      GetPaymentsByMonthParams(year, month),
    );

    result.fold(
      (failure) {
        emit(PaymentsError(failure.message));
      },
      (payments) {
        final currentState = state;
        if (currentState is PaymentsLoaded) {
          emit(
            currentState.copyWith(
              payments: List<Payment>.from(payments),
              filteredPayments: List<Payment>.from(payments),
              selectedYear: year,
              selectedMonth: month,
            ),
          );
        } else {
          emit(
            PaymentsLoaded(
              payments: List<Payment>.from(payments),
              filteredPayments: List<Payment>.from(payments),
              selectedYear: year,
              selectedMonth: month,
            ),
          );
        }
      },
    );
  }

  void applyFilter(PaymentFilter filter) {
    final currentState = state;
    if (currentState is! PaymentsLoaded) return;

    List<Payment> filtered;
    if (filter == PaymentFilter.all) {
      filtered = currentState.payments;
    } else {
      final type = filter == PaymentFilter.toPay
          ? PaymentType.toPay
          : PaymentType.toReceive;
      filtered = currentState.payments.where((p) => p.type == type).toList();
    }

    emit(currentState.copyWith(filteredPayments: filtered, filter: filter));
  }

  Future<void> createPayment(Payment payment) async {
    final result = await createPaymentUseCase(payment);

    result.fold((failure) => emit(PaymentsError(failure.message)), (
      createdPayment,
    ) {
      final currentState = state;
      if (currentState is PaymentsLoaded) {
        final updatedPayments = [createdPayment, ...currentState.payments];
        emit(
          currentState.copyWith(
            payments: List<Payment>.from(updatedPayments),
            filteredPayments: List<Payment>.from(updatedPayments),
          ),
        );
      } else {
        loadPayments();
      }
    });
  }

  Future<void> updatePayment(Payment payment) async {
    final updatedPayment = payment.copyWith(updatedAt: DateTime.now());
    final result = await updatePaymentUseCase(updatedPayment);

    result.fold((failure) => emit(PaymentsError(failure.message)), (updated) {
      final currentState = state;
      if (currentState is PaymentsLoaded) {
        final updatedPayments = currentState.payments
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        emit(
          currentState.copyWith(
            payments: List<Payment>.from(updatedPayments),
            filteredPayments: List<Payment>.from(updatedPayments),
          ),
        );
      } else {
        loadPayments();
      }
    });
  }

  Future<void> deletePayment(String id) async {
    final result = await deletePaymentUseCase(DeletePaymentParams(id));

    result.fold((failure) => emit(PaymentsError(failure.message)), (_) {
      final currentState = state;
      if (currentState is PaymentsLoaded) {
        final updatedPayments = currentState.payments
            .where((p) => p.id != id)
            .toList();
        if (updatedPayments.isEmpty) {
          emit(PaymentsEmpty());
        } else {
          emit(
            currentState.copyWith(
              payments: updatedPayments,
              filteredPayments: updatedPayments,
            ),
          );
        }
      } else {
        loadPayments();
      }
    });
  }

  Future<void> markAsPaid(String id) async {
    final result = await markPaymentPaidUseCase(MarkPaymentPaidParams(id));

    result.fold((failure) => emit(PaymentsError(failure.message)), (updated) {
      final currentState = state;
      if (currentState is PaymentsLoaded) {
        final updatedPayments = currentState.payments
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        emit(
          currentState.copyWith(
            payments: List<Payment>.from(updatedPayments),
            filteredPayments: List<Payment>.from(updatedPayments),
          ),
        );
      } else {
        loadPayments();
      }
    });
  }

  Future<void> processTranscription(String transcription) async {
    final result = await processPaymentTranscriptionUseCase(
      ProcessPaymentTranscriptionParams(transcription),
    );

    result.fold(
      (failure) {
        emit(PaymentsError(failure.message));
      },
      (processedPayments) async {
        // Create all payments simultaneously for better performance
        final now = DateTime.now();
        final baseTimestamp = now.millisecondsSinceEpoch;
        final paymentsToCreate = processedPayments.asMap().entries.map((entry) {
          final index = entry.key;
          final processed = entry.value;
          return Payment(
            id: '${baseTimestamp}_$index',
            title: processed.title,
            amount: processed.amount,
            currency: processed.currency,
            dueDate: processed.dueDate,
            category: processed.category,
            type: processed.type,
            status: _calculateStatus(
              processed.dueDate,
              processed.type,
              processed.isRecurring,
            ),
            isRecurring: processed.isRecurring,
            recurringFrequency: processed.recurringFrequency,
            notificationDays: processed.notificationDays,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

        // Create all payments in parallel
        final createResults = await Future.wait(
          paymentsToCreate.map((payment) => createPaymentUseCase(payment)),
        );

        // Check if all succeeded and update state once
        final currentState = state;

        final createdPayments = <Payment>[];
        bool hasError = false;

        for (var i = 0; i < createResults.length; i++) {
          final result = createResults[i];
          result.fold(
            (failure) {
              // If any payment creation fails, mark error
              if (!hasError) {
                hasError = true;
                emit(PaymentsError(failure.message));
              }
            },
            (payment) {
              createdPayments.add(payment);
            },
          );
        }

        // If there was an error, don't update state
        if (hasError || createdPayments.length != paymentsToCreate.length) {
          await loadPayments();
          return;
        }

        // Update state based on current state
        if (currentState is PaymentsLoaded) {
          // State is already loaded, add new payments to existing list
          final updatedPayments = [
            ...createdPayments,
            ...currentState.payments,
          ];

          // Reapply current filter to filteredPayments
          List<Payment> filtered;
          if (currentState.filter == PaymentFilter.all) {
            filtered = updatedPayments;
          } else {
            final type = currentState.filter == PaymentFilter.toPay
                ? PaymentType.toPay
                : PaymentType.toReceive;
            filtered = updatedPayments.where((p) => p.type == type).toList();
          }

          emit(
            currentState.copyWith(
              payments: List<Payment>.from(updatedPayments),
              filteredPayments: List<Payment>.from(filtered),
            ),
          );
        } else {
          // State is PaymentsEmpty or PaymentsInitial - emit PaymentsLoaded directly with created payments
          emit(
            PaymentsLoaded(
              payments: List<Payment>.from(createdPayments),
              filteredPayments: List<Payment>.from(createdPayments),
            ),
          );
        }
      },
    );
  }

  PaymentStatus _calculateStatus(
    DateTime dueDate,
    PaymentType type,
    bool isRecurring,
  ) {
    // For non-recurring payments, just record them without status
    if (!isRecurring) {
      return PaymentStatus.upcoming; // Just a record, no due date tracking
    }

    // For "To Receive" payments (income), they can't be overdue
    // They're either received (paid) or pending
    if (type == PaymentType.toReceive) {
      return PaymentStatus
          .upcoming; // Income is always "upcoming" until received
    }

    // For recurring "To Pay" payments (expenses), calculate based on due date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      return PaymentStatus.overdue;
    } else if (due.isAtSameMomentAs(today)) {
      return PaymentStatus.due;
    } else {
      return PaymentStatus.upcoming;
    }
  }
}
