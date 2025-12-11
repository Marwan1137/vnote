// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/domain/entities/event.dart';
import 'package:vnote/presentation/cubit/events/events_cubit.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/screens/recording/recording_screen.dart';
import 'package:vnote/presentation/widgets/app_bar_actions.dart';
import 'package:vnote/core/utils/page_transitions.dart';

class AddEventScreen extends StatefulWidget {
  final Event event;

  const AddEventScreen({super.key, required this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _attendeesController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isRecurring = false;
  String? _recurringFrequency;
  List<int> _notificationDays = [];
  bool _isProcessingVoice = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description ?? '';
    _locationController.text = widget.event.location ?? '';
    _attendeesController.text = widget.event.attendeesCount?.toString() ?? '';
    _selectedDateTime = widget.event.dateTime;
    _isRecurring = widget.event.isRecurring;
    _recurringFrequency = widget.event.recurringFrequency;
    _notificationDays = widget.event.notificationDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _attendeesController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceRecording() async {
    final result = await Navigator.push(
      context,
      FadePageRoute(
        page: BlocProvider(
          create: (context) => getIt<RecordingCubit>(),
          child: const RecordingScreen(mode: RecordingMode.event),
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _isProcessingVoice = true;
      });

      await context.read<EventsCubit>().processTranscription(result);

      setState(() {
        _isProcessingVoice = false;
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      final now = DateTime.now();
      final event = Event(
        id: widget.event.id,
        userId: widget.event.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTime: _selectedDateTime!,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        attendeesCount: _attendeesController.text.trim().isEmpty
            ? null
            : int.tryParse(_attendeesController.text.trim()),
        status: widget.event.status,
        isRecurring: _isRecurring,
        recurringFrequency: _recurringFrequency,
        recurringEndDate: widget.event.recurringEndDate,
        notificationDays: _notificationDays,
        createdAt: widget.event.createdAt,
        updatedAt: now,
      );

      context.read<EventsCubit>().updateEvent(event);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startVoiceRecording,
          ),
          const AppBarActions(),
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
                    _buildVoicePrompt(),
                    const SizedBox(height: 24),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildDateTimeField(),
                    const SizedBox(height: 16),
                    _buildLocationField(),
                    const SizedBox(height: 16),
                    _buildAttendeesField(),
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

  Widget _buildVoicePrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Say: "Meeting tomorrow at 3 PM at the office"',
              style: AppTypography.bodySmall.copyWith(color: AppColors.green),
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
        labelText: 'Event Title',
        hintText: 'e.g., Team Meeting',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add event details...',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
    );
  }

  Widget _buildDateTimeField() {
    return InkWell(
      onTap: _selectDateTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date & Time',
          prefixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          _selectedDateTime != null
              ? '${DateFormat('MMM d, yyyy').format(_selectedDateTime!)} at ${DateFormat('h:mm a').format(_selectedDateTime!)}'
              : 'Select date and time',
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Location (Optional)',
        hintText: 'e.g., Conference Room A',
        prefixIcon: Icon(Icons.location_on),
      ),
    );
  }

  Widget _buildAttendeesField() {
    return TextFormField(
      controller: _attendeesController,
      decoration: const InputDecoration(
        labelText: 'Number of Attendees (Optional)',
        hintText: 'e.g., 5',
        prefixIcon: Icon(Icons.people),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final count = int.tryParse(value.trim());
          if (count == null || count < 0) {
            return 'Please enter a valid number';
          }
        }
        return null;
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
                'Recurring Event',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isRecurring)
                Text(
                  _recurringFrequency ?? 'Monthly',
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
              if (value) {
                _recurringFrequency = 'monthly';
              } else {
                _recurringFrequency = null;
              }
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
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Event'),
          ),
        ),
      ],
    );
  }
}
