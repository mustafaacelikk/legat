import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 2)
class Reminder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late DateTime scheduledAt;

  @HiveField(4)
  late String profileId;

  @HiveField(5)
  bool isCompleted = false;

  @HiveField(6)
  String? contactName;

  @HiveField(7)
  String? contactPhone;

  @HiveField(8)
  int snoozeMinutes;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  bool isRecurringYearly = false;

  @HiveField(11)
  String? specialDayType;

  @HiveField(12)
  String? groupId;

  @HiveField(13)
  List<String> communicationTypes;

  @HiveField(14)
  String? taskId;

  Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledAt,
    required this.profileId,
    this.isCompleted = false,
    this.contactName,
    this.contactPhone,
    this.snoozeMinutes = 30,
    required this.createdAt,
    this.isRecurringYearly = false,
    this.specialDayType,
    this.groupId,
    this.communicationTypes = const [],
    this.taskId,
  });
}