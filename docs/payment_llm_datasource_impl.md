# Payment LLM Data Source Implementation

## File Overview

**File Path:** `lib/data/datasource_impl/payment_llm_datasource_impl.dart`

**Purpose:** This file implements the `PaymentLLMDataSource` interface, providing integration with Google's Gemini AI API to process voice transcriptions and extract structured payment information. It takes raw transcription text and uses AI to extract:
- **Title:** Payment description (e.g., "Electric Bill", "Rent Payment")
- **Amount:** Numeric payment amount
- **Currency:** Currency code (USD, EUR, EGP, etc.)
- **Due Date:** When payment is due
- **Category:** Payment category (Utilities, Housing, Food, etc.)
- **Type:** Whether it's a payment to make (`toPay`) or to receive (`toReceive`)
- **Recurring Information:** Whether it's recurring and frequency (monthly, weekly, yearly)
- **Notification Preferences:** When to notify user before due date

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It handles complex payment extraction from natural language, including sophisticated date parsing, recurring payment calculations, and multi-payment detection (extracting multiple payments from a single transcription).

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - RecordingCubit                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)           │
│   - ProcessPaymentTranscriptionUseCase│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - PaymentsRepositoryImpl            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - PaymentLLMDataSourceImpl         │ ← This file
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
- **`PaymentLLMDataSource`**: Abstract interface this class implements.
- **`ProcessedPayment`**: Domain entity representing structured payment data.
- **`Payment`**: Domain entity for payment (used for type enums).
- **`Currencies`**: Currency detection and symbol mapping.
- **`PaymentCategories`**: List of valid payment categories.
- **`LLMProcessingException`**: Custom exception for LLM processing errors.

## Key Features

### 1. Multi-Payment Extraction
The implementation can extract **multiple payments** from a single transcription. For example:
- "I need to pay the electric bill of $100 on the 3rd, and the rent of $2000 on the 5th"
- Returns an array of two `ProcessedPayment` objects.

### 2. Intelligent Date Parsing
Handles various date formats:
- Relative dates: "tomorrow", "next week"
- Absolute dates: "December 3rd", "on the 15th"
- Recurring dates: "each month on the 3rd", "every month"
- Calculates next occurrence for recurring payments in the past

### 3. Recurring Payment Logic
- Detects recurring payments from keywords
- Calculates next occurrence if date is in the past
- Handles edge cases (month-end dates, invalid days)

### 4. Currency Detection
- Detects currency from keywords in multiple languages
- Falls back to USD if not detected
- Supports: USD, EUR, EGP, SAR, AED, JPY, CNY, INR

## Detailed Code Walkthrough

### Class Structure

```dart
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
```

**Similar to Notes LLM:** Uses same pattern with fallback models for resilience.

### Process Payment Transcription

```dart
@override
Future<List<ProcessedPayment>> processPaymentTranscription(
  String transcription,
) async {
  try {
    final prompt = _buildPrompt(transcription);
    // ... API call similar to notes LLM
    final parsed = _parseResponse(generatedText, transcription);
    return parsed;
  } catch (e) {
    // Error handling...
  }
}
```

**Key Difference:** Returns `List<ProcessedPayment>` instead of single object, supporting multi-payment extraction.

### Prompt Engineering

The prompt is specifically designed for payment extraction:

```dart
String _buildPrompt(String transcription) {
  final detectedLanguage = _detectLanguage(transcription);
  // Language instructions...
  
  return '''
You are an intelligent payment processing assistant...
Extract the following information:
1. **title**: Payment description
2. **amount**: Numeric value only
3. **currency**: Currency code (USD, EUR, EGP, etc.)
4. **type**: Either "toPay" or "toReceive"
5. **dueDate**: Date in ISO format (YYYY-MM-DD)
6. **category**: One of: Utilities, Housing, Income, Food, ...
7. **isRecurring**: Boolean (true/false)
8. **recurringFrequency**: "monthly", "weekly", "yearly", or null
9. **notificationDays**: Array of integers

IMPORTANT: The transcription may contain MULTIPLE payments...
''';
}
```

