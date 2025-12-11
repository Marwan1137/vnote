import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/processed_event.dart';
import '../datasources_contracts/event_llm_datasource.dart';

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

  EventLLMDataSourceImpl() {
    try {
      _model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProcessedEvent>> processEventTranscription(
    String transcription,
  ) async {
    try {
      final prompt = _buildPrompt(transcription);

      final generationConfig = GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
      );

      GenerateContentResponse response;
      try {
        response = await _model
            .generateContent([
              Content.text(prompt),
            ], generationConfig: generationConfig)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw LLMProcessingException('Request timeout');
              },
            );
      } on GenerativeAIException catch (e) {
        if (e.message.contains('not found') ||
            e.message.contains('not supported') ||
            e.message.contains('quota') ||
            e.message.contains('Quota exceeded')) {
          return _tryWithFallbackModels(
            prompt,
            transcription,
            generationConfig,
          );
        }
        rethrow;
      }

      final generatedText = response.text ?? '';

      if (generatedText.isEmpty) {
        throw LLMProcessingException('Gemini API returned empty response');
      }

      final parsed = _parseResponse(generatedText, transcription);
      return parsed;
    } on GenerativeAIException catch (e) {
      throw LLMProcessingException('Gemini API error: ${e.message}');
    } catch (e) {
      if (e is LLMProcessingException) {
        rethrow;
      }
      throw LLMProcessingException('Failed to process event: $e');
    }
  }

  String _buildPrompt(String transcription) {
    final detectedLanguage = _detectLanguage(transcription);
    final languageInstruction = detectedLanguage == 'en'
        ? 'The transcription is in ENGLISH. You MUST respond in ENGLISH for ALL fields.'
        : detectedLanguage == 'ar'
        ? 'The transcription is in ARABIC. You MUST respond in ARABIC for ALL fields.'
        : detectedLanguage == 'de'
        ? 'The transcription is in GERMAN. You MUST respond in GERMAN for ALL fields.'
        : 'The transcription appears to be in ${detectedLanguage.toUpperCase()}. You MUST respond in the EXACT SAME LANGUAGE as the transcription.';

    final now = DateTime.now();
    final currentDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentDateTime = now.toIso8601String();

    return '''
You are an intelligent event processing assistant. Analyze the following voice transcription and extract event information.

${'=' * 80}
ABSOLUTE LANGUAGE REQUIREMENT:
$languageInstruction
${'=' * 80}

${'=' * 80}
CRITICAL DATE CONTEXT:
Today's date is: $currentDate
Current date and time is: $currentDateTime
You MUST use this as your reference for ALL relative dates (tomorrow, next week, etc.)
${'=' * 80}

CRITICAL: You MUST respond with ONLY valid JSON. Do NOT include markdown code blocks, explanations, or any other text.

Transcription to analyze:
$transcription

Extract the following information from the transcription:

1. **title**: Event name/description (e.g., "Team Sync Meeting", "Flight to Tokyo", "Product Launch")
   - Extract the main event description
   - MUST be in the same language as the transcription

2. **dateTime**: Full date and time in ISO format (YYYY-MM-DDTHH:mm:ss)
   - CRITICAL: You MUST use the CURRENT DATE as reference. Today is ${DateTime.now().toIso8601String().split('T')[0]}
   - Extract date and time from phrases like:
     - "tomorrow at 3 pm" → (today + 1 day) at 15:00:00
     - "Dec 3 at 2:00 PM" → Use CURRENT YEAR if year not mentioned, use CURRENT MONTH if month not mentioned
     - "next Monday at 10 am" → next Monday from today at 10:00:00
     - "on the 15th at 8:30 AM" → CURRENT month/year 15th at 08:30:00 (if day has passed, use next month)
   - If a day number is mentioned and it's already passed this month, use NEXT MONTH
   - If no time mentioned, default to 12:00:00 (noon)
   - If no date mentioned, use today's date
   - Use 24-hour format for time
   - NEVER return a date in the past unless explicitly stated

3. **location**: Full location string (optional)
   - Extract complete location description (e.g., "room 9c at the 3rd floor in the company", "LAX Airport", "Virtual Event")
   - Include all location details mentioned
   - Return null if no location mentioned

4. **attendeesCount**: Number of attendees (optional)
   - Extract number if mentioned (e.g., "5 people", "10 attendees", "50 people")
   - Return null if not mentioned

5. **isRecurring**: Boolean (true/false)
   - true if user says: "every Monday", "each week", "monthly", "every month", "recurring", "repeat"
   - false otherwise

6. **recurringFrequency**: String or null
   - "daily" if recurring and daily
   - "weekly" if recurring and weekly
   - "monthly" if recurring and monthly
   - "yearly" if recurring and yearly
   - null if not recurring

7. **notificationDays**: Array of integers
   - Extract notification preferences:
     - "same day" or "on the day" → [0]
     - "1 day before" or "day before" → [1]
     - "1 week before" or "week before" → [7]
     - "notify me before it by a day" → [1]
     - Multiple can be specified: [0, 1, 7]
     - Default to [] if not mentioned

IMPORTANT: The transcription may contain MULTIPLE events. If you detect multiple events, extract ALL of them.

Respond with this EXACT JSON structure:
- If ONE event: A single JSON object
- If MULTIPLE events: A JSON array of objects

Single event structure:
{
  "title": "Event title here",
  "dateTime": "2025-12-03T15:00:00",
  "location": "room 9c at the 3rd floor in the company",
  "attendeesCount": 5,
  "isRecurring": false,
  "recurringFrequency": null,
  "notificationDays": [1]
}

Multiple events structure (array):
[
  {
    "title": "Event 1 title",
    "dateTime": "2025-12-03T15:00:00",
    "location": "Location 1",
    "attendeesCount": 5,
    "isRecurring": false,
    "recurringFrequency": null,
    "notificationDays": [1]
  },
  {
    "title": "Event 2 title",
    "dateTime": "2025-12-15T08:30:00",
    "location": "Location 2",
    "attendeesCount": 10,
    "isRecurring": true,
    "recurringFrequency": "weekly",
    "notificationDays": []
  }
]

ABSOLUTE REQUIREMENTS:
1. Start your response with { or [ and end with } or ] - no markdown, no code blocks
2. Ensure the JSON is valid and parseable
3. ALL fields MUST be in the EXACT SAME LANGUAGE as the transcription (except dateTime which is in ISO format)
4. Use current date context for relative dates (today, tomorrow, next week)
5. If multiple events are mentioned, extract ALL of them into an array

Example single event:
{"title":"Team Meeting","dateTime":"2025-12-04T15:00:00","location":"room 9c at the 3rd floor in the company","attendeesCount":5,"isRecurring":false,"recurringFrequency":null,"notificationDays":[]}

Example multiple events:
[{"title":"Team Sync Meeting","dateTime":"2025-12-03T14:00:00","location":"Conference Room B","attendeesCount":5,"isRecurring":false,"recurringFrequency":null,"notificationDays":[]},{"title":"Flight to Tokyo","dateTime":"2025-12-15T08:30:00","location":"LAX Airport","attendeesCount":1,"isRecurring":false,"recurringFrequency":null,"notificationDays":[]}]
''';
  }

  String _detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    final arabicChars = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    final arabicMatches = arabicChars.allMatches(text).length;
    final totalChars = text
        .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
        .length;

    if (totalChars > 0 && (arabicMatches / totalChars) > 0.4) {
      return 'ar';
    }

    final germanPattern = RegExp(
      r'\b(der|die|das|und|oder|aber|in|auf|mit|von|zu|für|ist|sind|war|waren|ein|eine|einer|dies|dass|du|ich|wir|sie|er|sie|es|haben|hat|wird|kann|muss|soll)\b',
      caseSensitive: false,
    );
    final germanMatches = germanPattern.allMatches(text).length;

    if (germanMatches > 2) {
      return 'de';
    }

    final englishPattern = RegExp(
      r'\b(the|and|or|but|in|on|at|to|for|of|with|by|is|are|was|were|a|an|this|that|you|I|we|they|he|she|it)\b',
      caseSensitive: false,
    );
    final englishMatches = englishPattern.allMatches(text).length;

    if (englishMatches > 2) {
      return 'en';
    }

    return 'en';
  }

  List<ProcessedEvent> _parseResponse(
    String response,
    String originalTranscription,
  ) {
    try {
      String cleanedResponse = response.trim();
      cleanedResponse = cleanedResponse.replaceAll(
        RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```', multiLine: true),
        r'$1',
      );

      // Find the outermost JSON structure by finding the first { or [
      // and matching it with its closing bracket using bracket counting
      int? firstBrace = cleanedResponse.indexOf('{');
      int? firstBracket = cleanedResponse.indexOf('[');

      // Determine which comes first and is the outermost structure
      if (firstBracket != -1 &&
          (firstBrace == -1 || firstBracket < firstBrace)) {
        // Array comes first - find matching closing bracket
        int depth = 0;
        int start = firstBracket;
        int end = start;
        for (int i = start; i < cleanedResponse.length; i++) {
          if (cleanedResponse[i] == '[') depth++;
          if (cleanedResponse[i] == ']') {
            depth--;
            if (depth == 0) {
              end = i + 1;
              break;
            }
          }
        }
        if (end > start) {
          final jsonString = cleanedResponse.substring(start, end);
          try {
            final jsonArray = jsonDecode(jsonString) as List<dynamic>;
            if (jsonArray.isEmpty) {
              throw const FormatException('Empty array found');
            }
            return jsonArray
                .map(
                  (json) => _parseSingleEvent(
                    json as Map<String, dynamic>,
                    originalTranscription,
                  ),
                )
                .toList();
          } catch (e) {
            // Fall through to object parsing
          }
        }
      }

      if (firstBrace != -1) {
        // Object comes first or array parsing failed - find matching closing brace
        int depth = 0;
        int start = firstBrace;
        int end = start;
        for (int i = start; i < cleanedResponse.length; i++) {
          if (cleanedResponse[i] == '{') depth++;
          if (cleanedResponse[i] == '}') {
            depth--;
            if (depth == 0) {
              end = i + 1;
              break;
            }
          }
        }
        if (end > start) {
          final jsonString = cleanedResponse.substring(start, end);
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          return [_parseSingleEvent(json, originalTranscription)];
        }
      }

      throw const FormatException('No JSON found in response');
    } catch (e) {
      throw LLMProcessingException('Failed to parse event response: $e');
    }
  }

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
          // Parse the ISO dateTime string from LLM
          final parsedDateTime = DateTime.parse(dateTimeString);
          final parsedDateOnly = DateTime(
            parsedDateTime.year,
            parsedDateTime.month,
            parsedDateTime.day,
          );

          // Check if the parsed date is in the past
          if (parsedDateOnly.isBefore(today)) {
            // Date is in the past, use fallback extraction which handles current date context
            dateTime = _extractDateTimeFromTranscription(originalTranscription);
          } else {
            dateTime = parsedDateTime;

            // If it's recurring and the parsed date is in the past, calculate next occurrence
            if (isRecurring && dateTime.isBefore(now)) {
              dateTime = _calculateNextRecurringDateTime(
                dateTime,
                recurringFrequency,
              );
            }
          }
        } catch (e) {
          // Parsing failed, use fallback extraction
          dateTime = _extractDateTimeFromTranscription(originalTranscription);
        }
      } else {
        // No dateTime from LLM, extract from transcription
        dateTime = _extractDateTimeFromTranscription(originalTranscription);
      }

      // Final check: if recurring and date is still in the past, calculate next occurrence
      if (isRecurring && dateTime.isBefore(now)) {
        dateTime = _calculateNextRecurringDateTime(
          dateTime,
          recurringFrequency,
        );
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
      } else if (eventDateOnly.isAtSameMomentAs(today) &&
          dateTime.isBefore(now)) {
        // Same day but time has passed - if it's more than 1 hour ago, move to tomorrow
        final timeDiff = now.difference(dateTime);
        if (timeDiff.inHours >= 1) {
          dateTime = DateTime(
            now.year,
            now.month,
            now.day,
            dateTime.hour,
            dateTime.minute,
          ).add(const Duration(days: 1));
        }
      }

      final notificationDays =
          notificationDaysList
              ?.map((e) => (e as num).toInt())
              .where((e) => e >= 0)
              .toList() ??
          [];

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

  DateTime _extractDateTimeFromTranscription(String transcription) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lowerText = transcription.toLowerCase();

    // Extract time first
    int hour = 12; // Default to noon
    int minute = 0;

    // Match time patterns: "3 pm", "15:00", "3:00 PM", "at 3 pm", etc.
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

    // Extract date
    DateTime date;
    if (lowerText.contains('tomorrow')) {
      date = today.add(const Duration(days: 1));
    } else if (lowerText.contains('next week')) {
      date = today.add(const Duration(days: 7));
    } else if (lowerText.contains('today')) {
      date = today;
    } else {
      // Try to extract day of month
      final dayMatch = RegExp(
        r'\b(\d{1,2})(?:st|nd|rd|th)?\b',
      ).firstMatch(lowerText);
      if (dayMatch != null) {
        final day = int.tryParse(dayMatch.group(1) ?? '');
        if (day != null && day >= 1 && day <= 31) {
          try {
            // Try current month first
            var candidateDate = DateTime(now.year, now.month, day);
            final candidateDateOnly = DateTime(
              candidateDate.year,
              candidateDate.month,
              candidateDate.day,
            );

            // If the date (without time) is before today, move to next month
            if (candidateDateOnly.isBefore(today)) {
              if (now.month == 12) {
                candidateDate = DateTime(now.year + 1, 1, day);
              } else {
                candidateDate = DateTime(now.year, now.month + 1, day);
              }
            }

            // Combine with extracted time
            date = DateTime(
              candidateDate.year,
              candidateDate.month,
              candidateDate.day,
              hour,
              minute,
            );

            // Final check: if the full datetime is still in the past, adjust
            if (date.isBefore(now)) {
              // If it's the same day but time has passed, keep the date but this shouldn't happen
              // If it's a different day, we already handled it above
              // This is a safety check
              if (date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day) {
                // Same day but time passed - this is fine, it's today
                return date;
              }
            }

            return date;
          } catch (e) {
            // Invalid date for month (e.g., Feb 31), use last day of month
            try {
              final lastDay = DateTime(now.year, now.month + 1, 0).day;
              final validDay = day > lastDay ? lastDay : day;
              var candidateDate = DateTime(now.year, now.month, validDay);
              final candidateDateOnly = DateTime(
                candidateDate.year,
                candidateDate.month,
                candidateDate.day,
              );

              if (candidateDateOnly.isBefore(today)) {
                if (now.month == 12) {
                  candidateDate = DateTime(now.year + 1, 1, validDay);
                } else {
                  candidateDate = DateTime(now.year, now.month + 1, validDay);
                }
              }

              return DateTime(
                candidateDate.year,
                candidateDate.month,
                candidateDate.day,
                hour,
                minute,
              );
            } catch (e2) {
              // Fall through to default
            }
          }
        }
      }
      // Default to today if no date found
      date = today;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

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
      try {
        var nextDate = DateTime(
          now.year,
          now.month,
          originalDay,
          originalHour,
          originalMinute,
        );
        if (nextDate.isBefore(now)) {
          if (now.month == 12) {
            nextDate = DateTime(
              now.year + 1,
              1,
              originalDay,
              originalHour,
              originalMinute,
            );
          } else {
            nextDate = DateTime(
              now.year,
              now.month + 1,
              originalDay,
              originalHour,
              originalMinute,
            );
          }
        }
        return nextDate;
      } catch (e) {
        // Invalid day for month, use last day
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final validDay = originalDay > lastDay ? lastDay : originalDay;
        return DateTime(
          nextYear,
          nextMonth,
          validDay,
          originalHour,
          originalMinute,
        );
      }
    } else if (frequency == 'yearly') {
      var nextDate = DateTime(
        now.year,
        originalDateTime.month,
        originalDay,
        originalHour,
        originalMinute,
      );
      if (nextDate.isBefore(now)) {
        nextDate = DateTime(
          now.year + 1,
          originalDateTime.month,
          originalDay,
          originalHour,
          originalMinute,
        );
      }
      return nextDate;
    }

    // Default: monthly
    try {
      var nextDate = DateTime(
        now.year,
        now.month,
        originalDay,
        originalHour,
        originalMinute,
      );
      if (nextDate.isBefore(now)) {
        if (now.month == 12) {
          nextDate = DateTime(
            now.year + 1,
            1,
            originalDay,
            originalHour,
            originalMinute,
          );
        } else {
          nextDate = DateTime(
            now.year,
            now.month + 1,
            originalDay,
            originalHour,
            originalMinute,
          );
        }
      }
      return nextDate;
    } catch (e) {
      return now;
    }
  }

  Future<List<ProcessedEvent>> _tryWithFallbackModels(
    String prompt,
    String transcription,
    GenerationConfig generationConfig,
  ) async {
    for (final modelName in _fallbackModels) {
      if (modelName == AppConfig.geminiModel) {
        continue;
      }

      try {
        final fallbackModel = GenerativeModel(
          model: modelName,
          apiKey: AppConfig.geminiApiKey,
        );

        final response = await fallbackModel
            .generateContent([
              Content.text(prompt),
            ], generationConfig: generationConfig)
            .timeout(const Duration(seconds: 60));

        final generatedText = response.text ?? '';
        if (generatedText.isNotEmpty) {
          return _parseResponse(generatedText, transcription);
        }
      } catch (e) {
        continue;
      }
    }

    throw LLMProcessingException(
      'All Gemini models failed. Please check your API key quota.',
    );
  }
}
