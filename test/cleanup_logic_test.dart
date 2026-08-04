import 'package:flutter_test/flutter_test.dart';
import 'package:herseyim/models/task_model.dart';
import 'package:herseyim/models/reminder_model.dart';
import 'package:herseyim/services/cleanup_logic.dart';

Task _task(String id, String status) => Task(
      id: id,
      title: 'Test Görev $id',
      priority: 'Orta',
      status: status,
      profileId: 'personal',
      createdAt: DateTime.now(),
    );

Reminder _reminder(String id,
        {bool isCompleted = false, String? taskId}) =>
    Reminder(
      id: id,
      title: 'Test Hatırlatıcı $id',
      type: 'Zamanlı',
      scheduledAt: DateTime.now(),
      profileId: 'personal',
      createdAt: DateTime.now(),
      isCompleted: isCompleted,
      taskId: taskId,
    );

void main() {
  group('computeCompletedCleanup', () {
    test('kendi başına tamamlanmış hatırlatıcı silinir', () {
      final tasks = <Task>[];
      final reminders = [_reminder('r1', isCompleted: true)];

      final result = computeCompletedCleanup(tasks, reminders);

      expect(result.reminderIdsToDelete, contains('r1'));
    });

    test(
        'göreve bağlı hatırlatıcı, hatırlatıcı kendi isCompleted false olsa bile görev tamamlanınca silinir',
        () {
      final tasks = [_task('t1', 'Tamamlandı')];
      final reminders = [
        _reminder('r1', isCompleted: false, taskId: 't1'),
      ];

      final result = computeCompletedCleanup(tasks, reminders);

      expect(result.taskIdsToDelete, contains('t1'));
      expect(result.reminderIdsToDelete, contains('r1'));
    });

    test('tamamlanmamış görevin hatırlatıcısı silinmez', () {
      final tasks = [_task('t1', 'Planlı')];
      final reminders = [
        _reminder('r1', isCompleted: false, taskId: 't1'),
      ];

      final result = computeCompletedCleanup(tasks, reminders);

      expect(result.taskIdsToDelete, isEmpty);
      expect(result.reminderIdsToDelete, isEmpty);
    });

    test('ilgisiz hatırlatıcı hiç etkilenmez', () {
      final tasks = [_task('t1', 'Tamamlandı')];
      final reminders = [
        _reminder('r1', isCompleted: false, taskId: null),
      ];

      final result = computeCompletedCleanup(tasks, reminders);

      expect(result.reminderIdsToDelete, isEmpty);
    });
  });
}
