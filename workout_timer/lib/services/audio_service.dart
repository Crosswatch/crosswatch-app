import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _soundEnabled = true;

  // For Linux paplay method
  String? _completeFilePath;
  String? _countdownFilePath;

  // For audioplayers method (Android, iOS, etc.)
  final AudioPlayer _completePlayer = AudioPlayer();
  final AudioPlayer _countdownPlayer = AudioPlayer();
  bool _useAudioPlayers = false;

  /// Initialize audio service
  Future<void> initialize() async {
    try {
      // Determine which audio backend to use
      if (Platform.isLinux && !kIsWeb) {
        // Try Linux paplay method first
        _useAudioPlayers = !(await _initializeLinuxAudio());
        if (_useAudioPlayers) {
          // Fallback to audioplayers if paplay not available
          await _initializeAudioPlayers();
        }
      } else {
        // Use audioplayers for Android, iOS, Windows, macOS, Web
        _useAudioPlayers = true;
        await _initializeAudioPlayers();
      }
    } catch (e) {
      // If initialization fails, just continue without audio
      print('Audio initialization failed: $e');
    }
  }

  /// Initialize Linux audio with paplay
  Future<bool> _initializeLinuxAudio() async {
    try {
      // Check if paplay is available
      final result = await Process.run('which', ['paplay']);
      if (result.exitCode != 0) {
        return false;
      }

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

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize audioplayers for cross-platform support
  Future<void> _initializeAudioPlayers() async {
    // Pre-cache audio sources
    await _completePlayer.setSource(AssetSource('sounds/complete.oga'));
    await _countdownPlayer.setSource(AssetSource('sounds/countdown.oga'));

    // Set release mode to stop when complete
    await _completePlayer.setReleaseMode(ReleaseMode.stop);
    await _countdownPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Play a notification beep (for exercise completions)
  Future<void> playNotification() async {
    if (!_soundEnabled) return;

    try {
      if (_useAudioPlayers) {
        await _completePlayer.stop();
        await _completePlayer.seek(Duration.zero);
        await _completePlayer.resume();
      } else {
        // Use paplay for Linux
        if (_completeFilePath != null) {
          await Process.run('paplay', [_completeFilePath!]).timeout(
            const Duration(milliseconds: 800),
            onTimeout: () => ProcessResult(0, 1, '', ''),
          );
        }
      }
    } catch (e) {
      // Silently fail - audio is not critical
      print('Failed to play notification: $e');
    }
  }

  /// Play a countdown beep (short click for 3-2-1 countdown)
  Future<void> playCountdown() async {
    if (!_soundEnabled) return;

    try {
      if (_useAudioPlayers) {
        await _countdownPlayer.stop();
        await _countdownPlayer.seek(Duration.zero);
        await _countdownPlayer.resume();
      } else {
        // Use paplay for Linux
        if (_countdownFilePath != null) {
          await Process.run('paplay', [_countdownFilePath!]).timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => ProcessResult(0, 1, '', ''),
          );
        }
      }
    } catch (e) {
      // Silently fail
      print('Failed to play countdown: $e');
    }
  }

  void enableSound() {
    _soundEnabled = true;
  }

  void disableSound() {
    _soundEnabled = false;
  }

  /// Dispose audio players
  Future<void> dispose() async {
    await _completePlayer.dispose();
    await _countdownPlayer.dispose();
  }
}
