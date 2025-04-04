import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  String currency;

  @HiveField(1)
  String dateTimeFormat;

  @HiveField(2)
  String name;

  @HiveField(3)
  int age;

  @HiveField(4)
  String? profileImagePath;

  UserSettings({
    this.currency = '\$',
    this.dateTimeFormat = 'dd MMM yy',
    this.name = 'User',
    this.age = 18,
    this.profileImagePath,
  });
}
