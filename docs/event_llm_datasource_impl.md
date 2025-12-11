# Event LLM Data Source Implementation

## File Overview

**File Path:** `lib/data/datasource_impl/event_llm_datasource_impl.dart`

**Purpose:** This file implements the `EventLLMDataSource` interface, providing integration with Google's Gemini AI API to process voice transcriptions and extract structured event information. It takes raw transcription text and uses AI to extract:
- **Title:** Event name/description (e.g., "Team Sync Meeting", "Flight to Tokyo")
- **DateTime:** Full date and time in ISO format (YYYY-MM-DDTHH:mm:ss)
- **Location:** Event location (optional)
- **Attendees Count:** Number of attendees (optional)
- **Recurring Information:** Whether it's recurring and frequency (daily, weekly, monthly, yearly)
- **Notification Preferences:** When to notify user before event

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It handles complex event extraction from natural language, including sophisticated datetime parsing (with time), recurring event calculations, location extraction, and multi-event detection.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - RecordingCubit                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)           │
│   - ProcessEventTranscriptionUseCase │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - EventsRepositoryImpl             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - EventLLMDataSourceImpl           │ ← This file
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   External Service                   │
│   - Google Gemini API                │
└─────────────────────────────────────┘
```

## Dependencies

### External Packages
- **`google_generative_ai`** (`^0.4.0`): Google's Gemini AI SDK.

### Internal Dependencies
- **`AppConfig`**: Contains Gemini API key and model configuration.
- **`EventLLMDataSource`**: Abstract interface this class implements.
- **`ProcessedEvent`**: Domain entity representing structured event data.
- **`LLMProcessingException`**: Custom exception for LLM processing errors.

## Key Features

### 1. Multi-Event Extraction
Similar to payments, can extract **multiple events** from a single transcription:
- "I have a team meeting tomorrow at 3 pm, and a flight to Tokyo on December 15th at 8:30 AM"
- Returns an array of two `ProcessedEvent` objects.

### 2. DateTime Parsing (with Time)
More complex than payments because it includes **time**:
- Relative: "tomorrow at 3 pm", "next Monday at 10 am"
- Absolute: "December 3rd at 2:00 PM", "on the 15th at 8:30 AM"
- Default time: If no time mentioned, defaults to 12:00:00 (noon)
- 24-hour format: Converts to 24-hour format for storage

### 3. Recurring Event Logic
- Detects recurring events from keywords
- Calculates next occurrence with time preserved
- Handles different frequencies: daily, weekly, monthly, yearly
- Preserves time when calculating next occurrence

### 4. Location and Attendees
- Extracts location description (can be detailed: "room 9c at the 3rd floor")
- Extracts number of attendees if mentioned
- Both are optional fields

## Detailed Code Walkthrough

### Class Structure

```dart
@LazySingleton(as: EventLLMDataSource)
class EventLLMDataSourceImpl implements EventLLMDataSource {
  late final GenerativeModel _model;
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.5-pro',
  ];
