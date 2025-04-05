import 'package:hive/hive.dart';

part 'user_settings.g.dart'; // Make sure this is correct

@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String currency;

  @HiveField(2)
  String profileImagePath;

  @HiveField(3)
  DateTime? dateOfBirth;

  @HiveField(4)
  String gender;

  @HiveField(5)
  String dateTimeFormat;

  @HiveField(6)
  int xp;

  @HiveField(7)
  int level;

  UserSettings({
    this.name = '',
    this.currency = '\$',
    this.profileImagePath = '',
    this.dateOfBirth,
    this.gender = '',
    this.dateTimeFormat = 'dd MMM yy',
    this.xp = 0,
    this.level = 1,
  });
}
