import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';

class TaskProvider extends ChangeNotifier {
  late Box<Task> _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    _box = await Hive.openBox<Task>('tasks');
    notifyListeners();
  }

  List<Task> get all => _box.values.toList();

  List<Task> byProfile(String profileId) => profileId == 'all'
      ? all
      : all.where((t) => t.profileId == profileId).toList();

  List<Task> todayTasks(String profileId) {
    final now = DateTime.now();
    return byProfile(profileId).where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<Task> get overdue {
    final now = DateTime.now();
    return all.where((t) {
      if (t.dueDate == null || t.status == 'Tamamlandı') return false;
      return t.dueDate!.isBefore(now);
    }).toList();
  }

  int countByStatus(String status, String profileId) =>
      byProfile(profileId).where((t) => t.status == status).length;

  Future<void> add(Task task) async {
    task.id = _uuid.v4();
    task.createdAt = DateTime.now();
    await _box.put(task.id, task);
    await AnalyticsService.instance.logTaskCreated();
    notifyListeners();
  }

  Future<void> update(Task task) async {
    await task.save();
    await AnalyticsService.instance.logTaskEdited();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await AnalyticsService.instance.logTaskDeleted();
    notifyListeners();
  }
}