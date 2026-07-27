import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 3)
class Profile extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late bool isActive;

  @HiveField(5)
  late DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    this.isActive = true,
    required this.createdAt,
  });
}