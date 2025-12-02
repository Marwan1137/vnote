import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../datasources_contracts/google_speech_service.dart';

class GoogleSpeechServiceImpl implements GoogleSpeechService {
  static const String _credentialsPath = 'assets/google_credentials.json';
  SpeechApi? _speechApi;
  bool _isInitialized = false;

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

      final audioBase64 = base64Encode(audioBytes);

      final encoding = _getEncodingFromFile(audioPath);

      final config = RecognitionConfig(
        encoding: encoding,
        sampleRateHertz: sampleRateHertz,
        languageCode: languageCode ?? 'en-US',
        alternativeLanguageCodes: alternativeLanguageCodes,
        enableAutomaticPunctuation: true,
        model: 'default',
      );

      final audio = RecognitionAudio(content: audioBase64);

      final request = RecognizeRequest(config: config, audio: audio);

      final response = await _speechApi!.speech.recognize(request);

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
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Transcription failed: $e');
    }
  }

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

  @override
  void dispose() {
    _speechApi = null;
    _isInitialized = false;
  }
}
