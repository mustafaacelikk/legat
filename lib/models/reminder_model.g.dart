// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 2;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      scheduledAt: fields[3] as DateTime,
      profileId: fields[4] as String,
      isCompleted: fields[5] as bool,
      contactName: fields[6] as String?,
      contactPhone: fields[7] as String?,
      snoozeMinutes: fields[8] as int,
      createdAt: fields[9] as DateTime,
      isRecurringYearly: fields[10] as bool,
      specialDayType: fields[11] as String?,
      groupId: fields[12] as String?,
      communicationTypes: (fields[13] as List).cast<String>(),
      taskId: fields[14] as String?,
      quickMessage: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.scheduledAt)
      ..writeByte(4)
      ..write(obj.profileId)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.contactName)
      ..writeByte(7)
      ..write(obj.contactPhone)
      ..writeByte(8)
      ..write(obj.snoozeMinutes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isRecurringYearly)
      ..writeByte(11)
      ..write(obj.specialDayType)
      ..writeByte(12)
      ..write(obj.groupId)
      ..writeByte(13)
      ..write(obj.communicationTypes)
      ..writeByte(14)
      ..write(obj.taskId)
      ..writeByte(15)
      ..write(obj.quickMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
