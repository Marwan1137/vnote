import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/currencies.dart';
import '../../core/constants/payment_categories.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/processed_payment.dart';
import '../datasources_contracts/payment_llm_datasource.dart';

@LazySingleton(as: PaymentLLMDataSource)
class PaymentLLMDataSourceImpl implements PaymentLLMDataSource {
  late final GenerativeModel _model;
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.5-pro',
  ];

  PaymentLLMDataSourceImpl() {
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
  Future<List<ProcessedPayment>> processPaymentTranscription(
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
      throw LLMProcessingException('Failed to process payment: $e');
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

    return '''
You are an intelligent payment processing assistant. Analyze the following voice transcription and extract payment information.

${'=' * 80}
ABSOLUTE LANGUAGE REQUIREMENT:
$languageInstruction
${'=' * 80}

CRITICAL: You MUST respond with ONLY valid JSON. Do NOT include markdown code blocks, explanations, or any other text.

Transcription to analyze:
$transcription

Extract the following information from the transcription:

1. **title**: Payment description (e.g., "Electric Bill", "Landline Bill", "Rent Payment")
   - Extract the main payment description
   - MUST be in the same language as the transcription

2. **amount**: Numeric value only (e.g., 100, 125.50, 2000)
   - Extract the numeric amount mentioned
   - If no amount is mentioned, use 0.0

3. **currency**: Currency code (USD, EUR, EGP, etc.)
   - Detect from keywords: "dollars" → USD, "جنيه" → EGP, "euro" → EUR, etc.
   - Default to USD if not detected

4. **type**: Either "toPay" or "toReceive"
   - "toPay": If user says "I will pay", "I need to pay", "pay", "due", etc.
   - "toReceive": If user says "I will receive", "I will get", "income", etc.
   - Default to "toPay" if unclear

5. **dueDate**: Date in ISO format (YYYY-MM-DD)
   - Extract date from phrases like:
     - "on December 3rd" → 2025-12-03 (use current year if year not mentioned)
     - "on the 3rd" → 2025-12-03 (use current month if month not mentioned)
     - "each month on the 3rd" → next occurrence of 3rd
     - "tomorrow" → tomorrow's date
     - "next week" → date 7 days from now
   - If no date mentioned, use today's date

6. **category**: One of: ${PaymentCategories.categories.join(', ')}
   - Auto-detect from context:
     - "bill", "electric", "water", "internet" → Utilities
     - "rent", "mortgage", "housing" → Housing
     - "salary", "income", "payment received" → Income
     - "food", "groceries", "restaurant" → Food
     - "car", "gas", "transport" → Transportation
     - "doctor", "medical", "health" → Healthcare
     - "movie", "entertainment" → Entertainment
     - "shopping", "store" → Shopping
     - "school", "education", "tuition" → Education
     - Default to "Other" if unclear
   - MUST be one of the predefined categories

7. **isRecurring**: Boolean (true/false)
   - true if user says: "each month", "monthly", "every month", "recurring", "repeat"
   - false otherwise

8. **recurringFrequency**: String or null
   - "monthly" if recurring and monthly
   - "weekly" if recurring and weekly
   - "yearly" if recurring and yearly
   - null if not recurring

9. **notificationDays**: Array of integers
   - Extract notification preferences:
     - "same day" or "on the day" → [0]
     - "1 day before" or "day before" → [1]
     - "1 week before" or "week before" → [7]
     - "notify me before it by a day" → [1]
     - Multiple can be specified: [0, 1, 7]
     - Default to [] if not mentioned

IMPORTANT: The transcription may contain MULTIPLE payments. If you detect multiple payments, extract ALL of them.

Respond with this EXACT JSON structure:
- If ONE payment: A single JSON object
- If MULTIPLE payments: A JSON array of objects

Single payment structure:
{
  "title": "Payment title here",
  "amount": 100.0,
  "currency": "USD",
  "dueDate": "2025-12-03",
  "category": "Utilities",
  "type": "toPay",
  "isRecurring": false,
  "recurringFrequency": null,
  "notificationDays": [1]
}

Multiple payments structure (array):
[
  {
    "title": "Payment 1 title",
    "amount": 100.0,
    "currency": "USD",
    "dueDate": "2025-12-03",
    "category": "Utilities",
    "type": "toPay",
    "isRecurring": true,
    "recurringFrequency": "monthly",
    "notificationDays": [1]
  },
  {
    "title": "Payment 2 title",
    "amount": 200.0,
    "currency": "USD",
    "dueDate": "2025-12-05",
    "category": "Food",
    "type": "toPay",
    "isRecurring": true,
    "recurringFrequency": "monthly",
    "notificationDays": []
  }
]

ABSOLUTE REQUIREMENTS:
1. Start your response with { or [ and end with } or ] - no markdown, no code blocks
2. Ensure the JSON is valid and parseable
3. ALL fields MUST be in the EXACT SAME LANGUAGE as the transcription (except currency code and category which are in English)
4. Use current date context for relative dates (today, tomorrow, next week)
5. If multiple payments are mentioned, extract ALL of them into an array

Example single payment:
{"title":"Electric Bill","amount":125.0,"currency":"USD","dueDate":"2025-12-03","category":"Utilities","type":"toPay","isRecurring":true,"recurringFrequency":"monthly","notificationDays":[1]}

Example multiple payments:
[{"title":"Salary","amount":15000.0,"currency":"USD","dueDate":"2026-01-01","category":"Income","type":"toReceive","isRecurring":true,"recurringFrequency":"monthly","notificationDays":[]},{"title":"Landline Bill","amount":100.0,"currency":"USD","dueDate":"2026-01-03","category":"Utilities","type":"toPay","isRecurring":true,"recurringFrequency":"monthly","notificationDays":[]},{"title":"Groceries","amount":3000.0,"currency":"USD","dueDate":"2026-01-05","category":"Food","type":"toPay","isRecurring":true,"recurringFrequency":"monthly","notificationDays":[]}]
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

  List<ProcessedPayment> _parseResponse(
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
                  (json) => _parseSinglePayment(
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
          return [_parseSinglePayment(json, originalTranscription)];
        }
      }

      throw const FormatException('No JSON found in response');
    } catch (e) {
      throw LLMProcessingException('Failed to parse payment response: $e');
    }
  }

  ProcessedPayment _parseSinglePayment(
    Map<String, dynamic> json,
    String originalTranscription,
  ) {
    try {
      final title = json['title'] as String? ?? 'Payment';
      final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
      final currencyCode =
          json['currency'] as String? ??
          Currencies.detectCurrency(originalTranscription) ??
          'USD';
      final dueDateString = json['dueDate'] as String?;
      final category = json['category'] as String? ?? 'Other';
      final typeString = json['type'] as String? ?? 'toPay';
      final isRecurring = json['isRecurring'] as bool? ?? false;
      final recurringFrequency = json['recurringFrequency'] as String?;
      final notificationDaysList = json['notificationDays'] as List<dynamic>?;

      DateTime dueDate;
      if (dueDateString != null) {
        try {
          final parsedDate = DateTime.parse(dueDateString);
          // If it's recurring and the parsed date is in the past, calculate next occurrence
          if (isRecurring && parsedDate.isBefore(DateTime.now())) {
            dueDate = _calculateNextRecurringDate(parsedDate);
          } else {
            dueDate = parsedDate;
          }
        } catch (e) {
          dueDate = _extractDateFromTranscription(originalTranscription);
        }
      } else {
        dueDate = _extractDateFromTranscription(originalTranscription);
      }

      // Final check: if recurring and date is still in the past, calculate next occurrence
      if (isRecurring && dueDate.isBefore(DateTime.now())) {
        dueDate = _calculateNextRecurringDate(dueDate);
      }

      final type = typeString == 'toReceive'
          ? PaymentType.toReceive
          : PaymentType.toPay;

      final notificationDays =
          notificationDaysList
              ?.map((e) => (e as num).toInt())
              .where((e) => e >= 0)
              .toList() ??
          [];

      return ProcessedPayment(
        title: title,
        amount: amount,
        currency: currencyCode,
        dueDate: dueDate,
        category: category,
        type: type,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        notificationDays: notificationDays,
      );
    } catch (e) {
      throw LLMProcessingException('Failed to parse single payment: $e');
    }
  }

  DateTime _extractDateFromTranscription(String transcription) {
    final now = DateTime.now();
    final lowerText = transcription.toLowerCase();

    if (lowerText.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    if (lowerText.contains('next week')) {
      return now.add(const Duration(days: 7));
    }

    // Check for recurring payment patterns (e.g., "3rd of each month", "every month on the 3rd")
    final isRecurring =
        lowerText.contains('each month') ||
        lowerText.contains('every month') ||
        lowerText.contains('monthly');

    final dayMatch = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\b',
    ).firstMatch(lowerText);
    if (dayMatch != null) {
      final day = int.tryParse(dayMatch.group(1) ?? '');
      if (day != null && day >= 1 && day <= 31) {
        try {
          var date = DateTime(now.year, now.month, day);

          // If it's a recurring payment and the date is in the past, set to next month
          if (isRecurring && date.isBefore(now)) {
            if (now.month == 12) {
              date = DateTime(now.year + 1, 1, day);
            } else {
              date = DateTime(now.year, now.month + 1, day);
            }
          }
          // If it's not recurring and the date is in the past, set to next occurrence this month or next month
          else if (!isRecurring && date.isBefore(now)) {
            if (now.month == 12) {
              date = DateTime(now.year + 1, 1, day);
            } else {
              date = DateTime(now.year, now.month + 1, day);
            }
          }

          return date;
        } catch (e) {
          // If day is invalid for the month (e.g., Feb 31), use last day of month
          try {
            final lastDay = DateTime(now.year, now.month + 1, 0).day;
            final validDay = day > lastDay ? lastDay : day;
            var date = DateTime(now.year, now.month, validDay);

            if (isRecurring && date.isBefore(now)) {
              if (now.month == 12) {
                date = DateTime(now.year + 1, 1, validDay);
              } else {
                date = DateTime(now.year, now.month + 1, validDay);
              }
            }

            return date;
          } catch (e2) {
            return now;
          }
        }
      }
    }

    return now;
  }

  DateTime _calculateNextRecurringDate(DateTime originalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final originalDay = originalDate.day;

    // Try current month first
    try {
      var nextDate = DateTime(now.year, now.month, originalDay);
      if (nextDate.isBefore(today) || nextDate.isAtSameMomentAs(today)) {
        // If it's today or in the past, move to next month
        if (now.month == 12) {
          nextDate = DateTime(now.year + 1, 1, originalDay);
        } else {
          nextDate = DateTime(now.year, now.month + 1, originalDay);
        }
      }
      return nextDate;
    } catch (e) {
      // If day is invalid for the month (e.g., Feb 31), use last day of next month
      try {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final validDay = originalDay > lastDay ? lastDay : originalDay;
        return DateTime(nextYear, nextMonth, validDay);
      } catch (e2) {
        return now;
      }
    }
  }

  Future<List<ProcessedPayment>> _tryWithFallbackModels(
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
