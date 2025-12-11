# Google Speech-to-Text Service Implementation

## File Overview

**File Path:** `lib/data/datasource_impl/google_speech_service_impl.dart`

**Purpose:** This file implements the `GoogleSpeechService` interface, providing a concrete implementation that interacts with Google Cloud Speech-to-Text API. It handles audio file transcription by converting audio recordings into text transcriptions with support for multiple languages and automatic language detection.

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It acts as the boundary between the application's domain logic and Google's Speech-to-Text API service. It handles authentication, audio encoding, API requests, and response parsing.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - RecordingCubit                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)          │
│   - TranscribeAudioUseCase          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - AudioRepositoryImpl             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - TranscriptionDataSourceImpl      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Service)               │
│   - GoogleSpeechServiceImpl          │ ← This file
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   External Service                   │
│   - Google Cloud Speech-to-Text API  │
└─────────────────────────────────────┘
```

## Dependencies

### External Packages
- **`googleapis/speech/v1.dart`**: Google Cloud Speech-to-Text API client library. Provides the `SpeechApi` class and all request/response types.
- **`googleapis_auth/auth_io.dart`**: OAuth 2.0 authentication library for Google APIs. Provides `ServiceAccountCredentials` and `clientViaServiceAccount` for service account authentication.
- **`flutter/services.dart`**: Flutter services for loading assets. Used to load service account credentials JSON file.

### Internal Dependencies
- **`GoogleSpeechService`**: Abstract interface defining the contract this class implements.

## Detailed Code Walkthrough

### Class Declaration and State

```dart
class GoogleSpeechServiceImpl implements GoogleSpeechService {
  static const String _credentialsPath = 'assets/google_credentials.json';
  SpeechApi? _speechApi;
  bool _isInitialized = false;
```

**Why Class-Level State?**

1. **`_credentialsPath`:** 
   - Constant path to service account credentials file.
   - Stored in `assets/` directory and loaded at runtime.
   - Made `static const` because it never changes.

2. **`_speechApi`:**
   - Holds the initialized `SpeechApi` instance.
   - Nullable because it's only set after successful initialization.
   - Reused across multiple transcription calls for efficiency.

3. **`_isInitialized`:**
   - Boolean flag to track initialization status.
   - Prevents redundant initialization calls.
   - Used for lazy initialization pattern.

**Why Not Singleton?**
- This class is instantiated per-use (not a singleton).
- However, the `_speechApi` instance is reused once created.
- This allows for proper resource management while avoiding repeated initialization.

### Initialization Method

```dart
@override
Future<void> initialize() async {
  if (_isInitialized && _speechApi != null) return;

  try {
    final credentialsJson = await rootBundle.loadString(_credentialsPath);
    final credentialsMap =
        json.decode(credentialsJson) as Map<String, dynamic>;

    final credentials = ServiceAccountCredentials.fromJson(credentialsMap);

    final client = await clientViaServiceAccount(credentials, [
      SpeechApi.cloudPlatformScope,
    ]);

    _speechApi = SpeechApi(client);
    _isInitialized = true;
  } catch (e) {
    throw Exception('Failed to initialize Google Speech-to-Text: $e');
  }
}
```

**Step-by-Step Breakdown:**

1. **Early Return Check:**
   ```dart
   if (_isInitialized && _speechApi != null) return;
   ```
   - **Why?** Prevents redundant initialization.
   - **Performance:** Avoids reloading credentials and creating new API client.
   - **Idempotency:** Safe to call `initialize()` multiple times.

2. **Load Credentials File:**
   ```dart
   final credentialsJson = await rootBundle.loadString(_credentialsPath);
   ```
   - **`rootBundle`:** Flutter's asset loading mechanism.
   - **Why async?** Asset loading is asynchronous.
   - **File Location:** Must be in `assets/` directory and declared in `pubspec.yaml`.

3. **Parse JSON:**
   ```dart
   final credentialsMap = json.decode(credentialsJson) as Map<String, dynamic>;
   ```
   - **Why decode?** Credentials file is JSON, needs parsing.
   - **Type Cast:** Explicitly casts to `Map<String, dynamic>` for type safety.

4. **Create Credentials Object:**
   ```dart
   final credentials = ServiceAccountCredentials.fromJson(credentialsMap);
   ```
   - **Service Account:** Uses service account authentication (not user OAuth).
   - **Why Service Account?** Server-to-server authentication, no user interaction needed.
   - **From JSON:** Factory constructor parses the credentials map.

5. **Create Authenticated Client:**
   ```dart
   final client = await clientViaServiceAccount(credentials, [
     SpeechApi.cloudPlatformScope,
   ]);
   ```
   - **`clientViaServiceAccount`:** Creates an authenticated HTTP client.
   - **Scopes:** `SpeechApi.cloudPlatformScope` grants access to Speech-to-Text API.
   - **Why async?** Authentication involves network calls to Google's servers.

6. **Create SpeechApi Instance:**
   ```dart
   _speechApi = SpeechApi(client);
   ```
   - **Wraps Client:** `SpeechApi` uses the authenticated client for API calls.
   - **Reusable:** This instance is used for all subsequent API calls.

7. **Error Handling:**
   ```dart
   catch (e) {
     throw Exception('Failed to initialize Google Speech-to-Text: $e');
   }
   ```
   - **Catches All Errors:** Network errors, file not found, invalid credentials, etc.
   - **Wraps in Exception:** Provides context about what failed.
   - **Preserves Error:** Includes original error message for debugging.

### Transcription Method

```dart
@override
Future<String> transcribeAudio(
  String audioPath, {
  String? languageCode,
  List<String>? alternativeLanguageCodes,
  int sampleRateHertz = 44100,
}) async {
  if (!_isInitialized) {
    await initialize();
  }

  if (_speechApi == null) {
    throw Exception('Speech API not initialized');
  }
```

**Method Signature Analysis:**

- **`audioPath`:** Path to the audio file on the device's file system.
- **`languageCode`:** Primary language code (e.g., `'en-US'`, `'ar-EG'`). Optional, defaults to `'en-US'`.
- **`alternativeLanguageCodes`:** List of alternative languages to try if primary fails. Helps with multilingual audio.
- **`sampleRateHertz`:** Audio sample rate. Default `44100` Hz (CD quality). Must match the actual audio file.

**Why Auto-Initialize?**
- **Lazy Initialization:** If not initialized, initialize automatically.
- **User-Friendly:** Calling code doesn't need to remember to initialize.
- **Flexible:** Supports both explicit and implicit initialization.

**Why Check `_speechApi` After Initialize?**
- Initialization might fail silently in some edge cases.
- Double-check ensures we have a valid API instance.
- Throws clear error if initialization somehow failed.

### Audio File Validation

```dart
try {
  final audioFile = File(audioPath);
  if (!await audioFile.exists()) {
    throw Exception('Audio file not found: $audioPath');
  }

  final audioBytes = await audioFile.readAsBytes();

  const maxFileSize = 10 * 1024 * 1024;
  if (audioBytes.length > maxFileSize) {
    throw Exception(
      'Audio file is too large (${(audioBytes.length / 1024 / 1024).toStringAsFixed(2)}MB). '
      'Maximum size is 10MB. Please record a shorter audio.',
    );
  }
```

**File Existence Check:**
- **Why?** Prevents API call with invalid file path.
- **Early Failure:** Fails fast with clear error message.
- **User-Friendly:** Tells user exactly which file is missing.

**Read Audio Bytes:**
- **Why Read Entire File?** Google API requires audio data in the request.
- **Memory Consideration:** For very large files, this loads entire file into memory.
- **Alternative:** Could use streaming for very large files, but 10MB limit makes this acceptable.

**File Size Validation:**
- **10MB Limit:** Google Speech-to-Text API has a 10MB limit for synchronous requests.
- **Why Check Client-Side?** Saves API call and provides immediate feedback.
- **User-Friendly Message:** Shows actual file size and limit.
- **Calculation:** Converts bytes to MB with 2 decimal places for readability.

**Why 10MB?**
- Google's API limit for synchronous recognition.
- Larger files require asynchronous processing (more complex).
- 10MB is reasonable for voice notes (approximately 1-2 minutes of audio).

### Base64 Encoding

```dart
final audioBase64 = base64Encode(audioBytes);
```

**Why Base64?**
- **API Requirement:** Google Speech-to-Text API expects audio data as base64-encoded string in JSON.
- **Text Format:** Base64 converts binary data to text, safe for JSON transmission.
- **Standard:** Common encoding for binary data in APIs.

**Performance Note:**
- Base64 encoding increases size by ~33%.
- For a 10MB file, this becomes ~13MB in the request.
- Still acceptable for API calls.

### Audio Encoding Detection

```dart
final encoding = _getEncodingFromFile(audioPath);
```

**Why Detect Encoding?**
- Google API needs to know the audio format to decode it correctly.
- Different formats require different decoding.
- File extension is used as a hint for the format.

**Encoding Method:**
```dart
String? _getEncodingFromFile(String filePath) {
  final extension = filePath.toLowerCase().split('.').last;

  switch (extension) {
    case 'wav':
      return 'LINEAR16';
    case 'flac':
      return 'FLAC';
    case 'ogg':
      return 'OGG_OPUS';
    case 'amr':
      return 'AMR';
    case 'amr-wb':
      return 'AMR_WB';
    case 'mp3':
      return 'MP3';
    case 'm4a':
    case 'mp4':
      return null;
    default:
      return null;
  }
}
```

**Supported Formats:**
- **WAV (LINEAR16):** Uncompressed, high quality. Common for recordings.
- **FLAC:** Lossless compression. Good quality, smaller than WAV.
- **OGG_OPUS:** Modern codec, good compression and quality.
- **AMR/AMR-WB:** Older mobile codecs. Still supported.
- **MP3:** Common format, widely supported.

**Why Return Null for Some Formats?**
- **M4A/MP4:** These are container formats, not specific audio codecs.
- **Unknown Extensions:** Can't determine encoding from extension alone.
- **API Behavior:** When `encoding` is null, Google API attempts auto-detection (less reliable).

**Why Lowercase Extension?**
- File extensions might be uppercase (`.WAV`).
- Converting to lowercase ensures consistent matching.
- Prevents case-sensitivity issues.

### Recognition Configuration

```dart
final config = RecognitionConfig(
  encoding: encoding,
  sampleRateHertz: sampleRateHertz,
  languageCode: languageCode ?? 'en-US',
  alternativeLanguageCodes: alternativeLanguageCodes,
  enableAutomaticPunctuation: true,
  model: 'default',
);
```

**Configuration Parameters:**

1. **`encoding`:** Audio format (detected from file extension).
2. **`sampleRateHertz`:** Audio sample rate. Must match actual audio file.
3. **`languageCode`:** Primary language. Defaults to `'en-US'` if not specified.
4. **`alternativeLanguageCodes`:** Alternative languages to try. Helps with:
   - Multilingual speakers
   - Accented speech
   - Language detection uncertainty
5. **`enableAutomaticPunctuation`:** Adds punctuation to transcription. Improves readability.
6. **`model`:** Speech recognition model. `'default'` is the standard model. Other options:
   - `'phone_call'`: Optimized for phone calls
   - `'command_and_search'`: For short commands
   - `'video'`: For video audio

**Why Default to 'en-US'?**
- Most common use case.
- Safe fallback if language not specified.
- English is widely supported.

**Why Enable Automatic Punctuation?**
- Improves transcription readability.
- Reduces post-processing needed.
- Better user experience.

### Recognition Audio and Request

```dart
final audio = RecognitionAudio(content: audioBase64);

final request = RecognizeRequest(config: config, audio: audio);
```

**RecognitionAudio:**
- **`content`:** Base64-encoded audio data.
- **Alternative:** Could use `uri` for Google Cloud Storage files (for larger files).

**RecognizeRequest:**
- Combines configuration and audio data.
- This is the complete request to send to Google API.

### API Call

```dart
final response = await _speechApi!.speech.recognize(request);
```

**Why `_speechApi!`?**
- We've already checked it's not null.
- The `!` operator asserts non-null (safe here).
- Makes intent clear to readers and linter.

**API Endpoint:**
- `speech.recognize()` calls the synchronous recognition endpoint.
- Returns results immediately (for files up to 10MB).
- For larger files, use `speech.longrunningrecognize()` (asynchronous).

### Response Validation

```dart
if (response.results == null || response.results!.isEmpty) {
  throw Exception(
    'No transcription results returned from Google Speech API. '
    'Please check: audio length, quality, and language settings.',
  );
}

final firstResult = response.results!.first;
if (firstResult.alternatives == null ||
    firstResult.alternatives!.isEmpty) {
  throw Exception('No transcription alternatives returned');
}

final transcription = firstResult.alternatives!.first.transcript ?? '';

if (transcription.isEmpty) {
  throw Exception('Transcription returned empty result');
}

return transcription;
```

**Why Multiple Validation Checks?**

1. **Results Check:**
   - API might return empty results array.
   - Could indicate: silent audio, unsupported format, language mismatch.
   - Provides helpful error message with possible causes.

2. **Alternatives Check:**
   - Each result contains alternatives (different confidence levels).
   - Should have at least one alternative.
   - Empty alternatives indicate API issue.

3. **Transcript Check:**
   - Even with alternatives, transcript might be empty.
   - Could indicate: very poor audio quality, complete silence.
   - Prevents returning empty string (which might be confusing).

4. **Return First Alternative:**
   - Google returns alternatives sorted by confidence.
   - First alternative is the most confident transcription.
   - Usually sufficient for most use cases.

**Why Not Use Other Alternatives?**
- First alternative is typically the best.
- If needed, could return all alternatives and let calling code choose.
- Current implementation prioritizes simplicity.

### Error Handling

```dart
} catch (e) {
  if (e is Exception) rethrow;
  throw Exception('Transcription failed: $e');
}
```

**Why Re-throw Existing Exceptions?**
- Our validation throws `Exception` with helpful messages.
- Re-throwing preserves those messages.
- Only wraps non-Exception errors (shouldn't happen, but defensive).

### Dispose Method

```dart
@override
void dispose() {
  _speechApi = null;
  _isInitialized = false;
}
```

**Purpose:**
- Cleans up resources when service is no longer needed.
- Resets state to allow re-initialization if needed.

**Why Not Dispose HTTP Client?**
- The HTTP client is managed by `googleapis_auth`.
- It handles its own cleanup.
- We just clear our reference to the API instance.

**When to Call:**
- When app is closing.
- When switching to different transcription service.
- Generally not needed in normal app lifecycle (service persists).

## Authentication: Service Account

### What is a Service Account?

A service account is a special Google account that represents an application, not a user. It's used for server-to-server authentication.

### Why Service Account for This App?

1. **No User Interaction:** Transcription happens automatically, no user login needed.
2. **Server-to-Server:** App talks directly to Google API, not on behalf of a user.
3. **Persistent Access:** Credentials don't expire (unlike user OAuth tokens).
4. **Quota Management:** Easier to manage API quotas per app.

### Service Account Setup

1. **Create Service Account:**
   - Go to Google Cloud Console.
   - Navigate to IAM & Admin > Service Accounts.
   - Create new service account.

2. **Grant Permissions:**
   - Grant "Cloud Speech-to-Text API User" role.
   - Or grant "Cloud Platform" scope (broader access).

3. **Create Key:**
   - Create JSON key for the service account.
   - Download the JSON file.

4. **Add to Project:**
   - Place JSON file in `assets/google_credentials.json`.
   - Add to `pubspec.yaml` assets section.

### Security Considerations

**Important:** Service account keys are **sensitive** and should be:

1. **Not Committed to Git:**
   - Add `assets/google_credentials.json` to `.gitignore`.
   - Use environment variables or secure storage in CI/CD.

2. **Restricted Access:**
   - Only grant minimum necessary permissions.
   - Use principle of least privilege.

3. **Rotate Regularly:**
   - Rotate keys periodically for security.
   - Update credentials file when rotated.

4. **Monitor Usage:**
   - Monitor API usage for anomalies.
   - Set up alerts for unusual activity.

## API Limits and Quotas

### File Size Limits

- **Synchronous (`recognize`):** 10MB maximum.
- **Asynchronous (`longrunningrecognize`):** 10GB maximum (requires different implementation).

### Rate Limits

- **Requests per minute:** Varies by quota tier.
- **Free tier:** Limited requests per day.
- **Paid tier:** Higher limits, pay-per-use.

### Best Practices

1. **Validate File Size:** Check before API call (as we do).
2. **Handle Rate Limits:** Implement retry with exponential backoff.
3. **Monitor Quota:** Track usage to avoid hitting limits.
4. **Error Handling:** Gracefully handle quota exceeded errors.

## Language Support

### Supported Languages

Google Speech-to-Text supports 100+ languages. Common ones include:

- **English:** `en-US`, `en-GB`, `en-AU`
- **Arabic:** `ar-EG`, `ar-SA`, `ar-AE`
- **Spanish:** `es-ES`, `es-MX`, `es-AR`
- **French:** `fr-FR`, `fr-CA`
- **German:** `de-DE`
- **And many more...**

### Language Detection

The API can attempt automatic language detection, but it's more reliable to:

1. **Specify Primary Language:** Use `languageCode` parameter.
2. **Provide Alternatives:** Use `alternativeLanguageCodes` for multilingual audio.
3. **Use Local Detection:** Some apps detect language locally before calling API.

### Alternative Language Codes

```dart
alternativeLanguageCodes: [
  'en-US',  // English (US)
  'ar-EG',  // Arabic (Egypt)
  'fr-FR',  // French
  'es-ES',  // Spanish
  // ... more languages
]
```

**Why Multiple Alternatives?**
- User might speak multiple languages.
- Helps with accented speech.
- Improves accuracy for multilingual content.

## Error Scenarios and Handling

### Common Errors

1. **File Not Found:**
   - **Cause:** Invalid file path.
   - **Handling:** Check file exists before API call (as we do).

2. **File Too Large:**
   - **Cause:** File exceeds 10MB limit.
   - **Handling:** Validate size and show user-friendly error.

3. **Invalid Credentials:**
   - **Cause:** Service account key is invalid or expired.
   - **Handling:** Clear error message, guide user to check credentials.

4. **Quota Exceeded:**
   - **Cause:** API quota limit reached.
   - **Handling:** Show user-friendly message, suggest retry later.

5. **Network Error:**
   - **Cause:** No internet connection or API unreachable.
   - **Handling:** Retry with exponential backoff.

6. **Empty Transcription:**
   - **Cause:** Silent audio, poor quality, or language mismatch.
   - **Handling:** Validate response and provide helpful error message.

## Testing Considerations

### What Should Be Tested

1. **Initialization:**
   - Successful initialization with valid credentials.
   - Failure with invalid credentials.
   - Idempotency (multiple calls).

2. **Transcription:**
   - Successful transcription with valid audio.
   - Error handling for missing file.
   - Error handling for oversized file.
   - Error handling for empty transcription.

3. **Encoding Detection:**
   - Correct encoding for each file format.
   - Null handling for unknown formats.

4. **Error Scenarios:**
   - Network errors.
   - API errors.
   - Invalid responses.

### Mocking for Tests

```dart
// Example test structure
test('transcribeAudio returns transcription for valid audio', () async {
  // Arrange: Mock SpeechApi
  final mockSpeechApi = MockSpeechApi();
  final service = GoogleSpeechServiceImpl();
  // ... setup mocks
  
  // Act
  final result = await service.transcribeAudio('test.wav');
  
  // Assert
  expect(result, isNotEmpty);
});
```

## Future Improvements

1. **Asynchronous Processing:**
   - Support for files > 10MB using `longrunningrecognize`.
   - Poll for results, handle callbacks.

2. **Streaming Recognition:**
   - Real-time transcription during recording.
   - Use streaming API endpoint.

3. **Caching:**
   - Cache transcriptions for same audio file.
   - Reduce API calls and costs.

4. **Retry Logic:**
   - Automatic retry with exponential backoff.
   - Handle transient errors gracefully.

5. **Progress Callbacks:**
   - Report transcription progress to UI.
   - Better user experience for long audio.

6. **Multiple Alternatives:**
   - Return all alternatives, not just first.
   - Let calling code choose best one.

7. **Language Auto-Detection:**
   - Detect language before API call.
   - Use local detection libraries.

8. **Audio Preprocessing:**
   - Normalize audio levels.
   - Remove noise.
   - Improve transcription accuracy.

## Summary

The `GoogleSpeechServiceImpl` provides a robust interface to Google Cloud Speech-to-Text API:

- **Handles Authentication:** Service account authentication with proper scopes.
- **Validates Input:** File existence, size, and format validation.
- **Supports Multiple Languages:** Primary and alternative language codes.
- **Error Handling:** Comprehensive error handling with user-friendly messages.
- **Resource Management:** Proper initialization and disposal.
- **Type Safety:** Strong typing throughout.

This implementation ensures reliable audio transcription while handling edge cases and providing clear error messages for debugging and user feedback.
