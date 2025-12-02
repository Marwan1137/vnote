import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';
import '../../core/errors/exceptions.dart';
import '../datasources_contracts/audio_local_datasource.dart';

@LazySingleton(as: AudioLocalDataSource)
class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  @override
  Future<String> startRecording() async {
    try {
      if (!await checkPermission()) {
        throw AudioPermissionException('Microphone permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${audioDir.path}/recording_$timestamp.wav';

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
            numChannels: 1,
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
      return false;
    }

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
