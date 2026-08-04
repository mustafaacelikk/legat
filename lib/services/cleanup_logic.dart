import '../models/task_model.dart';
import '../models/reminder_model.dart';

class CleanupResult {
  final List<String> taskIdsToDelete;
  final List<String> reminderIdsToDelete;
  CleanupResult(this.taskIdsToDelete, this.reminderIdsToDelete);
}

/// Tamamlanmış görevleri ve hatırlatıcıları hesaplar.
/// Bir görev tamamlandıysa, ona bağlı hatırlatıcı (taskId ile eşleşen)
/// kendi isCompleted durumu ne olursa olsun silinecekler listesine eklenir.
CleanupResult computeCompletedCleanup(
    List<Task> tasks, List<Reminder> reminders) {
  final completedTaskIds = tasks
      .where((t) => t.status == 'Tamamlandı')
      .map((t) => t.id)
      .toSet();

  final reminderIdsToDelete = <String>{};
  for (final r in reminders) {
    if (r.isCompleted) {
      reminderIdsToDelete.add(r.id);
    }
    if (r.taskId != null && completedTaskIds.contains(r.taskId)) {
      reminderIdsToDelete.add(r.id);
    }
  }

  return CleanupResult(
      completedTaskIds.toList(), reminderIdsToDelete.toList());
}
