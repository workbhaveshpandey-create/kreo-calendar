import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'kreo_calendar_reminders';
  static const _channelName = 'Event Reminders';
  static const _channelDescription =
      'Notifications for upcoming calendar events';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // Set timezone to India Standard Time
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Register the channel with the system
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        print('DEBUG: Notification tapped: ${details.payload}');
      },
    );

    // Request exact alarm permission on Android 12+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    print('DEBUG: NotificationService initialized with timezone Asia/Kolkata');
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'Kreo Calendar Test',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
      macOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '🔔 Test Notification',
      'Notifications are working! You will receive event reminders.',
      platformChannelSpecifics,
    );
    print('DEBUG: Test notification sent');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(presentSound: true),
      macOS: DarwinNotificationDetails(presentSound: true),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    print('DEBUG: Scheduling notification "$title" for $scheduledTZDate');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true, // High priority notification
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('DEBUG: Notification scheduled successfully for $scheduledTZDate');
  }

  /// Schedule a reminder notification 5 minutes before the event
  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventStartTime,
    String? eventLocation,
  }) async {
    // Calculate reminder time (5 minutes before event)
    final reminderTime = eventStartTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    print('DEBUG: Event "$eventTitle" starts at $eventStartTime');
    print('DEBUG: Reminder would be at $reminderTime (now is $now)');

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(now)) {
      print('DEBUG: Skipping notification - reminder time is in the past');
      return;
    }

    // Generate unique notification ID from event ID hash
    final notificationId = eventId.hashCode.abs() % 2147483647;

    final body = eventLocation != null && eventLocation.isNotEmpty
        ? 'Starting in 5 minutes at $eventLocation'
        : 'Starting in 5 minutes';

    await scheduleNotification(
      id: notificationId,
      title: '📅 $eventTitle',
      body: body,
      scheduledDate: reminderTime,
      payload: eventId,
    );

    print(
      'DEBUG: Scheduled reminder for "$eventTitle" at $reminderTime (ID: $notificationId)',
    );
  }

  /// Cancel a scheduled notification for an event
  Future<void> cancelEventReminder(String eventId) async {
    final notificationId = eventId.hashCode.abs() % 2147483647;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    print('DEBUG: Cancelled notification for event $eventId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('DEBUG: Cancelled all notifications');
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
