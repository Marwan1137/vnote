# Google Speech-to-Text & Gemini API Integration Documentation

## Table of Contents
1. [Overview](#overview)
2. [Google Speech-to-Text API](#google-speech-to-text-api)
3. [Google Gemini API](#google-gemini-api)
4. [Architecture & Flow](#architecture--flow)
5. [File Structure](#file-structure)
6. [Configuration](#configuration)
7. [Error Handling](#error-handling)
8. [Usage Examples](#usage-examples)

---

## Overview

This project integrates two Google Cloud services:
- **Google Speech-to-Text API**: Converts audio recordings to text transcriptions
- **Google Gemini API**: Processes transcriptions to generate structured notes and payment information

The integration follows Clean Architecture principles with dependency injection, repository pattern, and use cases.

---

## Google Speech-to-Text API

### Purpose
Converts audio files (recordings) into text transcriptions with support for multiple languages and automatic language detection.

### Implementation Files

#### 1. `lib/data/datasources_contracts/google_speech_service.dart`
**Abstract Interface** - Defines the contract for Google Speech-to-Text service.

```dart
abstract class GoogleSpeechService {
  Future<void> initialize();
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
    int sampleRateHertz = 44100,
  });
  void dispose();
}
```

**Key Methods:**
- `initialize()`: Sets up authentication using service account credentials
- `transcribeAudio()`: Converts audio file to text transcription
- `dispose()`: Cleans up resources

#### 2. `lib/data/datasource_impl/google_speech_service_impl.dart`
**Concrete Implementation** - Handles the actual Google Speech-to-Text API calls.

**Key Features:**

1. **Authentication**
   - Uses service account credentials from `assets/google_credentials.json`
   - Implements OAuth 2.0 authentication via `googleapis_auth` package
   - Requires `SpeechApi.cloudPlatformScope` permission

2. **Initialization Process**
   ```dart
   Future<void> initialize() async {
     // Load credentials from assets
     final credentialsJson = await rootBundle.loadString(_credentialsPath);
     final credentialsMap = json.decode(credentialsJson);
     final credentials = ServiceAccountCredentials.fromJson(credentialsMap);
     
     // Create authenticated client
     final client = await clientViaServiceAccount(credentials, [
       SpeechApi.cloudPlatformScope,
     ]);
     
     // Initialize Speech API
     _speechApi = SpeechApi(client);
   }
   ```

3. **Transcription Process**
   - **File Validation**: Checks if audio file exists and size (max 10MB)
   - **Audio Encoding**: Detects encoding format from file extension:
     - `.wav` → `LINEAR16`
     - `.flac` → `FLAC`
     - `.ogg` → `OGG_OPUS`
     - `.amr` → `AMR`
     - `.mp3` → `MP3`
   - **Base64 Encoding**: Converts audio bytes to base64 for API transmission
   - **Recognition Config**: Configures:
     - Encoding format
     - Sample rate (default: 44100 Hz)
     - Language code (default: `en-US`)
     - Alternative language codes for better detection
     - Automatic punctuation
     - Model: `default`
   - **API Request**: Sends `RecognizeRequest` to Google Speech API
   - **Response Parsing**: Extracts transcript from first result alternative

4. **Error Handling**
   - File not found errors
   - File size validation (10MB limit)
   - Empty transcription results
   - API initialization failures

#### 3. `lib/data/datasource_impl/transcription_datasource_impl.dart`
**Wrapper Implementation** - Combines Google Speech-to-Text with local speech recognition for language detection.

**Key Features:**

1. **Dual Initialization**
   - Initializes Google Speech Service (primary transcription)
   - Initializes local `speech_to_text` package (for language detection only)

2. **Multi-Language Support**
   Default alternative languages:
   ```dart
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

3. **Language Detection**
   - Uses local `speech_to_text` package to get available languages
   - Helps with better language detection in Google API

#### 4. `lib/data/datasources_contracts/transcription_datasource.dart`
**Abstract Interface** - Defines transcription data source contract.

```dart
abstract class TranscriptionDataSource {
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  });
  Future<bool> initialize();
  Future<List<stt.LocaleName>> getAvailableLanguages();
}
```

### Dependencies
- `googleapis/speech/v1.dart`: Google Speech-to-Text API client
- `googleapis_auth/auth_io.dart`: OAuth 2.0 authentication
- `speech_to_text`: Local speech recognition (for language detection)

### Configuration Requirements
1. **Service Account Credentials**
   - File: `assets/google_credentials.json`
   - Must have Speech-to-Text API enabled
   - Requires `Cloud Platform` scope

2. **API Setup**
   - Enable Google Cloud Speech-to-Text API in Google Cloud Console
   - Create service account with appropriate permissions
   - Download JSON credentials file

---

## Google Gemini API

### Purpose
Processes text transcriptions to generate:
- **Structured Notes**: Title, bullet points, tags, summary
- **Payment Information**: Amount, currency, due date, category, recurring settings

### Implementation Files

#### 1. `lib/core/config/app_config.dart`
**Configuration** - Stores Gemini API credentials and model selection.

```dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_API_KEY';
  static const String geminiModel = 'gemini-2.5-flash';
}
```

**Available Models:**
- `gemini-2.5-flash` (recommended): Balanced speed and intelligence
- `gemini-2.5-pro`: High capability for complex reasoning
- `gemini-2.0-flash`: Workhorse model
- `gemini-2.5-flash-lite`: Fast and cost-efficient
- `gemini-2.0-flash-lite`: Smaller, cost-efficient

#### 2. `lib/data/datasources_contracts/llm_datasource.dart`
**Abstract Interface** - Defines LLM data source contract for note processing.

```dart
abstract class LLMDataSource {
  Future<ProcessedNote> processTranscription(String transcription);
}
```

#### 3. `lib/data/datasource_impl/llm_datasource_impl.dart`
**Note Processing Implementation** - Processes transcriptions into structured notes.

**Key Features:**

1. **Model Initialization**
   ```dart
   _model = GenerativeModel(
     model: AppConfig.geminiModel,
     apiKey: AppConfig.geminiApiKey,
   );
   ```

2. **Prompt Engineering**
   - **Language Detection**: Automatically detects transcription language (English, Arabic, German)
   - **Structured Output**: Requests JSON response with:
     - `title`: Concise, descriptive title (3-7 words)
     - `bulletPoints`: 3-7 key points extracted from transcription
     - `tags`: 3-7 relevant hashtags
     - `summary`: 1-2 sentence summary
   - **Language Consistency**: Ensures all fields use the same language as transcription

3. **Generation Configuration**
   ```dart
   GenerationConfig(
     temperature: 0.3,  // Lower = more focused, deterministic
     topK: 40,          // Consider top 40 tokens
     topP: 0.95,        // Nucleus sampling threshold
   )
   ```

4. **Response Parsing**
   - Removes markdown code blocks (```json)
   - Extracts JSON from response
   - Handles both `bulletPoints` and `bullet_points` field names
   - Fallback to transcription if parsing fails

5. **Fallback Models**
   If primary model fails (quota, not found, etc.), tries:
   ```dart
   [
     'gemini-2.5-flash',
     'gemini-2.0-flash',
     'gemini-2.5-flash-lite',
     'gemini-2.0-flash-lite',
     'gemini-2.5-pro',
   ]
   ```

6. **Language Detection Algorithm**
   - **Arabic**: Detects Arabic Unicode characters (40% threshold)
   - **German**: Pattern matching for common German words
   - **English**: Pattern matching for common English words
   - **Default**: Falls back to English

7. **Error Handling**
   - Timeout: 60 seconds
   - Quota exceeded: Tries fallback models
   - Empty responses: Throws exception
   - Invalid API key: Clear error message

#### 4. `lib/data/datasources/payment_llm_datasource.dart`
**Abstract Interface** - Defines payment processing contract.

```dart
abstract class PaymentLLMDataSource {
  Future<List<ProcessedPayment>> processPaymentTranscription(
    String transcription,
  );
}
```

#### 5. `lib/data/datasources/payment_llm_datasource_impl.dart`
**Payment Processing Implementation** - Extracts payment information from transcriptions.

**Key Features:**

1. **Payment Extraction**
   Extracts structured payment data:
   - `title`: Payment description
   - `amount`: Numeric value
   - `currency`: Currency code (USD, EUR, EGP, etc.)
   - `dueDate`: ISO format date (YYYY-MM-DD)
   - `category`: Predefined category (Utilities, Housing, Food, etc.)
   - `type`: `toPay` or `toReceive`
   - `isRecurring`: Boolean
   - `recurringFrequency`: `monthly`, `weekly`, `yearly`, or `null`
   - `notificationDays`: Array of days before due date for notifications

2. **Date Parsing**
   Handles various date formats:
   - "on December 3rd" → `2025-12-03`
   - "on the 3rd" → Current month, 3rd day
   - "tomorrow" → Next day
   - "next week" → 7 days from now
   - "each month on the 3rd" → Recurring monthly

3. **Multiple Payments**
   Can extract multiple payments from single transcription:
   ```json
   [
     {"title": "Salary", "amount": 15000, ...},
     {"title": "Landline Bill", "amount": 100, ...},
     {"title": "Groceries", "amount": 3000, ...}
   ]
   ```

4. **Recurring Payment Logic**
   - Detects recurring patterns: "each month", "monthly", "every month"
   - Calculates next occurrence if date is in the past
   - Handles edge cases (e.g., Feb 31 → Feb 28/29)

5. **Category Detection**
   Auto-detects from context:
   - "bill", "electric", "water" → Utilities
   - "rent", "mortgage" → Housing
   - "salary", "income" → Income
   - "food", "groceries" → Food
   - etc.

### Dependencies
- `google_generative_ai`: Google Gemini API client

### Configuration Requirements
1. **API Key**
   - Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Store in `AppConfig.geminiApiKey`
   - **Security Note**: For production, use environment variables or secure storage

2. **Model Selection**
   - Choose appropriate model based on:
     - Speed requirements
     - Cost constraints
     - Complexity of tasks

---

## Architecture & Flow

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│      Presentation Layer                 │
│  (Cubits, Screens, Widgets)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Domain Layer                       │
│  (Use Cases, Entities, Repositories)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Data Layer                         │
│  (Data Sources, Repository Impl)        │
└─────────────────────────────────────────┘
```

### Complete Flow: Recording → Note

1. **User Records Audio**
   ```
   RecordingCubit.startRecording()
   → StartRecordingUseCase
   → AudioRepository.startRecording()
   → AudioLocalDataSource.startRecording()
   ```

2. **User Stops Recording**
   ```
   RecordingCubit.stopRecording()
   → StopRecordingUseCase
   → AudioRepository.stopRecording()
   → Creates Recording entity
   ```

3. **Transcribe Audio**
   ```
   RecordingCubit._processRecording()
   → TranscribeAudioUseCase
   → AudioRepository.transcribeAudio()
   → TranscriptionDataSource.transcribeAudio()
   → GoogleSpeechServiceImpl.transcribeAudio()
   → Google Speech-to-Text API
   → Returns transcription string
   ```

4. **Process Transcription**
   ```
   RecordingCubit._processRecording()
   → ProcessTranscriptionUseCase
   → AudioRepository.processTranscription()
   → LLMDataSource.processTranscription()
   → LLMDataSourceImpl.processTranscription()
   → Google Gemini API
   → Returns ProcessedNote (title, bullets, tags, summary)
   ```

5. **Create Note**
   ```
   RecordingCubit.createNoteWithFormat()
   → CreateNoteUseCase
   → NotesRepository.createNote()
   → Note saved to local storage
   ```

### Complete Flow: Recording → Payment

1. **User Records Payment Audio**
   - Same recording flow as above

2. **Transcribe Audio**
   - Same transcription flow as above

3. **Process Payment Transcription**
   ```
   PaymentsCubit.processTranscription()
   → ProcessPaymentTranscriptionUseCase
   → PaymentsRepository.processPaymentTranscription()
   → PaymentLLMDataSource.processPaymentTranscription()
   → PaymentLLMDataSourceImpl.processPaymentTranscription()
   → Google Gemini API
   → Returns List<ProcessedPayment>
   ```

4. **Create Payments**
   ```
   PaymentsCubit.createPayments()
   → CreatePaymentUseCase (for each payment)
   → PaymentsRepository.createPayment()
   → Payment saved to local storage
   ```

---

## File Structure

### Google Speech-to-Text Files

```
lib/
├── data/
│   ├── datasources_contracts/
│   │   ├── google_speech_service.dart          # Abstract interface
│   │   └── transcription_datasource.dart      # Abstract interface
│   └── datasource_impl/
│       ├── google_speech_service_impl.dart      # Google API implementation
│       └── transcription_datasource_impl.dart  # Wrapper implementation
├── domain/
│   ├── repositories/
│   │   └── audio_repository.dart               # Repository contract
│   └── usecases/
│       └── transcribe_audio_usecase.dart       # Use case
└── data/
    └── repositories/
        └── audio_repository_impl.dart           # Repository implementation
```

### Gemini API Files

```
lib/
├── core/
│   └── config/
│       └── app_config.dart                     # API key & model config
├── data/
│   ├── datasources_contracts/
│   │   └── llm_datasource.dart                 # Abstract interface
│   ├── datasource_impl/
│   │   └── llm_datasource_impl.dart            # Note processing
│   └── datasources/
│       ├── payment_llm_datasource.dart          # Payment interface
│       └── payment_llm_datasource_impl.dart    # Payment processing
├── domain/
│   ├── repositories/
│   │   └── audio_repository.dart               # Repository contract
│   └── usecases/
│       ├── process_transcription_usecase.dart  # Note processing use case
│       └── payments/
│           └── process_payment_transcription_usecase.dart  # Payment use case
└── data/
    └── repositories/
        └── audio_repository_impl.dart           # Repository implementation
```

---

## Configuration

### Google Speech-to-Text Setup

1. **Create Service Account**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to IAM & Admin → Service Accounts
   - Create new service account
   - Grant "Cloud Speech Client" role

2. **Generate Credentials**
   - Create JSON key for service account
   - Download credentials file
   - Place in `assets/google_credentials.json`

3. **Enable API**
   - Enable "Cloud Speech-to-Text API" in API Library
   - Ensure billing is enabled (free tier available)

4. **Update pubspec.yaml**
   ```yaml
   assets:
     - assets/google_credentials.json
   ```

### Gemini API Setup

1. **Get API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create new API key
   - Copy API key

2. **Configure in Code**
   ```dart
   // lib/core/config/app_config.dart
   static const String geminiApiKey = 'YOUR_API_KEY_HERE';
   static const String geminiModel = 'gemini-2.5-flash';
   ```

3. **Security Best Practices**
   - **DO NOT** commit API keys to version control
   - Use environment variables in production
   - Consider using Flutter's `flutter_dotenv` package
   - Store keys in secure storage (e.g., `flutter_secure_storage`)

---

## Error Handling

### Exception Types

#### Speech-to-Text Exceptions
- `TranscriptionException`: General transcription failures
- `Exception`: File not found, size exceeded, API errors

#### Gemini API Exceptions
- `LLMProcessingException`: General AI processing failures
- `GenerativeAIException`: API-specific errors (quota, model not found)
- `GeminiAPIException`: Wrapper for Gemini-specific errors

### Error Handling Strategy

1. **Transcription Errors**
   ```dart
   try {
     final transcription = await transcribeAudio(audioPath);
   } on TranscriptionException catch (e) {
     // Handle transcription-specific errors
     return Left(TranscriptionFailure(e.message));
   } catch (e) {
     // Handle unexpected errors
     return Left(TranscriptionFailure('Unexpected error: $e'));
   }
   ```

2. **Gemini API Errors**
   ```dart
   try {
     final response = await _model.generateContent([...]);
   } on GenerativeAIException catch (e) {
     if (e.message.contains('quota')) {
       // Try fallback models
       return _tryWithFallbackModels(...);
     }
     rethrow;
   }
   ```

3. **Fallback Mechanisms**
   - **Transcription**: If Google API fails, returns empty transcription (user can still create note)
   - **AI Processing**: If primary model fails, tries fallback models
   - **Parsing**: If JSON parsing fails, uses transcription as fallback

### Common Error Scenarios

1. **Audio File Too Large**
   - Error: "Audio file is too large (X MB). Maximum size is 10MB."
   - Solution: Record shorter audio or compress file

2. **No Transcription Results**
   - Error: "No transcription results returned from Google Speech API."
   - Causes: Silent audio, poor quality, wrong language
   - Solution: Check audio quality, verify language settings

3. **API Quota Exceeded**
   - Error: "Quota exceeded" or "Quota exceeded"
   - Solution: Check API quota limits, enable billing, wait for reset

4. **Invalid API Key**
   - Error: "Invalid Gemini API key" or "authentication"
   - Solution: Verify API key in `AppConfig`, check key permissions

5. **Model Not Found**
   - Error: "not found" or "not supported"
   - Solution: Check model name in `AppConfig`, try fallback models

---

## Usage Examples

### Example 1: Transcribe Audio

```dart
// In RecordingCubit
final transcriptionResult = await transcribeAudioUseCase(
  TranscribeAudioParams(
    audioPath: recording.audioPath,
    languageCode: 'en-US',  // Optional
    alternativeLanguageCodes: ['ar-EG', 'fr-FR'],  // Optional
  ),
);

transcriptionResult.fold(
  (failure) => print('Error: ${failure.message}'),
  (transcription) => print('Transcription: $transcription'),
);
```

### Example 2: Process Transcription to Note

```dart
// In RecordingCubit
final processingResult = await processTranscriptionUseCase(
  ProcessTranscriptionParams(transcription),
);

processingResult.fold(
  (failure) => print('Error: ${failure.message}'),
  (processedNote) {
    print('Title: ${processedNote.title}');
    print('Bullet Points: ${processedNote.bulletPoints}');
    print('Tags: ${processedNote.tags}');
    print('Summary: ${processedNote.summary}');
  },
);
```

### Example 3: Process Payment Transcription

```dart
// In PaymentsCubit
final result = await processPaymentTranscriptionUseCase(
  ProcessPaymentTranscriptionParams(transcription),
);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (payments) {
    for (final payment in payments) {
      print('Title: ${payment.title}');
      print('Amount: ${payment.amount} ${payment.currency}');
      print('Due Date: ${payment.dueDate}');
      print('Category: ${payment.category}');
      print('Recurring: ${payment.isRecurring}');
    }
  },
);
```

### Example 4: Direct API Usage (Not Recommended)

```dart
// Direct Google Speech Service usage
final speechService = GoogleSpeechServiceImpl();
await speechService.initialize();

final transcription = await speechService.transcribeAudio(
  '/path/to/audio.wav',
  languageCode: 'en-US',
  alternativeLanguageCodes: ['ar-EG'],
  sampleRateHertz: 44100,
);

print('Transcription: $transcription');
speechService.dispose();
```

```dart
// Direct Gemini API usage
final model = GenerativeModel(
  model: 'gemini-2.5-flash',
  apiKey: 'YOUR_API_KEY',
);

final response = await model.generateContent([
  Content.text('Process this transcription: $transcription'),
]);

print('Response: ${response.text}');
```

---

## Best Practices

### Security
1. **Never commit API keys** to version control
2. **Use environment variables** for production
3. **Rotate API keys** regularly
4. **Monitor API usage** to detect unauthorized access

### Performance
1. **Cache transcriptions** when possible
2. **Batch API calls** if processing multiple items
3. **Use appropriate models** (flash for speed, pro for accuracy)
4. **Implement retry logic** for transient failures

### Error Handling
1. **Always provide fallbacks** (e.g., use transcription if AI fails)
2. **Log errors** for debugging
3. **Show user-friendly messages** instead of technical errors
4. **Handle network timeouts** appropriately

### Code Organization
1. **Follow Clean Architecture** principles
2. **Use dependency injection** (Injectable/GetIt)
3. **Separate concerns** (data, domain, presentation)
4. **Write unit tests** for critical paths

---

## Troubleshooting

### Issue: Transcription returns empty
**Possible Causes:**
- Silent or very short audio
- Poor audio quality
- Wrong language code
- API quota exceeded

**Solutions:**
- Check audio file quality
- Verify language settings
- Check API quota limits
- Test with known good audio file

### Issue: Gemini API returns invalid JSON
**Possible Causes:**
- Model returns markdown instead of JSON
- Response truncated
- Model hallucination

**Solutions:**
- Check prompt engineering
- Implement robust JSON parsing
- Use fallback parsing logic
- Try different model

### Issue: API quota exceeded
**Possible Causes:**
- Too many requests
- Free tier limits reached
- Billing not enabled

**Solutions:**
- Enable billing in Google Cloud Console
- Check quota limits
- Implement rate limiting
- Use fallback models

---

## Additional Resources

- [Google Speech-to-Text API Documentation](https://cloud.google.com/speech-to-text/docs)
- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Clean Architecture Guide](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Dependency Injection with Injectable](https://pub.dev/packages/injectable)

---

## Summary

This project implements a sophisticated voice-to-text-to-structured-data pipeline:

1. **Audio Recording** → Local file storage
2. **Google Speech-to-Text** → Text transcription
3. **Google Gemini API** → Structured data (notes/payments)
4. **Local Storage** → Save processed data

The architecture ensures:
- **Separation of concerns** (Clean Architecture)
- **Testability** (Dependency injection)
- **Maintainability** (Repository pattern)
- **Reliability** (Error handling, fallbacks)
- **Scalability** (Modular design)

Both APIs are integrated seamlessly with proper error handling, fallback mechanisms, and user-friendly error messages.