```

**Same Pattern:** Uses fallback models for resilience, similar to other LLM datasources.

### Process Event Transcription

```dart
@override
Future<List<ProcessedEvent>> processEventTranscription(
  String transcription,
) async {
  try {
    final prompt = _buildPrompt(transcription);
    // ... API call with timeout and fallback
    final parsed = _parseResponse(generatedText, transcription);
    return parsed;
  } catch (e) {
    // Error handling...
  }
}
```

**Returns List:** Supports multi-event extraction, similar to payments.

### Prompt Engineering

The prompt is specifically designed for event extraction with datetime context:

```dart
String _buildPrompt(String transcription) {
  final detectedLanguage = _detectLanguage(transcription);
  final now = DateTime.now();
  final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final currentDateTime = now.toIso8601String();
  
  return '''
You are an intelligent event processing assistant...

${'=' * 80}
CRITICAL DATE CONTEXT:
Today's date is: $currentDate
Current date and time is: $currentDateTime
You MUST use this as your reference for ALL relative dates...
${'=' * 80}

Extract the following information:
1. **title**: Event name/description
2. **dateTime**: Full date and time in ISO format (YYYY-MM-DDTHH:mm:ss)
3. **location**: Full location string (optional)
4. **attendeesCount**: Number of attendees (optional)
5. **isRecurring**: Boolean (true/false)
6. **recurringFrequency**: "daily", "weekly", "monthly", "yearly", or null
7. **notificationDays**: Array of integers

IMPORTANT: The transcription may contain MULTIPLE events...
''';
}
```

**Key Differences from Payment Prompt:**

1. **Date Context:**
   - Provides current date and time to AI.
   - Helps AI calculate relative dates correctly.
   - Critical for "tomorrow", "next week", etc.

2. **DateTime Format:**
   - Requires ISO format with time: `YYYY-MM-DDTHH:mm:ss`
   - More specific than payment dates (which only need date).

3. **Location and Attendees:**
   - Extracts optional location description.
   - Extracts optional attendee count.

**Why Provide Current Date?**
- **Relative Dates:** AI needs context to calculate "tomorrow", "next week".
- **Accuracy:** Without context, AI might use wrong reference date.
- **Consistency:** Ensures all relative dates use same reference point.

### Response Parsing

Similar to payments, handles both single event and multiple events:

```dart
List<ProcessedEvent> _parseResponse(
  String response,
  String originalTranscription,
) {
  try {
    // Clean response and find JSON structure
    // ... bracket matching logic (same as payments)
    
    // Parse as array or single object
    if (jsonArray) {
      return jsonArray.map((json) => _parseSingleEvent(json, ...)).toList();
    } else {
      return [_parseSingleEvent(json, ...)];
    }
  } catch (e) {
    throw LLMProcessingException('Failed to parse event response: $e');
  }
}
```

**Same Pattern:** Uses bracket matching to extract JSON, handles both array and object responses.

### Single Event Parsing

```dart
ProcessedEvent _parseSingleEvent(
  Map<String, dynamic> json,
  String originalTranscription,
) {
  try {
    final title = json['title'] as String? ?? 'Event';
    final dateTimeString = json['dateTime'] as String?;
    final location = json['location'] as String?;
    final attendeesCount = json['attendeesCount'] as int?;
    final isRecurring = json['isRecurring'] as bool? ?? false;
    final recurringFrequency = json['recurringFrequency'] as String?;
    final notificationDaysList = json['notificationDays'] as List<dynamic>?;
    
    DateTime dateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (dateTimeString != null && dateTimeString.isNotEmpty) {
      try {
        final parsedDateTime = DateTime.parse(dateTimeString);
        final parsedDateOnly = DateTime(
          parsedDateTime.year,
          parsedDateTime.month,
          parsedDateTime.day,
        );
        
        // Check if parsed date is in the past
        if (parsedDateOnly.isBefore(today)) {
          // Use fallback extraction
          dateTime = _extractDateTimeFromTranscription(originalTranscription);
        } else {
          dateTime = parsedDateTime;
          
          // Handle recurring events in the past
          if (isRecurring && dateTime.isBefore(now)) {
            dateTime = _calculateNextRecurringDateTime(
              dateTime,
              recurringFrequency,
            );
          }
        }
      } catch (e) {
        // Parsing failed, use fallback
        dateTime = _extractDateTimeFromTranscription(originalTranscription);
      }
    } else {
      // No dateTime from AI, extract from transcription
      dateTime = _extractDateTimeFromTranscription(originalTranscription);
    }
    
    // Final validation: ensure dateTime is not in the past
    // ... validation logic
    
    final notificationDays = notificationDaysList
        ?.map((e) => (e as num).toInt())
        .where((e) => e >= 0)
        .toList() ?? [];
    
    return ProcessedEvent(
      title: title,
      dateTime: dateTime,
      location: location,
      attendeesCount: attendeesCount,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      notificationDays: notificationDays,
    );
  } catch (e) {
    throw LLMProcessingException('Failed to parse single event: $e');
  }
}
```

**Key Parsing Logic:**

1. **Title:** Defaults to 'Event' if missing.
2. **DateTime:** Complex parsing with multiple fallbacks (see DateTime Parsing section).
3. **Location:** Optional, can be null.
4. **Attendees Count:** Optional, can be null.
5. **Recurring:** Handles frequency and next occurrence calculation.
6. **Notification Days:** Parses and validates.

**Past Date Handling:**
- If AI returns date in past, uses fallback extraction.
- For recurring events, calculates next occurrence.
- Final validation ensures dateTime is not in past (unless it's today with future time).

### DateTime Parsing Logic

This is the most complex part, handling both date and time:

#### Extract DateTime from Transcription

```dart
DateTime _extractDateTimeFromTranscription(String transcription) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final lowerText = transcription.toLowerCase();
  
  // Extract time first
  int hour = 12; // Default to noon
  int minute = 0;
  
  // Match time patterns
  final timePatterns = [
    RegExp(r'at\s+(\d{1,2}):(\d{2})\s*(?:am|pm)?', caseSensitive: false),
    RegExp(r'at\s+(\d{1,2})\s*(?:am|pm)', caseSensitive: false),
    RegExp(r'(\d{1,2}):(\d{2})\s*(?:am|pm)?', caseSensitive: false),
    RegExp(r'(\d{1,2})\s*(?:am|pm)', caseSensitive: false),
  ];
  
  for (final pattern in timePatterns) {
    final match = pattern.firstMatch(lowerText);
    if (match != null) {
      final hourStr = match.group(1);
      final minuteStr = match.group(2);
      final isPm = lowerText.contains('pm') || lowerText.contains('p.m.');
      final isAm = lowerText.contains('am') || lowerText.contains('a.m.');
      
      if (hourStr != null) {
        hour = int.tryParse(hourStr) ?? 12;
        // Convert to 24-hour format
        if (isPm && hour != 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        }
        if (minuteStr != null) {
          minute = int.tryParse(minuteStr) ?? 0;
        }
      }
      break;
    }
  }
  
  // Extract date (similar to payment parsing but with time)
  DateTime date;
  if (lowerText.contains('tomorrow')) {
    date = today.add(const Duration(days: 1));
  } else if (lowerText.contains('next week')) {
    date = today.add(const Duration(days: 7));
  } else if (lowerText.contains('today')) {
    date = today;
  } else {
    // Extract day of month
    // ... similar to payment parsing
  }
  
  return DateTime(date.year, date.month, date.day, hour, minute);
}
```

**Time Extraction Strategy:**

1. **Multiple Patterns:**
   - "at 3 pm", "at 3:00 PM", "3 pm", "15:00"
   - Tries patterns in order, uses first match.

2. **AM/PM Conversion:**
   - Detects "am" or "pm" in text.
   - Converts to 24-hour format:
     - "3 pm" → 15:00
     - "12 am" → 00:00
     - "12 pm" → 12:00

3. **Default Time:**
   - If no time found, defaults to 12:00:00 (noon).
   - Reasonable default for events.

4. **Minute Handling:**
   - Extracts minutes if present ("3:30 pm" → 15:30).
   - Defaults to 0 if not specified.

**Date Extraction:**
- Similar to payment parsing but combines with extracted time.
- Handles relative dates, absolute dates, recurring patterns.
- Returns `DateTime` with both date and time.

**Why Extract Time First?**
- Time patterns are more specific than date patterns.
- Once time is extracted, we know it's an event (not just a date).
- Combines date and time at the end.

#### Calculate Next Recurring DateTime

```dart
DateTime _calculateNextRecurringDateTime(
  DateTime originalDateTime,
  String? frequency,
) {
  final now = DateTime.now();
  final originalDay = originalDateTime.day;
  final originalHour = originalDateTime.hour;
  final originalMinute = originalDateTime.minute;
  
  if (frequency == 'daily') {
    var nextDate = DateTime(
      now.year,
      now.month,
      now.day,
      originalHour,
      originalMinute,
    );
    if (nextDate.isBefore(now)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    return nextDate;
  } else if (frequency == 'weekly') {
    // Find next occurrence of the same weekday
    final daysUntilNext = (originalDateTime.weekday - now.weekday + 7) % 7;
    var nextDate = now.add(
      Duration(days: daysUntilNext == 0 ? 7 : daysUntilNext),
    );
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      originalHour,
      originalMinute,
    );
  } else if (frequency == 'monthly') {
    // Similar to payment logic but preserves time
    // ...
  } else if (frequency == 'yearly') {
    // ...
  }
  
  // Default: monthly
  // ...
}
```

**Recurring DateTime Logic:**

1. **Preserves Time:**
   - Keeps original hour and minute.
   - Only changes the date.

2. **Daily:**
   - If time today has passed, move to tomorrow.
   - Otherwise, use today.

3. **Weekly:**
   - Finds next occurrence of same weekday.
   - Calculates days until next occurrence.
   - Preserves time.

4. **Monthly:**
   - Similar to payment logic.
   - Preserves time when moving to next month.

5. **Yearly:**
   - Finds next occurrence in next year.
   - Preserves month, day, and time.

**Why Preserve Time?**
- **User Intent:** "Meeting every Monday at 3 pm" means same time each week.
- **Consistency:** Recurring events should have consistent time.
- **User Experience:** Users expect time to be preserved.

### Final DateTime Validation

```dart
// Final check: if recurring and date is still in the past, calculate next occurrence
if (isRecurring && dateTime.isBefore(now)) {
  dateTime = _calculateNextRecurringDateTime(dateTime, recurringFrequency);
}

