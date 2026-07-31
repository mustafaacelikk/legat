import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';

@pragma('vm:entry-point')
Future<void> _handleReminderAction(String? actionId, String? payload) async {
  if (payload == null || actionId == null) return;

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    final box = Hive.isBoxOpen('reminders')
        ? Hive.box<Reminder>('reminders')
        : await Hive.openBox<Reminder>('reminders');

    final reminder = box.get(payload);
    if (reminder == null) return;

    if (actionId == 'mark_complete') {
      reminder.isCompleted = true;
      await reminder.save();
      ReminderProvider.instance?.notifyChanges();
      await NotificationService.instance.cancelNotification(reminder.id);
    } else if (actionId == 'snooze') {
      final newTime =
          DateTime.now().add(Duration(minutes: reminder.snoozeMinutes));
      reminder.scheduledAt = newTime;
      await reminder.save();
      ReminderProvider.instance?.notifyChanges();
      await NotificationService.instance.scheduleNotification(
        id: reminder.id,
        title: reminder.title,
        body: reminder.type,
        scheduledAt: newTime,
      );
    }

    ReminderProvider.instance?.notifyChanges();
  } catch (e) {
    // Arka plan izolasyonunda sessizce yut, uygulamayı etkilemesin
  }
}

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  _handleReminderAction(response.actionId, response.payload);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static void Function(String? reminderId)? onReminderNotificationTap;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.actionId != null) {
          _handleReminderAction(details.actionId, details.payload);
        } else {
          onReminderNotificationTap?.call(details.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return false;

    final notifGranted =
        await androidImpl.requestNotificationsPermission() ?? false;
    await androidImpl.requestExactAlarmsPermission();

    return notifGranted;
  }

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? repeatPeriod,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;

    final notifId = id.hashCode;
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel_v2',
      'Hatırlatıcılar',
      channelDescription: 'Hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('mark_complete', 'Tamamlandı',
            showsUserInterface: false),
        AndroidNotificationAction('snooze', 'Ertele',
            showsUserInterface: false),
      ],
    );
    const details = NotificationDetails(android: androidDetails);

    DateTimeComponents? matchComponents;
    if (repeatPeriod == 'Günlük') {
      matchComponents = DateTimeComponents.time;
    } else if (repeatPeriod == 'Haftalık') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }
    // Aylık/Yıllık: tek seferlik planlanır; uygulama tarafı (_checkYearlyReminders benzeri
    // mekanizma) bir sonraki dönemi tekrar planlayacak şekilde update() çağırır.

    try {
      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
        payload: id,
      );
    } catch (e) {
      debugPrint('Bildirim planlama hatası: $e');
    }
  }

  Future<void> cancelNotification(String id) async {
    await _plugin.cancel(id.hashCode);
  }
}
