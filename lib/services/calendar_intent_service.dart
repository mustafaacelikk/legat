import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class CalendarIntentService {
  static Future<void> addEvent({
    required String title,
    String description = '',
    required DateTime start,
    DateTime? end,
    bool allDay = false,
  }) async {
    final endTime = end ?? start.add(const Duration(hours: 1));
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': title,
          'description': description,
          'beginTime': start.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
          'allDay': allDay,
        },
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Takvime ekleme hatası: $e');
    }
  }
}
