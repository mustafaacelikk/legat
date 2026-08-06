import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';

class ReminderProvider extends ChangeNotifier {
  static ReminderProvider? instance;

  late Box<Reminder> _box;
  final _uuid = const Uuid();
  bool _isReloading = false;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    _box = await Hive.openBox<Reminder>('reminders');
    await _checkYearlyReminders();
    instance = this;
    notifyListeners();
  }

  Future<void> reload() async {
    if (_isReloading) return;
    _isReloading = true;
    try {
      if (_box.isOpen) {
        await _box.close();
      }
      _box = await Hive.openBox<Reminder>('reminders');
      notifyListeners();
    } finally {
      _isReloading = false;
    }
  }

  List<Reminder> get all {
    try {
      return _box.values.toList();
    } catch (_) {
      return [];
    }
  }

  void notifyChanges() {
    notifyListeners();
  }

  List<Reminder> byProfile(String profileId) => profileId == 'all'
      ? all
      : all.where((r) => r.profileId == profileId).toList();

  List<Reminder> todayReminders(String profileId) {
    final now = DateTime.now();
    return byProfile(profileId).where((r) {
      if (r.isCompleted) return false;
      final d = r.scheduledAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<Reminder> get callReminders =>
      all.where((r) => r.type == 'Arama' && !r.isCompleted).toList();

  Future<void> _scheduleFor(Reminder reminder) async {
    if (reminder.isCompleted) {
      await NotificationService.instance.cancelNotification(reminder.id);
      return;
    }
    String? repeatPeriod;
    if (reminder.type.startsWith('Tekrarlayan:')) {
      repeatPeriod = reminder.type.split(':')[1];
    }
    final hasPhone =
        reminder.contactPhone != null && reminder.contactPhone!.isNotEmpty;
    final showCall = hasPhone && reminder.communicationTypes.contains('Ara');
    final showSend =
        hasPhone && reminder.communicationTypes.contains('Sohbet');
    await NotificationService.instance.scheduleNotification(
      id: reminder.id,
      title: reminder.title,
      body: (reminder.quickMessage != null &&
              reminder.quickMessage!.isNotEmpty)
          ? reminder.quickMessage!
          : reminder.type,
      scheduledAt: reminder.scheduledAt,
      repeatPeriod: repeatPeriod,
      showCallAction: showCall,
      showSendAction: showSend,
    );
  }

  Future<void> add(Reminder reminder) async {
    reminder.id = _uuid.v4();
    reminder.createdAt = DateTime.now();
    await _box.put(reminder.id, reminder);
    await AnalyticsService.instance.logReminderCreated();
    await _scheduleFor(reminder);
    notifyListeners();
  }

  Future<void> complete(String id) async {
    final r = _box.get(id);
    if (r != null) {
      r.isCompleted = true;
      await r.save();
      await NotificationService.instance.cancelNotification(r.id);
      notifyListeners();
    }
  }

  Future<void> update(Reminder reminder) async {
    await reminder.save();
    await AnalyticsService.instance.logReminderEdited();
    await _scheduleFor(reminder);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await AnalyticsService.instance.logReminderDeleted();
    await NotificationService.instance.cancelNotification(id);
    notifyListeners();
  }

  Future<void> deleteByTaskId(String taskId) async {
    final linked =
        _box.values.where((r) => r.taskId == taskId).map((r) => r.id).toList();
    for (final id in linked) {
      await _box.delete(id);
    }
    if (linked.isNotEmpty) notifyListeners();
  }

  Future<void> setCompletedForTask(String taskId, bool completed) async {
    final linked = _box.values.where((r) => r.taskId == taskId).toList();
    for (final r in linked) {
      r.isCompleted = completed;
      await r.save();
      await _scheduleFor(r);
    }
    if (linked.isNotEmpty) notifyListeners();
  }

  Future<void> cleanupOrphaned(Set<String> existingTaskIds) async {
    final orphans = _box.values
        .where((r) => r.taskId != null && !existingTaskIds.contains(r.taskId))
        .map((r) => r.id)
        .toList();
    for (final id in orphans) {
      await _box.delete(id);
    }
    if (orphans.isNotEmpty) notifyListeners();
  }

  Future<void> updateGroup(String groupId, DateTime newBaseDate) async {
    final groupReminders =
        _box.values.where((r) => r.groupId == groupId).toList();

    for (final r in groupReminders) {
      // Offset'i başlıktan tespit et
      int dayOffset = 0;
      if (r.title.contains('1 Gün Sonra')) dayOffset = -1;
      if (r.title.contains('1 Hafta Sonra')) dayOffset = -7;

      r.scheduledAt = DateTime(
        newBaseDate.year,
        newBaseDate.month,
        newBaseDate.day + dayOffset,
        9,
        0,
      );
      await r.save();
      await _scheduleFor(r);
    }
    notifyListeners();
  }

  // Yıllık tekrar kontrolü — uygulama açılışında çalışır
  Future<void> _checkYearlyReminders() async {
    final now = DateTime.now();
    final toUpdate = <Reminder>[];

    for (final r in _box.values) {
      if (!r.isRecurringYearly) continue;
      if (!r.isCompleted) continue;
      // Geçmiş yıllık hatırlatıcıyı bir sonraki yıla taşı
      final nextYear = DateTime(
        r.scheduledAt.year + 1,
        r.scheduledAt.month,
        r.scheduledAt.day,
        r.scheduledAt.hour,
        r.scheduledAt.minute,
      );
      if (nextYear.isAfter(now)) {
        r.scheduledAt = nextYear;
        r.isCompleted = false;
        toUpdate.add(r);
      }
    }

    for (final r in toUpdate) {
      await r.save();
      await _scheduleFor(r);
    }
  }
}
