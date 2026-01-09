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
  // Use a pool of players for overlapping sounds
  final List<AudioPlayer> _countdownPlayers = [];
  final List<AudioPlayer> _completePlayers = [];
  int _countdownPlayerIndex = 0;
  int _completePlayerIndex = 0;
  static const int _playerPoolSize = 5; // Allow up to 5 overlapping sounds
  bool _useAudioPlayers = false;
  
  // Keep sources ready for reuse
  Source? _completeSource;
  Source? _countdownSource;

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
    print('AudioService: Initializing audio players...');
    
    // Prepare sources
    _completeSource = AssetSource('sounds/complete.oga');
    _countdownSource = AssetSource('sounds/countdown.oga');
    
    // Create a pool of players for overlapping sounds
    for (int i = 0; i < _playerPoolSize; i++) {
      final countdownPlayer = AudioPlayer();
      final completePlayer = AudioPlayer();
      
      await countdownPlayer.setPlayerMode(PlayerMode.lowLatency);
      await completePlayer.setPlayerMode(PlayerMode.lowLatency);
      
      await countdownPlayer.setReleaseMode(ReleaseMode.stop);
      await completePlayer.setReleaseMode(ReleaseMode.stop);
      
      await countdownPlayer.setVolume(1.0);
      await completePlayer.setVolume(1.0);
      
      // Configure audio context to mix with background audio without requesting focus
      await countdownPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // Don't request focus
          ),
        ),
      );
      
      await completePlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // Don't request focus
          ),
        ),
      );
      
      _countdownPlayers.add(countdownPlayer);
      _completePlayers.add(completePlayer);
    }
    
    // Preload audio by playing at zero volume, then stopping
    // This ensures the first real play is instant
    print('AudioService: Preloading audio files...');
    await _countdownPlayers[0].setVolume(0.0);
    await _countdownPlayers[0].play(_countdownSource!);
    await Future.delayed(const Duration(milliseconds: 100));
    await _countdownPlayers[0].stop();
    await _countdownPlayers[0].setVolume(1.0);
    
    await _completePlayers[0].setVolume(0.0);
    await _completePlayers[0].play(_completeSource!);
    await Future.delayed(const Duration(milliseconds: 100));
    await _completePlayers[0].stop();
    await _completePlayers[0].setVolume(1.0);
    
    print('AudioService: Audio players initialized successfully');
  }

  /// Play a notification beep (for exercise completions)
  Future<void> playNotification() async {
    if (!_soundEnabled) return;

    try {
      if (_useAudioPlayers) {
        // Use round-robin player selection
        final player = _completePlayers[_completePlayerIndex];
        _completePlayerIndex = (_completePlayerIndex + 1) % _playerPoolSize;
        
        // Stop first if already playing, then play
        if (player.state == PlayerState.playing) {
          await player.stop();
        }
        await player.play(_completeSource!);
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
      print('Failed to play notification: $e');
    }
  }

  /// Play a countdown beep (short click for 3-2-1 countdown)
  Future<void> playCountdown() async {
    if (!_soundEnabled) {
      print('AudioService: Sound disabled');
      return;
    }

    try {
      if (_useAudioPlayers) {
        // Use round-robin player selection
        final player = _countdownPlayers[_countdownPlayerIndex];
        print('AudioService: Playing countdown on player ${_countdownPlayerIndex}, state: ${player.state}');
        _countdownPlayerIndex = (_countdownPlayerIndex + 1) % _playerPoolSize;
        
        // Stop first if already playing, then play
        if (player.state == PlayerState.playing) {
          await player.stop();
        }
        await player.play(_countdownSource!);
        print('AudioService: Countdown play() completed');
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
    for (final player in _countdownPlayers) {
      await player.dispose();
    }
    for (final player in _completePlayers) {
      await player.dispose();
    }
  }
}
