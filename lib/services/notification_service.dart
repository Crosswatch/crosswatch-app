import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Use conditional import to avoid dart:io on web
import 'dart:io' if (dart.library.html) 'platform_stub.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Skip notifications on web
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Platform-specific initialization
    InitializationSettings? initializationSettings;

    if (!kIsWeb && Platform.isAndroid) {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      initializationSettings = const InitializationSettings(
        android: androidSettings,
      );
    } else if (!kIsWeb && Platform.isIOS) {
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      initializationSettings = const InitializationSettings(iOS: iosSettings);
    } else if (!kIsWeb && Platform.isLinux) {
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open workout',
      );
      initializationSettings = const InitializationSettings(
        linux: linuxSettings,
      );
    }

    if (initializationSettings != null) {
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
        },
      );
    }

    _initialized = true;
  }

  Future<void> showExerciseNotification({
    required String exerciseName,
    required String description,
  }) async {
    if (!_initialized) await initialize();
    if (kIsWeb) return;

    NotificationDetails? notificationDetails;

    if (Platform.isAndroid) {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_channel',
          'Workout Notifications',
          channelDescription:
              'Notifications for workout exercises and transitions',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    } else if (Platform.isIOS) {
      notificationDetails = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else if (Platform.isLinux) {
      notificationDetails = const NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.critical,
        ),
      );
    }

    if (notificationDetails != null) {
      await _notifications.show(
        0, // notification id
        'Next Exercise: $exerciseName',
        description,
        notificationDetails,
      );
    }
  }

  Future<void> showTransitionNotification({
    required String nextExerciseName,
    required int secondsRemaining,
  }) async {
    if (!_initialized) await initialize();
    if (kIsWeb) return;

    NotificationDetails? notificationDetails;

    if (Platform.isAndroid) {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_channel',
          'Workout Notifications',
          channelDescription:
              'Notifications for workout exercises and transitions',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
        ),
      );
    } else if (Platform.isIOS) {
      notificationDetails = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      );
    } else if (Platform.isLinux) {
      notificationDetails = const NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        ),
      );
    }

    if (notificationDetails != null) {
      await _notifications.show(
        0, // notification id
        'Get Ready',
        'Next: $nextExerciseName in ${secondsRemaining}s',
        notificationDetails,
      );
    }
  }

  Future<void> showWorkoutCompleteNotification() async {
    if (!_initialized) await initialize();
    if (kIsWeb) return;

    NotificationDetails? notificationDetails;

    if (Platform.isAndroid) {
      notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_channel',
          'Workout Notifications',
          channelDescription:
              'Notifications for workout exercises and transitions',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
        ),
      );
    } else if (Platform.isIOS) {
      notificationDetails = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else if (Platform.isLinux) {
      notificationDetails = const NotificationDetails(
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        ),
      );
    }

    if (notificationDetails != null) {
      await _notifications.show(
        0, // notification id
        'Workout Complete!',
        'Great job! You finished your workout.',
        notificationDetails,
      );
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
