// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      dueDate: fields[1] as DateTime,
      stars: fields[2] == null ? 0 : fields[2] as int,
      completed: fields[3] == null ? false : fields[3] as bool,
      completedAt: fields[4] as DateTime?,
      autoStars: fields[5] == null ? 0 : fields[5] as int,
      streakCount: fields[6] == null ? 0 : fields[6] as int,
      isRecurring: fields[7] == null ? false : fields[7] as bool,
      priority: fields[8] == null ? 'low' : fields[8] as String,
      isAcknowledged: fields[9] == null ? false : fields[9] as bool,
      snoozedUntil: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.stars)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.autoStars)
      ..writeByte(6)
      ..write(obj.streakCount)
      ..writeByte(7)
      ..write(obj.isRecurring)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.isAcknowledged)
      ..writeByte(10)
      ..write(obj.snoozedUntil);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