**Why So Detailed?**
- **Structured Output:** Ensures AI returns consistent JSON format.
- **Multi-Payment Support:** Explicitly instructs AI to extract all payments.
- **Field Definitions:** Clear definitions prevent misinterpretation.
- **Examples:** Shows correct format for single and multiple payments.

### Response Parsing

The parsing logic is more complex than notes because it handles arrays:

```dart
List<ProcessedPayment> _parseResponse(
  String response,
  String originalTranscription,
) {
  try {
    String cleanedResponse = response.trim();
    // Remove markdown code blocks...
    
    // Find outermost JSON structure
    int? firstBrace = cleanedResponse.indexOf('{');
    int? firstBracket = cleanedResponse.indexOf('[');
    
    // Determine if array or object
    if (firstBracket != -1 && (firstBrace == -1 || firstBracket < firstBrace)) {
      // Array comes first - parse as array
      // ... bracket matching logic
      final jsonArray = jsonDecode(jsonString) as List<dynamic>;
      return jsonArray.map((json) => _parseSinglePayment(json, ...)).toList();
    }
    
    if (firstBrace != -1) {
      // Object comes first - parse as single payment
      // ... brace matching logic
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return [_parseSinglePayment(json, ...)];
    }
    
    throw const FormatException('No JSON found in response');
  } catch (e) {
    throw LLMProcessingException('Failed to parse payment response: $e');
  }
}
```

**Bracket Matching Logic:**
- **Why Needed?** AI might add extra text around JSON.
- **Depth Counting:** Tracks opening/closing brackets to find complete JSON.
- **Array vs Object:** Handles both single payment (object) and multiple payments (array).

**Why This Complexity?**
- **AI Variability:** AI responses can have extra text.
- **Robustness:** Ensures we extract valid JSON even with noise.
- **Flexibility:** Handles both single and multiple payment responses.

### Single Payment Parsing

```dart
ProcessedPayment _parseSinglePayment(
  Map<String, dynamic> json,
  String originalTranscription,
) {
  try {
    final title = json['title'] as String? ?? 'Payment';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final currencyCode = json['currency'] as String? ??
        Currencies.detectCurrency(originalTranscription) ??
        'USD';
    
    // Date parsing with fallback
    DateTime dueDate;
    if (dueDateString != null) {
      try {
        final parsedDate = DateTime.parse(dueDateString);
        // Handle recurring payments in the past
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
    
    // Final check for recurring payments
    if (isRecurring && dueDate.isBefore(DateTime.now())) {
      dueDate = _calculateNextRecurringDate(dueDate);
    }
    
    // ... other fields
    return ProcessedPayment(...);
  } catch (e) {
    throw LLMProcessingException('Failed to parse single payment: $e');
  }
}
```

**Key Parsing Logic:**

1. **Title:** Defaults to 'Payment' if missing.
2. **Amount:** Converts to double, defaults to 0.0.
3. **Currency:** Uses AI value, falls back to detection, then USD.
4. **Date:** Complex parsing with multiple fallbacks (see Date Parsing section).
5. **Category:** Must be from predefined list, defaults to 'Other'.
6. **Type:** Converts string to `PaymentType` enum.
7. **Recurring:** Handles recurring frequency and next occurrence calculation.

### Date Parsing Logic

This is one of the most complex parts of the implementation:

#### Extract Date from Transcription

