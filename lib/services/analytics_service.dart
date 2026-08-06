import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> setUserId(String id) => _analytics.setUserId(id: id);

  Future<void> logAppOpen() => _analytics.logEvent(name: 'app_open');

  Future<void> logTaskCreated() => _analytics.logEvent(name: 'task_created');
  Future<void> logTaskEdited() => _analytics.logEvent(name: 'task_edited');
  Future<void> logTaskDeleted() => _analytics.logEvent(name: 'task_deleted');

  Future<void> logNoteCreated() => _analytics.logEvent(name: 'note_created');
  Future<void> logNoteEdited() => _analytics.logEvent(name: 'note_edited');
  Future<void> logNoteDeleted() => _analytics.logEvent(name: 'note_deleted');

  Future<void> logReminderCreated() =>
      _analytics.logEvent(name: 'reminder_created');
  Future<void> logReminderEdited() =>
      _analytics.logEvent(name: 'reminder_edited');
  Future<void> logReminderDeleted() =>
      _analytics.logEvent(name: 'reminder_deleted');

  Future<void> logProfileCreated() =>
      _analytics.logEvent(name: 'profile_created');
  Future<void> logProfileEdited() =>
      _analytics.logEvent(name: 'profile_edited');
  Future<void> logProfileDeleted() =>
      _analytics.logEvent(name: 'profile_deleted');
}
