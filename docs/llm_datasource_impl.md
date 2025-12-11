# LLM Data Source Implementation (Notes Processing)

## File Overview

**File Path:** `lib/data/datasource_impl/llm_datasource_impl.dart`

**Purpose:** This file implements the `LLMDataSource` interface, providing integration with Google's Gemini AI API to process voice transcriptions and convert them into structured note data. It takes raw transcription text and uses AI to extract:
- **Title:** A concise, descriptive title
- **Bullet Points:** Key points extracted from the transcription
- **Tags:** Relevant hashtags/categories
- **Summary:** A brief summary of the note

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It acts as the interface between the application and Google's Gemini AI service, handling prompt engineering, API communication, response parsing, and error handling with fallback mechanisms.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - RecordingCubit                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)           │
│   - ProcessTranscriptionUseCase      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - AudioRepositoryImpl              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - LLMDataSourceImpl                │ ← This file
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   External Service                   │
│   - Google Gemini API                │
└─────────────────────────────────────┘
```

## Dependencies

### External Packages
- **`google_generative_ai`** (`^0.4.0`): Google's Gemini AI SDK for Flutter. Provides `GenerativeModel`, `GenerateContentResponse`, and related types.

### Internal Dependencies
- **`AppConfig`**: Contains Gemini API key and model configuration.
- **`LLMDataSource`**: Abstract interface this class implements.
- **`ProcessedNote`**: Domain entity representing structured note data.
- **`LLMProcessingException`**: Custom exception for LLM processing errors.

## Detailed Code Walkthrough

### Class Declaration and State

```dart
@LazySingleton(as: LLMDataSource)
class LLMDataSourceImpl implements LLMDataSource {
  late final GenerativeModel _model;
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.5-pro',
  ];
