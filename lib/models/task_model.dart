import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  late String priority;

  @HiveField(4)
  late String status;

  @HiveField(5)
  late String profileId;

  @HiveField(6)
  DateTime? dueDate;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  int completionPercent;

  @HiveField(9)
  String sprint;

  @HiveField(10)
  DateTime? startDate;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.priority,
    required this.status,
    required this.profileId,
    this.dueDate,
    required this.createdAt,
    this.completionPercent = 0,
    this.sprint = '',
    this.startDate,
  });
}