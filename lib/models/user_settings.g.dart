// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 2;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      name: fields[0] as String,
      currency: fields[1] as String,
      profileImagePath: fields[2] as String,
      dateOfBirth: fields[3] as DateTime?,
      gender: fields[4] as String,
      dateTimeFormat: fields[5] as String,
      xp: fields[6] as int,
      level: fields[7] as int,
      taskStreak: fields[8] as int,
      lastTaskCompletedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.profileImagePath)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.dateTimeFormat)
      ..writeByte(6)
      ..write(obj.xp)
      ..writeByte(7)
      ..write(obj.level)
      ..writeByte(8)
      ..write(obj.taskStreak)
      ..writeByte(9)
      ..write(obj.lastTaskCompletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