```dart
DateTime _extractDateFromTranscription(String transcription) {
  final now = DateTime.now();
  final lowerText = transcription.toLowerCase();
  
  // Handle relative dates
  if (lowerText.contains('tomorrow')) {
    return now.add(const Duration(days: 1));
  }
  if (lowerText.contains('next week')) {
    return now.add(const Duration(days: 7));
  }
  
  // Check for recurring patterns
  final isRecurring = lowerText.contains('each month') ||
      lowerText.contains('every month') ||
      lowerText.contains('monthly');
  
  // Extract day of month
  final dayMatch = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\b').firstMatch(lowerText);
  if (dayMatch != null) {
    final day = int.tryParse(dayMatch.group(1) ?? '');
    if (day != null && day >= 1 && day <= 31) {
      try {
        var date = DateTime(now.year, now.month, day);
        
        // If recurring and date is in past, set to next month
        if (isRecurring && date.isBefore(now)) {
          if (now.month == 12) {
            date = DateTime(now.year + 1, 1, day);
          } else {
            date = DateTime(now.year, now.month + 1, day);
          }
        }
        // If not recurring and date is in past, set to next occurrence
        else if (!isRecurring && date.isBefore(now)) {
          // Similar logic...
        }
        
        return date;
      } catch (e) {
        // Handle invalid days (e.g., Feb 31)
        // Use last day of month
      }
    }
  }
  
  return now; // Default to today
}
```

**Date Extraction Strategy:**

1. **Relative Dates First:**
   - "tomorrow" → today + 1 day
   - "next week" → today + 7 days
   - Fast and unambiguous

2. **Day of Month Extraction:**
   - Regex matches: "3rd", "15th", "3", "15"
   - Handles ordinal suffixes (st, nd, rd, th)

3. **Recurring Detection:**
   - Keywords: "each month", "every month", "monthly"
   - Affects date calculation logic

4. **Past Date Handling:**
   - **Recurring:** If date is in past, move to next month
   - **Non-Recurring:** If date is in past, move to next occurrence
   - **Edge Case:** Handles month-end (e.g., Feb 31 → Feb 28/29)

5. **Invalid Day Handling:**
   - If day is invalid for month (e.g., Feb 31), uses last day of month
   - Prevents `DateTime` exceptions

**Why This Complexity?**
- **Natural Language:** Users express dates in many ways.
- **Context Matters:** "3rd" could mean this month or next month.
- **Recurring Logic:** Needs special handling for recurring payments.
- **Edge Cases:** Month-end dates, leap years, etc.

#### Calculate Next Recurring Date

```dart
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
    // Handle invalid day for month (e.g., Feb 31)
    // Use last day of next month
  }
}
```

**Recurring Date Logic:**

1. **Current Month First:**
   - Tries to use current month with original day.
   - If that date hasn't passed, use it.

2. **Next Month:**
   - If date has passed, move to next month.
   - Handles year rollover (December → January).

3. **Invalid Day Handling:**
   - If day doesn't exist in month (e.g., Feb 31), uses last valid day.
   - Ensures we always return a valid date.

**Why This Logic?**
- **User Intent:** "3rd of each month" means next occurrence of 3rd.
- **Past Dates:** If user says "3rd" and it's already the 5th, they mean next month's 3rd.
- **Consistency:** Always returns a future date for recurring payments.

### Currency Detection

```dart
final currencyCode = json['currency'] as String? ??
    Currencies.detectCurrency(originalTranscription) ??
    'USD';
```

**Three-Tier Fallback:**

1. **AI Detection:** AI extracts currency from transcription.
2. **Keyword Detection:** `Currencies.detectCurrency()` searches for currency keywords.
3. **Default:** Falls back to USD if not detected.

**Why Multiple Methods?**
- **AI Accuracy:** AI is good but not perfect.
- **Keyword Fallback:** Provides backup if AI misses it.
- **Always Valid:** Ensures we always have a currency code.

### Category Validation

```dart
final category = json['category'] as String? ?? 'Other';

// Must be from predefined list
if (!PaymentCategories.categories.contains(category)) {
  category = 'Other';
}
```

**Why Validate?**
- **Data Consistency:** Ensures categories match UI options.
- **Prevents Errors:** Invalid categories would break filtering/grouping.
- **Safe Default:** 'Other' is always valid.

### Payment Type Conversion

```dart
final typeString = json['type'] as String? ?? 'toPay';
final type = typeString == 'toReceive'
    ? PaymentType.toReceive
    : PaymentType.toPay;
```

**Why Default to 'toPay'?**
- **Most Common:** Most payments are expenses, not income.
- **Safe Default:** Better to default to expense than miss income.
- **User Can Correct:** User can edit if wrong.

