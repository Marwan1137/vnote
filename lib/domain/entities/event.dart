import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum EventStatus { upcoming, completed, cancelled }

class Event extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? location;
  final int? attendeesCount;
  final EventStatus status;
  final bool isRecurring;
  final String? recurringFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? recurringEndDate;
  final List<int>
  notificationDays; // Days before event to notify (e.g., [0, 1, 7])
  final DateTime createdAt;
  final DateTime updatedAt;
  final Color color; // Single color for all events (green)

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
    this.attendeesCount,
    this.status = EventStatus.upcoming,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringEndDate,
    this.notificationDays = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color = const Color(0xFF4CAF50), // Green color
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    int? attendeesCount,
    EventStatus? status,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    List<int>? notificationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    Color? color,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      notificationDays: notificationDays ?? this.notificationDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    dateTime,
    location,
    attendeesCount,
    status,
    isRecurring,
    recurringFrequency,
    recurringEndDate,
    notificationDays,
    createdAt,
    updatedAt,
    color,
  ];
}
