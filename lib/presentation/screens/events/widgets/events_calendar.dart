// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/domain/entities/event.dart' as event_entity;

class EventsCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<event_entity.Event> events;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay) onPageChanged;

  const EventsCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  List<event_entity.Event> _getEventsForDay(DateTime day) {
    return events.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.calendar_today, color: AppColors.green),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar<event_entity.Event>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 6,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.green,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.green,
                ),
              ),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