### Notification Days

```dart
final notificationDaysList = json['notificationDays'] as List<dynamic>?;
final notificationDays = notificationDaysList
    ?.map((e) => (e as num).toInt())
    .where((e) => e >= 0)
    .toList() ?? [];
```

**Parsing Logic:**
- Converts to integers.
- Filters negative values (invalid).
- Defaults to empty array if not specified.

**Why Filter Negative?**
- Notification days must be non-negative (days before due date).
- Prevents invalid data.

## Multi-Payment Handling

### Why Support Multiple Payments?

Users often mention multiple payments in one recording:
- "I need to pay the electric bill of $100 on the 3rd, the rent of $2000 on the 5th, and groceries of $300 on the 10th"

### Implementation

The parsing logic handles both formats:

1. **Single Payment:** `{ "title": "...", ... }`
2. **Multiple Payments:** `[{ "title": "...", ... }, { "title": "...", ... }]`

**Bracket Matching:**
- Finds outermost JSON structure.
- Handles nested objects/arrays correctly.
- Extracts complete JSON even with surrounding text.

**Why Bracket Matching?**
- AI might add explanatory text.
- Need to extract valid JSON from response.
- Handles both array and object responses.

## Error Handling

### Exception Types

- **`LLMProcessingException`:** All LLM-related errors.
- **`FormatException`:** JSON parsing errors.

### Error Scenarios

1. **No JSON in Response:**
   - **Detection:** No `{` or `[` found.
   - **Handling:** Throws `FormatException`.

2. **Invalid JSON:**
   - **Detection:** `jsonDecode` fails.
   - **Handling:** Throws `LLMProcessingException`.

3. **Invalid Date:**
   - **Detection:** Date parsing fails.
   - **Handling:** Falls back to transcription extraction.

4. **Invalid Day for Month:**
   - **Detection:** `DateTime` constructor throws.
   - **Handling:** Uses last valid day of month.

5. **All Models Fail:**
   - **Detection:** All fallback models fail.
   - **Handling:** Throws exception with helpful message.

## Testing Considerations

### What Should Be Tested

1. **Single Payment Extraction:**
   - Valid transcription produces one payment.
   - All fields populated correctly.

2. **Multi-Payment Extraction:**
   - Transcription with multiple payments returns array.
   - Each payment parsed correctly.

3. **Date Parsing:**
   - Relative dates ("tomorrow", "next week").
   - Absolute dates ("December 3rd", "on the 15th").
   - Recurring dates ("each month on the 3rd").
   - Past dates handled correctly.

4. **Recurring Logic:**
   - Next occurrence calculated correctly.
   - Month-end dates handled.
   - Year rollover handled.

5. **Currency Detection:**
   - AI detection works.
   - Keyword fallback works.
   - Default to USD works.

6. **Edge Cases:**
   - Empty transcription.
   - Invalid dates.
   - Invalid categories.
   - Missing fields.

## Future Improvements

1. **Better Date Parsing:**
   - Use NLP library for date parsing.
   - Handle more date formats.
   - Support timezone awareness.

2. **Currency Expansion:**
   - Support more currencies.
   - Better detection algorithms.
   - Exchange rate integration.

3. **Category Learning:**
   - Learn from user corrections.
   - Improve category detection.
   - Custom categories.

4. **Payment Templates:**
   - Remember common payments.
   - Suggest templates.
   - Quick entry.

5. **Validation:**
   - Validate amounts (reasonable ranges).
   - Validate dates (not too far in future/past).
   - Validate categories.

## Summary

The `PaymentLLMDataSourceImpl` provides robust payment extraction:

- **Multi-Payment Support:** Extracts multiple payments from one transcription.
- **Intelligent Date Parsing:** Handles various date formats and recurring logic.
- **Currency Detection:** Multiple fallback methods ensure accuracy.
- **Recurring Logic:** Calculates next occurrence for recurring payments.
- **Error Resilience:** Multiple fallbacks ensure reliability.

This implementation ensures reliable payment extraction while handling the complexity of natural language date expressions and recurring payment calculations.
