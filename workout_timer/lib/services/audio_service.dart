import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _soundEnabled = true;

  // Cache file paths for paplay
  String? _completeFilePath;
  String? _countdownFilePath;

  /// Initialize audio service - extract assets for paplay
  Future<void> initialize() async {
    try {
      // Extract sound files to temp directory for paplay
      final tempDir = await getTemporaryDirectory();
      _completeFilePath = path.join(tempDir.path, 'complete.oga');
      _countdownFilePath = path.join(tempDir.path, 'countdown.oga');

      // Extract complete.oga if not exists
      final completeFile = File(_completeFilePath!);
      if (!await completeFile.exists()) {
        final bytes = await rootBundle.load('assets/sounds/complete.oga');
        await completeFile.writeAsBytes(bytes.buffer.asUint8List());
      }

      // Extract countdown.oga if not exists
      final countdownFile = File(_countdownFilePath!);
      if (!await countdownFile.exists()) {
        final bytes = await rootBundle.load('assets/sounds/countdown.oga');
        await countdownFile.writeAsBytes(bytes.buffer.asUint8List());
      }
    } catch (e) {
      // If extraction fails, just continue without audio
    }
  }

  /// Play a notification beep (for exercise completions)
  Future<void> playNotification() async {
    if (!_soundEnabled || _completeFilePath == null) return;

    try {
      // Use paplay for Linux
      await Process.run('paplay', [_completeFilePath!]).timeout(
        const Duration(milliseconds: 800),
        onTimeout: () => ProcessResult(0, 1, '', ''),
      );
    } catch (e) {
      // Silently fail - audio is not critical
    }
  }

  /// Play a countdown beep (short click for 3-2-1 countdown)
  Future<void> playCountdown() async {
    if (!_soundEnabled || _countdownFilePath == null) return;

    try {
      // Use paplay for Linux
      await Process.run('paplay', [_countdownFilePath!]).timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => ProcessResult(0, 1, '', ''),
      );
    } catch (e) {
      // Silently fail
    }
  }

  void enableSound() {
    _soundEnabled = true;
  }

  void disableSound() {
    _soundEnabled = false;
  }
}
