import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<bool> requestPermission() async {
    final bool? result =
        await _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
    return result ?? true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'Basic notifications for tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Scheduled task reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// Schedules priority-based notifications for a task
  static Future<void> schedulePriorityNotifications({
    required int taskId,
    required String title,
    required String body,
    required DateTime dueDate,
    required String priority,
    bool allowRepeat = false,
  }) async {
    // Cancel any existing notifications for this task
    await cancelNotification(taskId);
    await cancelNotification(taskId + 1000); // pre-alert ID

    final mainTime = tz.TZDateTime.from(dueDate, tz.local);
    final preAlertTime = mainTime.subtract(const Duration(minutes: 15));

    const androidDetails = AndroidNotificationDetails(
      'task_alerts_channel',
      'Task Alerts',
      channelDescription: 'Priority-based task alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    if (priority == 'medium' || priority == 'high') {
      if (preAlertTime.isAfter(DateTime.now())) {
        await _notificationsPlugin.zonedSchedule(
          taskId + 1000, // Pre-alert
          "Upcoming Task",
          "$title is due soon",
          preAlertTime,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    if (priority == 'high' && allowRepeat) {
      // Repeating notification every 5 minutes until user acknowledges (or snoozes)
      await _notificationsPlugin.zonedSchedule(
        taskId,
        "High Priority Task",
        "$title is due now!",
        mainTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'repeating_channel',
            'Repeating High Priority Alerts',
            channelDescription: 'Repeats until acknowledged',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // Regular one-time notification
      await _notificationsPlugin.zonedSchedule(
        taskId,
        "Task Reminder",
        body,
        mainTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
