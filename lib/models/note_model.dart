import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late bool isVoice;

  @HiveField(4)
  late String profileId;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  bool convertedToTask;

  @HiveField(7)
  String? audioPath;

  @HiveField(8)
  int audioDurationSeconds;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isVoice,
    required this.profileId,
    required this.createdAt,
    this.convertedToTask = false,
    this.audioPath,
    this.audioDurationSeconds = 0,
  });
}