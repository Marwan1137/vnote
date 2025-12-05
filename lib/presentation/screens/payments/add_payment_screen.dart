// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/constants/currencies.dart';
import 'package:vnote/core/constants/payment_categories.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/presentation/cubit/payments/payments_cubit.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/screens/recording/recording_screen.dart';

class AddPaymentScreen extends StatefulWidget {
  final Payment? payment;

  const AddPaymentScreen({super.key, this.payment});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentType _selectedType = PaymentType.toPay;
  DateTime? _selectedDate;
  String _selectedCategory = PaymentCategories.categories.first;
  String _selectedCurrency = 'USD';
  bool _isRecurring = false;
  String? _recurringFrequency;
  List<int> _notificationDays = [];
  bool _isProcessingVoice = false;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _titleController.text = widget.payment!.title;
      _amountController.text = widget.payment!.amount.toString();
      _selectedType = widget.payment!.type;
      _selectedDate = widget.payment!.dueDate;
      _selectedCategory = widget.payment!.category;
      _selectedCurrency = widget.payment!.currency;
      _isRecurring = widget.payment!.isRecurring;
      _recurringFrequency = widget.payment!.recurringFrequency;
      _notificationDays = widget.payment!.notificationDays;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceRecording() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<RecordingCubit>(),
          child: const RecordingScreen(mode: RecordingMode.payment),
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _isProcessingVoice = true;
      });

      await context.read<PaymentsCubit>().processTranscription(result);

      setState(() {
        _isProcessingVoice = false;
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _savePayment() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final now = DateTime.now();
      final payment = Payment(
        id:
            widget.payment?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        dueDate: _selectedDate!,
        category: _selectedCategory,
        type: _selectedType,
        status: _calculateStatus(_selectedDate!, _selectedType, _isRecurring),
        isRecurring: _isRecurring,
        recurringFrequency: _recurringFrequency,
        notificationDays: _notificationDays,
        createdAt: widget.payment?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.payment != null) {
        context.read<PaymentsCubit>().updatePayment(payment);
      } else {
        context.read<PaymentsCubit>().createPayment(payment);
      }

      Navigator.pop(context, true);
    }
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
    if (type == PaymentType.toReceive) {
      return PaymentStatus.upcoming;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment != null ? 'Edit Payment' : 'New Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startVoiceRecording,
          ),
        ],
      ),
      body: _isProcessingVoice
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildVoicePrompt(),
                    const SizedBox(height: 24),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                    const SizedBox(height: 16),
                    _buildNotificationOptions(),
                    const SizedBox(height: 16),
                    _buildRecurringToggle(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            'I Need to Pay',
            PaymentType.toPay,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeButton(
            'I Will Receive',
            PaymentType.toReceive,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String label, PaymentType type, IconData icon) {
    final isSelected = _selectedType == type;
    final color = type == PaymentType.toPay ? AppColors.red : AppColors.green;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: AppColors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Say: "Pay electric bill 125 dollars on December 3rd"',
              style: AppTypography.bodySmall.copyWith(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Payment Title',
        hintText: 'e.g., Electric Bill',
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a payment title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: Currencies.getSymbol(_selectedCurrency),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Due Date',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : 'Select date',
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
      ),
      items: PaymentCategories.categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildNotificationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notify Me',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildNotificationChip('Same day', 0),
            _buildNotificationChip('1 day before', 1),
            _buildNotificationChip('1 week before', 7),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationChip(String label, int days) {
    final isSelected = _notificationDays.contains(days);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _notificationDays.add(days);
          } else {
            _notificationDays.remove(days);
          }
        });
      },
    );
  }

  Widget _buildRecurringToggle() {
    return Row(
      children: [
        const Icon(Icons.repeat),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recurring Payment',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isRecurring)
                Text(
                  'Repeat monthly',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              _recurringFrequency = value ? 'monthly' : null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _savePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Payment'),
          ),
        ),
      ],
    );
  }
}