```

**Why `@LazySingleton`?**
- Ensures only one instance exists throughout the app.
- Lazy initialization means it's created only when first needed.
- Registered as `LLMDataSource` interface for dependency inversion.

**Model Instance:**
- **`late final GenerativeModel _model`:** The Gemini model instance.
- **`late`:** Initialized in constructor, not at declaration.
- **`final`:** Once set, never changes.

**Fallback Models:**
- **Why Fallback?** If primary model fails (quota, unavailable), try alternatives.
- **Order Matters:** Tried in order, fastest/cheapest first.
- **Comprehensive List:** Covers different model tiers (flash, pro, lite).

### Constructor

```dart
LLMDataSourceImpl() {
  try {
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
    );
  } catch (e) {
    rethrow;
  }
}
```

**Why Initialize in Constructor?**
- **Early Failure:** If API key is invalid, fail immediately.
- **No Lazy Init:** Model is needed for all operations, so initialize early.
- **Error Propagation:** Re-throws to indicate configuration issue.

**Model Configuration:**
- **`model`:** From `AppConfig.geminiModel` (typically `'gemini-2.5-flash'`).
- **`apiKey`:** From `AppConfig.geminiApiKey` (API key for authentication).

### Process Transcription Method

```dart
@override
Future<ProcessedNote> processTranscription(String transcription) async {
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

    return _parseResponse(generatedText, transcription);
  } on GenerativeAIException catch (e) {
    throw LLMProcessingException('Gemini API error: ${e.message}');
  } catch (e) {
    if (e is LLMProcessingException) {
      rethrow;
    }

    final errorMessage = e.toString();
    if (errorMessage.contains('API key') ||
        errorMessage.contains('authentication')) {
      throw LLMProcessingException(
        'Invalid Gemini API key. Please check your configuration.',
      );
    }

    throw LLMProcessingException('Failed to process transcription: $e');
  }
}
```

**Step-by-Step Breakdown:**

1. **Build Prompt:**
   ```dart
   final prompt = _buildPrompt(transcription);
   ```
   - Converts transcription into a detailed prompt for the AI.
   - Includes instructions, examples, and formatting requirements.
   - See "Prompt Engineering" section for details.

2. **Generation Configuration:**
   ```dart
   final generationConfig = GenerationConfig(
     temperature: 0.3,
     topK: 40,
     topP: 0.95,
   );
   ```
   - **`temperature: 0.3`:** Low temperature = more deterministic, consistent output.
   - **`topK: 40`:** Consider top 40 most likely tokens at each step.
   - **`topP: 0.95`:** Nucleus sampling - consider tokens until cumulative probability reaches 95%.
   - **Why These Values?** Balance between creativity and consistency. Lower temperature ensures structured output.

3. **API Call with Timeout:**
   ```dart
   response = await _model
       .generateContent([Content.text(prompt)], generationConfig: generationConfig)
       .timeout(const Duration(seconds: 60), ...);
   ```
   - **Why Timeout?** Prevents hanging on slow/unresponsive API.
   - **60 Seconds:** Reasonable for AI processing (complex prompts can take time).
   - **Timeout Handler:** Throws `LLMProcessingException` with clear message.

4. **Fallback on Model Errors:**
   ```dart
   on GenerativeAIException catch (e) {
     if (e.message.contains('not found') || ...) {
       return _tryWithFallbackModels(...);
     }
   }
   ```
   - **When to Fallback:** Model not found, quota exceeded, model unavailable.
   - **Automatic Retry:** Tries fallback models without user intervention.
   - **Seamless Experience:** User doesn't see the error, just gets result.

5. **Response Validation:**
   ```dart
   if (generatedText.isEmpty) {
     throw LLMProcessingException('Gemini API returned empty response');
   }
   ```
   - **Why Check?** API might return success but empty text.
   - **Clear Error:** Provides specific error message.

6. **Parse Response:**
   ```dart
   return _parseResponse(generatedText, transcription);
   ```
   - Extracts structured data from AI response.
   - Handles JSON parsing, validation, and fallbacks.

7. **Comprehensive Error Handling:**
   - **API Key Errors:** Specific message for authentication issues.
   - **Generic Errors:** Wraps unknown errors in `LLMProcessingException`.
   - **Preserves Exceptions:** Re-throws `LLMProcessingException` to maintain type.

### Prompt Engineering

The `_buildPrompt` method is crucial for getting good results from the AI. Let's examine it:

```dart
String _buildPrompt(String transcription) {
  final detectedLanguage = _detectLanguage(transcription);
  final languageInstruction = detectedLanguage == 'en'
      ? 'The transcription is in ENGLISH. You MUST respond in ENGLISH for ALL fields...'
      : detectedLanguage == 'ar'
      ? 'The transcription is in ARABIC. You MUST respond in ARABIC for ALL fields...'
      : // ... more languages
      : 'The transcription appears to be in ${detectedLanguage.toUpperCase()}...';
```

**Language Detection:**
- Detects language of transcription before building prompt.
- Ensures AI responds in the same language.
- Critical for multilingual support.

**Why Language Detection?**
- **Consistency:** Title, bullets, tags, summary should match transcription language.
- **User Experience:** Users expect content in their language.
- **Accuracy:** AI performs better when language is specified.

**Prompt Structure:**
The prompt includes:

1. **Language Requirements:** Clear instructions about language matching.
2. **Requirements Section:** What to extract (title, bullets, tags, summary).
3. **Transcription:** The actual text to process.
4. **JSON Format:** Exact JSON structure expected.
5. **Examples:** Shows correct format.
6. **Critical Rules:** Emphasizes mandatory fields (like bullet points).

**Why So Detailed?**
- **AI Clarity:** More specific instructions = better results.
- **Format Consistency:** Ensures AI returns expected JSON structure.
- **Error Prevention:** Reduces parsing errors and malformed responses.

### Language Detection

```dart
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

  // Similar patterns for German and English...
  return 'en';
}
```

**Detection Strategy:**

1. **Arabic Detection:**
   - Uses Unicode ranges for Arabic characters.
   - Calculates percentage of Arabic characters.
   - If > 40% Arabic, detected as Arabic.

2. **German Detection:**
   - Looks for common German words.
   - Pattern matching for German vocabulary.

3. **English Detection:**
   - Looks for common English words.
   - Default fallback.

**Why This Approach?**
- **Simple:** Fast, no external dependencies.
- **Effective:** Works well for major languages.
- **Extensible:** Easy to add more languages.

**Limitations:**
- **Not Perfect:** Can misclassify mixed-language text.
- **Basic:** Doesn't handle all edge cases.
- **Improvement:** Could use more sophisticated detection (ML-based).

### Response Parsing

```dart
ProcessedNote _parseResponse(String response, String originalTranscription) {
  try {
    String cleanedResponse = response.trim();

    // Remove markdown code blocks
    cleanedResponse = cleanedResponse.replaceAll(
      RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```', multiLine: true),
      r'$1',
    );

    // Extract JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedResponse);
    if (jsonMatch == null) {
      throw const FormatException('No JSON found in response');
    }

    final jsonString = jsonMatch.group(0)!;
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Extract fields...
    final title = json['title'] as String? ?? 'Untitled Note';
    
    // Handle bullet points (supports both 'bulletPoints' and 'bullet_points')
    var bulletPoints = <String>[];
    if (json.containsKey('bulletPoints')) {
      // ... extract from 'bulletPoints'
    } else if (json.containsKey('bullet_points')) {
      // ... extract from 'bullet_points'
    }

    // Generate fallback if empty
    if (bulletPoints.isEmpty) {
      bulletPoints = _generateBulletPointsFromTranscription(originalTranscription);
    }

    // Extract tags and summary...
    final tags = (json['tags'] as List<dynamic>?)
        ?.map((e) => e.toString().toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList() ?? [];
    
    final summary = json['summary'] as String?;

    // Build content from bullet points or use transcription
    final content = bulletPoints.isEmpty
        ? originalTranscription
        : bulletPoints.map((point) => '• $point').join('\n');

    return ProcessedNote(
      title: title,
      content: content,
      bulletPoints: bulletPoints,
      tags: tags,
      summary: summary,
    );
  } catch (e) {
    // Fallback: create basic note from transcription
    return ProcessedNote(
      title: _extractTitle(originalTranscription),
      content: originalTranscription,
      bulletPoints: [],
      tags: _extractSimpleTags(originalTranscription),
      summary: null,
    );
  }
}
```

**Parsing Strategy:**

1. **Clean Response:**
   - Removes markdown code blocks (AI sometimes wraps JSON in ```json blocks).
   - Trims whitespace.

2. **Extract JSON:**
   - Uses regex to find JSON object in response.
   - Handles cases where AI adds extra text.

3. **Parse JSON:**
   - Decodes JSON string to Map.
   - Extracts each field with null safety.

4. **Field Extraction:**
   - **Title:** Defaults to 'Untitled Note' if missing.
   - **Bullet Points:** Handles both `bulletPoints` and `bullet_points` (AI inconsistency).
   - **Tags:** Converts to lowercase, trims, filters empty.
   - **Summary:** Optional field.

5. **Fallback Generation:**
   - If bullet points empty, generates from transcription.
   - Ensures we always have some structure.

6. **Content Building:**
   - If bullet points exist, formats as bullet list.
   - Otherwise, uses full transcription.

7. **Error Handling:**
   - If parsing fails completely, creates basic note from transcription.
   - Ensures we always return something useful.

**Why So Defensive?**
- **AI Variability:** AI responses can vary in format.
- **Resilience:** Always returns usable data, even if parsing fails.
- **User Experience:** Better to show something than nothing.

### Fallback Mechanisms

#### Fallback Models

```dart
Future<ProcessedNote> _tryWithFallbackModels(
  String prompt,
  String transcription,
  GenerationConfig generationConfig,
) async {
  for (final modelName in _fallbackModels) {
    if (modelName == AppConfig.geminiModel) {
      continue; // Skip primary model (already tried)
    }

    try {
      final fallbackModel = GenerativeModel(
        model: modelName,
        apiKey: AppConfig.geminiApiKey,
      );

      final response = await fallbackModel
          .generateContent([Content.text(prompt)], generationConfig: generationConfig)
          .timeout(const Duration(seconds: 60));

      final generatedText = response.text ?? '';
      if (generatedText.isNotEmpty) {
        return _parseResponse(generatedText, transcription);
      }
    } catch (e) {
      continue; // Try next model
    }
  }

  throw LLMProcessingException(
    'All Gemini models failed due to quota limits or availability...',
  );
}
```

**Fallback Strategy:**
1. **Try Each Model:** Iterates through fallback list.
2. **Skip Primary:** Skips model that already failed.
3. **Create New Instance:** Each model needs its own instance.
4. **Same Prompt:** Uses same prompt and config.
5. **Continue on Error:** If one fails, try next.
6. **Return on Success:** Returns first successful result.
7. **Throw if All Fail:** If all models fail, throw exception.

**Why This Order?**
- **Flash Models First:** Faster, cheaper.
- **Pro Models Last:** Slower, more expensive, but more capable.
- **Balance:** Speed vs. capability.

#### Fallback Content Generation

If AI fails completely, the code generates basic structure from transcription:

```dart
String _extractTitle(String text) {
  final sentences = text.split(RegExp(r'[.!?]'));
  if (sentences.isNotEmpty) {
    final firstSentence = sentences.first.trim();
    if (firstSentence.length > 50) {
      return '${firstSentence.substring(0, 47)}...';
    }
    return firstSentence;
  }
  return 'Voice Note';
}
```

**Simple Title Extraction:**
- Uses first sentence as title.
- Truncates if too long.
- Defaults to 'Voice Note' if no sentences.

**Bullet Point Generation:**
- Splits transcription into sentences.
- Filters short sentences.
- Takes first 7 sentences as bullet points.
- Falls back to transcription if not enough sentences.

**Tag Extraction:**
- Extracts keywords from text.
- Filters common words.
- Takes top 5 keywords as tags.

## Error Handling Strategy

### Exception Types

- **`LLMProcessingException`:** All LLM-related errors.
- **`GenerativeAIException`:** Errors from Gemini SDK.
- **`FormatException`:** JSON parsing errors.

### Error Scenarios

1. **API Key Invalid:**
   - **Detection:** Error message contains 'API key' or 'authentication'.
   - **Handling:** Clear message about checking configuration.

2. **Model Not Found:**
   - **Detection:** Error message contains 'not found' or 'not supported'.
   - **Handling:** Try fallback models.

3. **Quota Exceeded:**
   - **Detection:** Error message contains 'quota' or 'Quota exceeded'.
   - **Handling:** Try fallback models, then throw with helpful message.

4. **Timeout:**
   - **Detection:** Request takes > 60 seconds.
   - **Handling:** Throw timeout exception.

5. **Empty Response:**
   - **Detection:** API returns success but empty text.
   - **Handling:** Throw exception with clear message.

6. **JSON Parse Error:**
   - **Detection:** Response not valid JSON.
   - **Handling:** Fallback to basic note generation.

## Configuration

### API Key
- Stored in `AppConfig.geminiApiKey`.
- Should be kept secure (not committed to public repos).
- Can be set via environment variables.

### Model Selection
- Stored in `AppConfig.geminiModel`.
- Default: `'gemini-2.5-flash'`.
- Can be changed for different use cases.

### Generation Config
- **Temperature:** 0.3 (low = more deterministic).
- **TopK:** 40 (consider top 40 tokens).
- **TopP:** 0.95 (nucleus sampling).

## Testing Considerations

### What Should Be Tested

1. **Successful Processing:**
   - Valid transcription produces structured note.
   - All fields populated correctly.

2. **Language Detection:**
   - Correct language detected for different inputs.
   - Language instructions included in prompt.

3. **Response Parsing:**
   - Handles various JSON formats.
   - Fallback generation works when parsing fails.

4. **Error Handling:**
   - Fallback models tried on failure.
   - Appropriate exceptions thrown.

5. **Edge Cases:**
   - Empty transcription.
   - Very long transcription.
   - Special characters in transcription.

## Future Improvements

1. **Better Language Detection:**
   - Use ML-based detection.
   - Support more languages.

2. **Prompt Optimization:**
   - A/B test different prompts.
   - Optimize for accuracy and consistency.

3. **Caching:**
   - Cache processed notes for same transcription.
   - Reduce API calls and costs.

4. **Streaming Responses:**
   - Stream partial results as AI generates.
   - Better user experience.

5. **Multiple AI Providers:**
   - Support OpenAI, Anthropic, etc.
   - Automatic failover.

6. **Fine-Tuning:**
   - Fine-tune model on app-specific data.
   - Improve accuracy for voice notes.

## Summary

The `LLMDataSourceImpl` provides robust AI-powered note processing:

- **Prompt Engineering:** Detailed prompts ensure consistent, structured output.
- **Language Support:** Detects and preserves transcription language.
- **Error Resilience:** Multiple fallback mechanisms ensure reliability.
- **Flexible Parsing:** Handles various AI response formats.
- **User Experience:** Always returns usable data, even on failure.

This implementation ensures reliable note processing while handling the variability and potential failures of AI services.
