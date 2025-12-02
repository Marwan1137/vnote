import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';
import '../../core/errors/exceptions.dart';

abstract class AudioLocalDataSource {
  Future<String> startRecording();
  Future<String> stopRecording();
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<void> cancelRecording();
  Future<bool> openAppSettings();
}

@LazySingleton(as: AudioLocalDataSource)
class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  @override
  Future<String> startRecording() async {
    try {
      // Check permission first
      if (!await checkPermission()) {
        throw AudioPermissionException('Microphone permission denied');
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Generate file path
      // Use WAV format (LINEAR16) for best compatibility with Google Speech-to-Text API
      // WAV is supported on all platforms and is the recommended format for speech recognition
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${audioDir.path}/recording_$timestamp.wav';

      // Start recording
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            // Use WAV encoder - this produces LINEAR16 format which Google Speech-to-Text supports
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
            numChannels: 1, // Mono channel - better for speech recognition
            // Note: bitRate is not used for WAV (it's uncompressed PCM)
          ),
          path: filePath,
        );
        _currentRecordingPath = filePath;
        return filePath;
      } else {
        throw AudioPermissionException('Microphone permission denied');
      }
    } catch (e) {
      if (e is AudioPermissionException) rethrow;
      throw RecordingException('Failed to start recording: $e');
    }
  }

  @override
  Future<String> stopRecording() async {
    try {
      if (_currentRecordingPath == null) {
        throw RecordingException('No active recording');
      }

      final path = await _audioRecorder.stop();
      final recordingPath = _currentRecordingPath!;
      _currentRecordingPath = null;

      if (path == null || path.isEmpty) {
        throw RecordingException('Failed to stop recording');
      }

      return recordingPath;
    } catch (e) {
      if (e is RecordingException) rethrow;
      throw RecordingException('Failed to stop recording: $e');
    }
  }

  @override
  Future<bool> checkPermission() async {
    final status = await ph.Permission.microphone.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final status = await ph.Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // Permission is permanently denied, user needs to go to settings
      return false;
    }

    // Request permission
    final newStatus = await ph.Permission.microphone.request();
    return newStatus.isGranted;
  }

  @override
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  @override
  Future<void> cancelRecording() async {
    try {
      if (_currentRecordingPath != null) {
        await _audioRecorder.stop();
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      // Ignore errors when canceling
    }
  }
}
