import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/presentation/cubit/payments/payments_cubit.dart';
import 'package:vnote/presentation/cubit/payments/payments_state.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/screens/payments/payment_detail_screen.dart';
import 'package:vnote/presentation/screens/payments/widgets/filter_tabs.dart';
import 'package:vnote/presentation/screens/payments/widgets/monthly_summary_card.dart';
import 'package:vnote/presentation/screens/payments/widgets/payment_card.dart';
import 'package:vnote/presentation/screens/recording/recording_screen.dart';
import 'package:vnote/presentation/widgets/unified_mic_fab.dart';
import 'package:vnote/core/utils/page_transitions.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int? selectedYear;
  int? selectedMonth;
  bool _hasLoaded = false;
  bool _justCreatedPayments = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load payments after the BlocProvider is available (only once)
    if (!_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PaymentsCubit>().loadPayments();
        }
      });
    }
  }

  void _onFilterChanged(PaymentFilter filter) {
    context.read<PaymentsCubit>().applyFilter(filter);
  }

  void _onMonthChanged(int year, int month) {
    // Don't reload if we just created payments
    if (_justCreatedPayments) {
      return;
    }

    setState(() {
      selectedYear = year;
      selectedMonth = month;
    });
    context.read<PaymentsCubit>().loadPaymentsByMonth(year, month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payments',
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
      body: BlocConsumer<PaymentsCubit, PaymentsState>(
        listener: (context, state) {
          if (state is PaymentsLoaded) {
            // If we just created payments, don't trigger any reloads
            if (_justCreatedPayments && state.payments.isNotEmpty) {
              return;
            }
          }
        },
        builder: (context, state) {
          if (state is PaymentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTypography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PaymentsCubit>().loadPayments(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentsEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: AppColors.gray),
                  const SizedBox(height: 16),
                  Text('No payments yet', style: AppTypography.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the microphone button to add your first payment',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is PaymentsLoaded) {
            final toPayTotal = state.filteredPayments
                .where((p) => p.type == PaymentType.toPay)
                .fold<double>(0.0, (sum, p) => sum + p.amount);

            final toReceiveTotal = state.filteredPayments
                .where((p) => p.type == PaymentType.toReceive)
                .fold<double>(0.0, (sum, p) => sum + p.amount);

            return Column(
              children: [
                MonthlySummaryCard(
                  toPayTotal: toPayTotal,
                  toReceiveTotal: toReceiveTotal,
                  onMonthChanged: _onMonthChanged,
                  selectedYear: selectedYear ?? DateTime.now().year,
                  selectedMonth: selectedMonth ?? DateTime.now().month,
                ),
                FilterTabs(
                  currentFilter: state.filter,
                  onFilterChanged: _onFilterChanged,
                ),
                Expanded(
                  child: state.filteredPayments.isEmpty
                      ? Center(
                          child: Text(
                            'No payments found',
                            style: AppTypography.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = state.filteredPayments[index];
                            return PaymentCard(
                              payment: payment,
                              onTap: () {
                                final cubit = context.read<PaymentsCubit>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider.value(
                                      value: cubit,
                                      child: PaymentDetailScreen(
                                        payment: payment,
                                      ),
                                    ),
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    cubit.loadPayments();
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
        buildWhen: (previous, current) {
          return true;
        },
      ),
      floatingActionButton: UnifiedMicFab(
        onPressed: _onStartVoiceRecording,
        heroTag: 'mic_fab_payments',
      ),
    );
  }

  void _onStartVoiceRecording() async {
    final result = await Navigator.push(
      context,
      FadePageRoute(
        page: BlocProvider(
          create: (context) => getIt<RecordingCubit>(),
          child: const RecordingScreen(mode: RecordingMode.payment),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null && result is String) {
      final cubit = context.read<PaymentsCubit>();

      // Mark that we just created payments to prevent automatic reload
      _justCreatedPayments = true;

      await cubit.processTranscription(result);

      // Check if state was updated successfully
      if (mounted) {
        final currentState = cubit.state;
        if (currentState is! PaymentsLoaded) {
          // State wasn't updated, reload all payments
          // But don't reload if we just created payments
          if (!_justCreatedPayments) {
            await Future.delayed(const Duration(milliseconds: 100));
            if (selectedYear != null && selectedMonth != null) {
              await cubit.loadPaymentsByMonth(selectedYear!, selectedMonth!);
            } else {
              await cubit.loadPayments();
            }
          }
        }

        // Reset flag immediately after state is updated
        if (mounted) {
          _justCreatedPayments = false;
        }
      }
    } else {}
  }
}
