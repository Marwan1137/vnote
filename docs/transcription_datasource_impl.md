# Transcription Data Source Implementation

## File Overview

**File Path:** `lib/data/datasource_impl/transcription_datasource_impl.dart`

**Purpose:** This file implements the `TranscriptionDataSource` interface, serving as a wrapper that combines Google Speech-to-Text API (via `GoogleSpeechService`) with local speech recognition capabilities (via `speech_to_text` package). It provides a unified interface for audio transcription while leveraging both local and cloud-based services.

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It acts as an adapter/wrapper pattern, combining multiple transcription services into a single, consistent interface. It handles initialization of both services and delegates actual transcription to Google Speech API while using local speech recognition for language detection capabilities.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - RecordingCubit                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)           │
│   - TranscribeAudioUseCase           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - AudioRepositoryImpl              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - TranscriptionDataSourceImpl      │ ← This file
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────────────┐
│ Google      │  │ Local Speech        │
│ Speech API  │  │ Recognition         │
│ (Cloud)     │  │ (Device)            │
└─────────────┘  └─────────────────────┘
```

## Dependencies

### External Packages
- **`speech_to_text`** (`^7.0.0`): Local speech recognition package. Used for language detection and available language queries. Does not perform actual transcription (that's done by Google API).

### Internal Dependencies
- **`GoogleSpeechService`**: Interface for Google Speech-to-Text API service.
- **`GoogleSpeechServiceImpl`**: Concrete implementation of Google Speech service.
- **`TranscriptionDataSource`**: Abstract interface this class implements.
- **`TranscriptionException`**: Custom exception for transcription errors.

## Design Pattern: Adapter/Wrapper

### Why This Pattern?

This class implements the **Adapter Pattern** (also called Wrapper Pattern):

1. **Unified Interface:** Provides a single interface (`TranscriptionDataSource`) that hides the complexity of multiple underlying services.
2. **Service Composition:** Combines Google Speech API (for actual transcription) with local speech recognition (for language detection).
3. **Flexibility:** Can swap underlying services without changing the interface.
4. **Separation of Concerns:** Each service handles what it's best at:
   - Google API: Accurate cloud-based transcription
   - Local Recognition: Language detection and availability

### Benefits

- **Abstraction:** Calling code doesn't need to know about multiple services.
- **Testability:** Can mock individual services independently.
- **Maintainability:** Changes to underlying services don't affect callers.
- **Extensibility:** Easy to add more transcription services in the future.

## Detailed Code Walkthrough

### Class Declaration and State

```dart
@LazySingleton(as: TranscriptionDataSource)
class TranscriptionDataSourceImpl implements TranscriptionDataSource {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final GoogleSpeechService _googleSpeechService = GoogleSpeechServiceImpl();
  bool _isInitialized = false;
```

**Why `@LazySingleton`?**
- Ensures only one instance exists throughout the app.
- Lazy initialization means it's created only when first needed.
- Registered as `TranscriptionDataSource` interface for dependency inversion.

**Service Instances:**

1. **`_speechToText`:**
   - Instance of local speech recognition.
   - Used for language detection, not transcription.
   - Created directly (not injected) because it's a simple wrapper.

2. **`_googleSpeechService`:**
   - Instance of Google Speech API service.
   - Used for actual audio transcription.
   - Created directly (not injected) for simplicity, but could be injected for better testability.

3. **`_isInitialized`:**
   - Tracks initialization status.
   - Prevents redundant initialization.

**Why Create Instances Directly?**
- **Simplicity:** These are concrete implementations, not interfaces.
- **Trade-off:** Less testable, but simpler code.
- **Alternative:** Could inject them for better testability (recommended for production).

### Initialization Method

```dart
@override
Future<bool> initialize() async {
  if (_isInitialized) return true;

  try {
    await _googleSpeechService.initialize();

    final available = await _speechToText.initialize(
      onError: (error) {
        // Log error but don't throw - we're using Google API for transcription
      },
      onStatus: (status) {
        // Handle status if needed
      },
    );

    _isInitialized = true;
    return available;
  } catch (e) {
    throw TranscriptionException(
      'Failed to initialize speech recognition: $e',
    );
  }
}
```

**Step-by-Step Breakdown:**

1. **Early Return:**
   ```dart
   if (_isInitialized) return true;
   ```
   - **Idempotency:** Safe to call multiple times.
   - **Performance:** Avoids redundant initialization.

2. **Initialize Google Service:**
   ```dart
   await _googleSpeechService.initialize();
   ```
   - **Primary Service:** Google API is the main transcription service.
   - **Must Succeed:** If this fails, initialization fails (throws exception).

3. **Initialize Local Recognition:**
   ```dart
   final available = await _speechToText.initialize(
     onError: (error) {
       // Log error but don't throw
     },
     onStatus: (status) {
       // Handle status if needed
     },
   );
   ```
   - **Why Not Throw on Error?** Local recognition is optional - we use Google API for transcription.
   - **Error Callback:** Logs errors but doesn't fail initialization.
   - **Status Callback:** Can track initialization status if needed.
   - **Returns Boolean:** Indicates if local recognition is available on device.

4. **Why Local Recognition Doesn't Block:**
   - Google API is the primary service.
   - Local recognition is only for language detection.
   - If local recognition fails, we can still transcribe (just without local language hints).

5. **Error Handling:**
   ```dart
   catch (e) {
     throw TranscriptionException(
       'Failed to initialize speech recognition: $e',
     );
   }
   ```
   - **Wraps All Errors:** Any initialization error becomes `TranscriptionException`.
   - **Preserves Context:** Includes original error message.
   - **Domain Exception:** Uses domain-specific exception type.

**Why Return Boolean?**
- Indicates if local speech recognition is available.
- Useful for UI to show/hide language selection features.
- Doesn't affect transcription capability (Google API works regardless).

### Transcription Method

```dart
@override
Future<String> transcribeAudio(
  String audioPath, {
  String? languageCode,
  List<String>? alternativeLanguageCodes,
  }) async {
  try {
    if (!_isInitialized) {
      await initialize();
    }

    final transcription = await _googleSpeechService.transcribeAudio(
      audioPath,
      languageCode: languageCode,
      alternativeLanguageCodes:
          alternativeLanguageCodes ??
          [
            'en-US',
            'ar-EG',
            'fr-FR',
            'es-ES',
            'de-DE',
            'it-IT',
            'pt-BR',
            'ru-RU',
            'ja-JP',
            'zh-CN',
            'ko-KR',
            'hi-IN',
          ],
      sampleRateHertz: 44100,
    );

    if (transcription.isEmpty) {
      throw TranscriptionException('Transcription returned empty result');
    }

    return transcription;
  } catch (e) {
    if (e is TranscriptionException) rethrow;
    throw TranscriptionException('Transcription failed: $e');
  }
}
```

**Key Design Decisions:**

1. **Auto-Initialization:**
   ```dart
   if (!_isInitialized) {
     await initialize();
   }
   ```
   - **Lazy Initialization:** Initializes on first use if not already done.
   - **User-Friendly:** Calling code doesn't need to remember to initialize.
   - **Flexible:** Supports both explicit and implicit initialization.

2. **Delegation to Google Service:**
   ```dart
   final transcription = await _googleSpeechService.transcribeAudio(...);
   ```
   - **Actual Work:** Google API does the transcription.
   - **This Class:** Just wraps and provides default values.

3. **Default Alternative Languages:**
   ```dart
   alternativeLanguageCodes ??
   [
     'en-US',  // English (US)
     'ar-EG',  // Arabic (Egypt)
     'fr-FR',  // French
     'es-ES',  // Spanish
     'de-DE',  // German
     'it-IT',  // Italian
     'pt-BR',  // Portuguese (Brazil)
     'ru-RU',  // Russian
     'ja-JP',  // Japanese
     'zh-CN',  // Chinese (Simplified)
     'ko-KR',  // Korean
     'hi-IN',  // Hindi
   ]
   ```
   - **Why Defaults?** If caller doesn't specify, we provide a comprehensive list.
   - **Multilingual Support:** Covers major languages the app might encounter.
   - **Override-able:** Caller can still provide custom list.

4. **Why These Languages?**
   - **Common Languages:** Covers most global users.
   - **App's Target Markets:** Based on expected user base.
   - **Balanced:** Not too many (performance) or too few (coverage).

5. **Empty Transcription Check:**
   ```dart
   if (transcription.isEmpty) {
      throw TranscriptionException('Transcription returned empty result');
   }
   ```
   - **Validation:** Ensures we don't return empty strings.
   - **Clear Error:** Provides specific error message.
   - **User Experience:** Better than returning empty string silently.

6. **Error Handling:**
   ```dart
   catch (e) {
     if (e is TranscriptionException) rethrow;
     throw TranscriptionException('Transcription failed: $e');
   }
   ```
   - **Preserves Domain Exceptions:** Re-throws `TranscriptionException` as-is.
   - **Wraps Others:** Converts unknown errors to `TranscriptionException`.
   - **Consistent Interface:** All errors are `TranscriptionException`.

### Get Available Languages Method

```dart
@override
Future<List<stt.LocaleName>> getAvailableLanguages() async {
  if (!_isInitialized) {
    await initialize();
  }
  return _speechToText.locales();
}
```

**Purpose:**
- Returns list of languages supported by local speech recognition.
- Used by UI to show language selection options.
- Helps users choose their language before recording.

**Why Use Local Recognition for This?**
- **Fast:** Local query, no API call needed.
- **Device-Specific:** Shows languages actually available on device.
- **UI Helper:** Provides language list for user selection.

**Why Not Google API?**
- Google API supports 100+ languages (too many to show in UI).
- Local recognition provides a curated, device-relevant list.
- Faster response time for UI.

**Auto-Initialization:**
- Initializes if needed before querying.
- Ensures local recognition is ready.

**Return Type:**
- `List<stt.LocaleName>`: Contains locale information (code, name, etc.).
- Can be used to build language selection UI.

## Language Detection Strategy

### Current Implementation

The current implementation doesn't perform automatic language detection. Instead:

1. **User Selection:** User can select language before recording.
2. **Default Languages:** If not specified, uses comprehensive default list.
3. **Alternative Languages:** Provides fallback languages for better accuracy.

### Why Not Auto-Detect?

1. **Complexity:** Language detection requires additional processing.
2. **Accuracy:** User-selected language is more accurate than auto-detection.
3. **Performance:** Auto-detection adds latency.
4. **Google API:** Google API can handle language detection, but it's better to specify.

### Future Enhancement: Auto-Detection

Could be enhanced to:

1. **Use Local Recognition:** Quick language hint from local recognition.
2. **Analyze Audio:** Basic audio analysis for language hints.
3. **User History:** Remember user's preferred languages.
4. **Hybrid Approach:** Combine multiple signals for better detection.

## Error Handling Strategy

### Exception Hierarchy

```
Exception (Dart base)
└── TranscriptionException (core/errors/exceptions.dart)
    └── All transcription-related errors
```

### Error Scenarios

1. **Initialization Failure:**
   - **Cause:** Google API credentials invalid, network error, etc.
   - **Handling:** Throws `TranscriptionException` with clear message.

2. **File Not Found:**
   - **Cause:** Invalid audio file path.
   - **Handling:** Propagated from Google service, wrapped in `TranscriptionException`.

3. **Empty Transcription:**
   - **Cause:** Silent audio, poor quality, language mismatch.
   - **Handling:** Explicitly checked and throws `TranscriptionException`.

4. **Network Error:**
   - **Cause:** No internet, API unreachable.
   - **Handling:** Propagated from Google service, wrapped in `TranscriptionException`.

5. **API Quota Exceeded:**
   - **Cause:** API quota limit reached.
   - **Handling:** Propagated from Google service, wrapped in `TranscriptionException`.

### Why Consistent Exception Type?

- **Simplified Error Handling:** Calling code only needs to handle one exception type.
- **Consistent Interface:** All transcription errors are `TranscriptionException`.
- **Clear Semantics:** Exception name clearly indicates transcription issue.

## Service Composition Benefits

### Why Combine Services?

1. **Best of Both Worlds:**
   - Google API: Accurate, cloud-based transcription.
   - Local Recognition: Fast language queries, device capabilities.

2. **Resilience:**
   - If one service fails, the other might still work.
   - Local recognition can provide language hints even if Google API is down.

3. **User Experience:**
   - Local recognition provides immediate language list.
   - Google API provides accurate transcription.

4. **Flexibility:**
   - Can add more services in the future.
   - Easy to swap implementations.

### Service Responsibilities

| Service | Responsibility | Used For |
|---------|---------------|----------|
| Google Speech API | Audio transcription | Actual transcription work |
| Local Recognition | Language detection | Language list, hints |

## Testing Considerations

### What Should Be Tested

1. **Initialization:**
   - Successful initialization of both services.
   - Failure handling when Google service fails.
   - Idempotency (multiple initialization calls).

2. **Transcription:**
   - Successful transcription delegation to Google service.
   - Default language codes when not provided.
   - Empty transcription handling.

3. **Language Queries:**
   - Returns available languages from local recognition.
   - Handles initialization if needed.

4. **Error Handling:**
   - Wraps errors in `TranscriptionException`.
   - Preserves `TranscriptionException` when re-throwing.

### Mocking Strategy

```dart
// Example test structure
test('transcribeAudio delegates to Google service', () async {
  // Arrange: Mock Google service
  final mockGoogleService = MockGoogleSpeechService();
  final service = TranscriptionDataSourceImpl();
  // ... setup mocks
  
  // Act
  final result = await service.transcribeAudio('test.wav');
  
  // Assert
  verify(mockGoogleService.transcribeAudio(any)).called(1);
  expect(result, isNotEmpty);
});
```

## Future Improvements

1. **Dependency Injection:**
   - Inject `GoogleSpeechService` instead of creating directly.
   - Better testability and flexibility.

2. **Language Auto-Detection:**
   - Use local recognition to detect language before transcription.
   - Improve accuracy with language hints.

3. **Fallback Strategy:**
   - If Google API fails, try local recognition as fallback.
   - Provide offline transcription capability.

4. **Caching:**
   - Cache transcriptions for same audio file.
   - Reduce API calls and improve performance.

5. **Progress Reporting:**
   - Report transcription progress to UI.
   - Better user experience for long audio.

6. **Multiple Service Support:**
   - Support multiple cloud transcription services.
   - Automatic failover between services.

7. **Language Learning:**
   - Remember user's preferred languages.
   - Auto-select based on history.

8. **Audio Preprocessing:**
   - Normalize audio before transcription.
   - Improve accuracy.

## Summary

The `TranscriptionDataSourceImpl` provides a unified interface for audio transcription by:

- **Combining Services:** Wraps Google Speech API and local recognition.
- **Providing Defaults:** Supplies sensible default language codes.
- **Handling Errors:** Consistent error handling with `TranscriptionException`.
- **Auto-Initialization:** Initializes services on first use.
- **Language Support:** Provides language list for UI.

This implementation follows the Adapter Pattern, providing a clean abstraction over multiple underlying services while maintaining flexibility and testability.