// Final validation: ensure dateTime is not in the past (unless it's today)
final eventDateOnly = DateTime(
  dateTime.year,
  dateTime.month,
  dateTime.day,
);
if (eventDateOnly.isBefore(today)) {
  // Date is in the past, use today with the extracted time
  dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    dateTime.hour,
    dateTime.minute,
  );
} else if (eventDateOnly.isAtSameMomentAs(today) && dateTime.isBefore(now)) {
  // Same day but time has passed
  final timeDiff = now.difference(dateTime);
  if (timeDiff.inHours >= 1) {
    // If it's more than 1 hour ago, move to tomorrow
    dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      dateTime.hour,
      dateTime.minute,
    ).add(const Duration(days: 1));
  }
}
```

**Validation Logic:**

1. **Recurring Check:**
   - If recurring and in past, calculate next occurrence.
   - Ensures recurring events are always in future.

2. **Past Date Check:**
   - If date is in past (different day), use today with extracted time.
   - Prevents events in the past.

3. **Same Day, Past Time:**
   - If same day but time has passed:
     - If > 1 hour ago: move to tomorrow.
     - If < 1 hour ago: keep today (might be running late).

**Why This Logic?**
- **User Experience:** Events should be in the future.
- **Edge Cases:** Handles "today at 2 pm" when it's already 3 pm.
- **Flexibility:** Allows events within 1 hour (user might be running late).

### Location and Attendees

```dart
final location = json['location'] as String?;
final attendeesCount = json['attendeesCount'] as int?;
```

**Optional Fields:**
- **Location:** Can be detailed ("room 9c at the 3rd floor in the company").
- **Attendees Count:** Extracted if mentioned ("5 people", "10 attendees").
- **Null Handling:** Both can be null if not mentioned.

**Why Optional?**
- Not all events have location or attendees.
- User might not mention them.
- Better to have null than incorrect data.

## Multi-Event Handling

Similar to payments, handles multiple events in one transcription:

- "I have a team meeting tomorrow at 3 pm, and a flight to Tokyo on December 15th at 8:30 AM"
- Returns array of `ProcessedEvent` objects.

**Same Bracket Matching:** Uses same logic as payments to extract array or single object.

## Error Handling

### Exception Types

- **`LLMProcessingException`:** All LLM-related errors.
- **`FormatException`:** JSON parsing errors.

### Error Scenarios

1. **Invalid DateTime:**
   - **Detection:** `DateTime.parse()` fails.
   - **Handling:** Falls back to transcription extraction.

2. **Past DateTime:**
   - **Detection:** DateTime is before now.
   - **Handling:** Adjusts to future date (today or tomorrow).

3. **Invalid Recurring Frequency:**
   - **Detection:** Frequency not recognized.
   - **Handling:** Defaults to monthly.

4. **All Models Fail:**
   - **Detection:** All fallback models fail.
   - **Handling:** Throws exception with helpful message.

## Testing Considerations

### What Should Be Tested

1. **Single Event Extraction:**
   - Valid transcription produces one event.
   - All fields populated correctly.

2. **Multi-Event Extraction:**
   - Transcription with multiple events returns array.
   - Each event parsed correctly.

3. **DateTime Parsing:**
   - Relative dates with time ("tomorrow at 3 pm").
   - Absolute dates with time ("December 3rd at 2:00 PM").
   - Default time when not specified.
   - AM/PM conversion.

4. **Recurring Logic:**
   - Daily, weekly, monthly, yearly frequencies.
   - Time preservation.
   - Next occurrence calculation.

5. **Past DateTime Handling:**
   - Past dates adjusted to future.
   - Same day, past time handled correctly.
   - Recurring events in past calculated.

6. **Edge Cases:**
   - Empty transcription.
   - Invalid dates/times.
   - Missing fields.
   - Location and attendees optional.

## Future Improvements

1. **Better DateTime Parsing:**
   - Use NLP library for datetime parsing.
   - Handle more time formats.
   - Support timezone awareness.

2. **Location Enhancement:**
   - Geocode locations to coordinates.
   - Validate locations.
   - Suggest nearby locations.

3. **Attendees Enhancement:**
   - Extract attendee names if mentioned.
   - Link to contacts.
   - Send invitations.

4. **Recurring Patterns:**
   - Support complex patterns (every 2 weeks, first Monday of month).
   - Handle exceptions (skip certain dates).
   - End date for recurring events.

5. **Validation:**
   - Validate dates (not too far in future/past).
   - Validate times (reasonable hours).
   - Validate locations (if geocoded).

## Summary

The `EventLLMDataSourceImpl` provides robust event extraction:

- **Multi-Event Support:** Extracts multiple events from one transcription.
- **DateTime Parsing:** Handles date and time with various formats.
- **Recurring Logic:** Calculates next occurrence preserving time.
- **Location & Attendees:** Extracts optional location and attendee count.
- **Past DateTime Handling:** Ensures events are always in the future.
- **Error Resilience:** Multiple fallbacks ensure reliability.

This implementation ensures reliable event extraction while handling the complexity of natural language datetime expressions, recurring event calculations, and time preservation.
