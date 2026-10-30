import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/task.dart';

enum TaskReminderSyncStatus {
  ready,
  notificationsDenied,
  exactAlarmsDenied,
  unsupportedPlatform,
  notInitialized,
}

class TaskReminderService {
  TaskReminderService._();

  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _supported = false;
  static bool _exactAlarmsAllowed = false;
  static const _channelId = 'task_reminders_alarm_v1';
  static const _channelName = 'Task alarms';
  static const _payloadPrefix = 'task-reminder:';

  static bool get isInitialized => _initialized;
  static bool get isSupported => _supported;

  static Future<void> initialize() async {
    if (_initialized) return;
    final platform = defaultTargetPlatform;
    _supported = !kIsWeb &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
    if (!_supported) {
      _initialized = true;
      return;
    }

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(
      timezone.getLocation(localTimezone.identifier),
    );

    final initialized = await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) {
      throw StateError('The local notification service did not initialize.');
    }
    _initialized = true;
  }

  static Future<TaskReminderSyncStatus> syncTasks(
    List<AppTask> tasks, {
    bool requestPermissions = false,
  }) async {
    if (!_initialized) return TaskReminderSyncStatus.notInitialized;
    final reminders =
        tasks.where((task) => task.reminderEnabled && !task.completed).toList();
    if (reminders.isEmpty) {
      if (_supported) {
        final pending = await _notifications.pendingNotificationRequests();
        for (final request in pending) {
          if (request.payload?.startsWith(_payloadPrefix) ?? false) {
            await _notifications.cancel(id: request.id);
          }
        }
      }
      return TaskReminderSyncStatus.ready;
    }
    if (!_supported) return TaskReminderSyncStatus.unsupportedPlatform;

    var notificationsAllowed = await _notificationsEnabled();
    if (!notificationsAllowed && requestPermissions) {
      notificationsAllowed = await _requestNotificationPermission();
    }
    if (!notificationsAllowed) {
      return TaskReminderSyncStatus.notificationsDenied;
    }

    _exactAlarmsAllowed = await _canScheduleExactly();
    if (!_exactAlarmsAllowed && requestPermissions) {
      _exactAlarmsAllowed = await _requestExactAlarmPermission();
    }

    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_payloadPrefix) ?? false) {
        await _notifications.cancel(id: request.id);
      }
    }

    for (final task in reminders) {
      final scheduledAt = plannedTime(task);
      if (scheduledAt == null) continue;

      await _notifications.zonedSchedule(
        id: notificationIdForTask(task.id),
        title: 'Time for ${task.title}',
        body: task.description.isEmpty
            ? 'Your scheduled task reminder is here.'
            : task.description,
        scheduledDate: timezone.TZDateTime.from(scheduledAt, timezone.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Sound-enabled reminders for your tasks.',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: _exactAlarmsAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_payloadPrefix${task.id}',
      );
    }

    return _exactAlarmsAllowed
        ? TaskReminderSyncStatus.ready
        : TaskReminderSyncStatus.exactAlarmsDenied;
  }

  static Future<bool> requestPermissions() async {
    if (!_initialized || !_supported) return false;
    final notificationsAllowed =
        await _notificationsEnabled() || await _requestNotificationPermission();
    if (!notificationsAllowed) return false;
    _exactAlarmsAllowed =
        await _canScheduleExactly() || await _requestExactAlarmPermission();
    return true;
  }

  static Future<void> showTestSound() async {
    if (!_initialized || !_supported) {
      throw StateError('Task alarm notifications are not available here.');
    }
    if (!await _notificationsEnabled()) {
      final granted = await _requestNotificationPermission();
      if (!granted) {
        throw StateError(
          'Allow notifications in device settings before testing the alarm sound.',
        );
      }
    }

    await _notifications.show(
      id: 0x7ffffffe,
      title: 'Reminder sound test',
      body: 'Your task reminder sound is working.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Sound-enabled reminders for your tasks.',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  static DateTime? plannedTime(AppTask task, {DateTime? now}) {
    final dueDate = task.dueDate;
    if (!task.reminderEnabled || task.completed || dueDate == null) {
      return null;
    }
    final minutes = task.dueTimeMinutes ?? 9 * 60;
    final scheduledAt = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      minutes ~/ 60,
      minutes % 60,
    );
    return scheduledAt.isAfter(now ?? DateTime.now()) ? scheduledAt : null;
  }

  static int notificationIdForTask(String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static Future<bool> _notificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final permissions = await ios?.checkPermissions();
    return permissions?.isEnabled ?? false;
  }

  static Future<bool> _requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;
  }

  static Future<bool> _canScheduleExactly() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  static Future<bool> _requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestExactAlarmsPermission() ?? false;
  }
}
