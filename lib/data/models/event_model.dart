// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/event.dart';

part 'event_model.g.dart';

@HiveType(typeId: 2)
class EventModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final String? location;

  @HiveField(5)
  final int? attendeesCount;

  @HiveField(6)
  final int status; // 0 = upcoming, 1 = completed, 2 = cancelled

  @HiveField(7)
  final bool isRecurring;

  @HiveField(8)
  final String? recurringFrequency;

  @HiveField(9)
  final DateTime? recurringEndDate;

  @HiveField(10)
  final List<int> notificationDays;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final int color; // Color value as int

  @HiveField(14)
  final String userId;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dateTime,
    this.location,
    this.attendeesCount,
    required this.status,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringEndDate,
    this.notificationDays = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color = 0xFF4CAF50, // Green color default
  });

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      userId: event.userId,
      title: event.title,
      description: event.description,
      dateTime: event.dateTime,
      location: event.location,
      attendeesCount: event.attendeesCount,
      status: event.status == EventStatus.upcoming
          ? 0
          : event.status == EventStatus.completed
          ? 1
          : 2,
      isRecurring: event.isRecurring,
      recurringFrequency: event.recurringFrequency,
      recurringEndDate: event.recurringEndDate,
      notificationDays: event.notificationDays,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      color: event.color.value,
    );
  }

  Event toEntity() {
    return Event(
      id: id,
      userId: userId,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      attendeesCount: attendeesCount,
      status: status == 0
          ? EventStatus.upcoming
          : status == 1
          ? EventStatus.completed
          : EventStatus.cancelled,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      recurringEndDate: recurringEndDate,
      notificationDays: notificationDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
      color: Color(color),
    );
  }

  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    int? attendeesCount,
    int? status,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    List<int>? notificationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? color,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
}
