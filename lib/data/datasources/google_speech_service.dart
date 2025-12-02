import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Service class for Google Speech-to-Text API integration
class GoogleSpeechService {
  static const String _credentialsPath = 'assets/google_credentials.json';
  SpeechApi? _speechApi;
  bool _isInitialized = false;

  /// Initialize the Google Speech-to-Text API client
  Future<void> initialize() async {
    if (_isInitialized && _speechApi != null) return;

    try {
      // Load credentials from assets
      final credentialsJson = await rootBundle.loadString(_credentialsPath);
      final credentialsMap =
          json.decode(credentialsJson) as Map<String, dynamic>;

      // Create service account credentials
      final credentials = ServiceAccountCredentials.fromJson(credentialsMap);

      // Create authenticated HTTP client
      final client = await clientViaServiceAccount(credentials, [
        SpeechApi.cloudPlatformScope,
      ]);

      // Initialize Speech API
      _speechApi = SpeechApi(client);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Google Speech-to-Text: $e');
    }
  }

  /// Transcribe an audio file using Google Speech-to-Text API
  ///
  /// [audioPath] - Path to the audio file
  /// [languageCode] - Primary language code (e.g., 'en-US', 'ar-EG', 'fr-FR', 'es-ES', 'de-DE', 'ja-JP', 'zh-CN', etc.)
  ///                   If null, Google will auto-detect the language. Defaults to null for auto-detection.
  /// [alternativeLanguageCodes] - Optional list of alternative languages to try if auto-detecting
  ///                               Common languages: ['en-US', 'ar-EG', 'fr-FR', 'es-ES', 'de-DE', 'it-IT', 'pt-BR', 'ru-RU', 'ja-JP', 'zh-CN', 'ko-KR', 'hi-IN']
  /// [sampleRateHertz] - Sample rate of the audio. Defaults to 44100
  ///
  /// Returns the transcribed text
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

    try {
      // Read audio file
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      final audioBytes = await audioFile.readAsBytes();

      // Check file size (Google Speech-to-Text has a 10MB limit for recognize API)
      // Files larger than 10MB need to use long_running_recognize
      const maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
      if (audioBytes.length > maxFileSize) {
        throw Exception(
          'Audio file is too large (${(audioBytes.length / 1024 / 1024).toStringAsFixed(2)}MB). '
          'Maximum size is 10MB. Please record a shorter audio.',
        );
      }

      final audioBase64 = base64Encode(audioBytes);

      // Determine encoding based on file extension
      final encoding = _getEncodingFromFile(audioPath);

      // Create recognition config with language support
      final config = RecognitionConfig(
        encoding: encoding,
        sampleRateHertz: sampleRateHertz,
        languageCode: languageCode ?? 'en-US',
        alternativeLanguageCodes: alternativeLanguageCodes,
        enableAutomaticPunctuation: true,
        model: 'default',
      );

      // Create recognition audio
      final audio = RecognitionAudio(content: audioBase64);

      // Create recognition request
      final request = RecognizeRequest(config: config, audio: audio);

      // Perform recognition
      final response = await _speechApi!.speech.recognize(request);

      // Extract transcription from response
      if (response.results == null || response.results!.isEmpty) {
        throw Exception(
          'No transcription results returned from Google Speech API. '
          'Please check: audio length, quality, and language settings.',
        );
      }

      // Get the first result (most confident)
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
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Transcription failed: $e');
    }
  }

  /// Get the appropriate encoding type based on file extension
  String? _getEncodingFromFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    switch (extension) {
      case 'wav':
        // WAV files use LINEAR16 encoding (PCM)
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
        // M4A/MP4 files are not directly supported
        // Should not happen if recording is set to WAV
        return null;
      default:
        // For unknown formats, let Google auto-detect
        return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _speechApi = null;
    _isInitialized = false;
  }
}
