import 'package:equatable/equatable.dart';

class ProcessedEvent extends Equatable {
  final String title;
  final DateTime dateTime;
  final String? location;
  final int? attendeesCount;
  final bool isRecurring;
  final String? recurringFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final List<int> notificationDays;

  const ProcessedEvent({
    required this.title,
    required this.dateTime,
    this.location,
    this.attendeesCount,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notificationDays = const [],
  });

  @override
  List<Object?> get props => [
    title,
    dateTime,
    location,
    attendeesCount,
    isRecurring,
    recurringFrequency,
    notificationDays,
  ];
}
