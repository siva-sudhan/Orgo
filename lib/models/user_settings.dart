import 'package:hive/hive.dart';

part 'user_settings.g.dart';

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

  @HiveField(8)
  int taskStreak;

  @HiveField(9)
  DateTime? lastTaskCompletedAt;

  @HiveField(10)
  List<String> customCategories; // 🆕 Custom user-defined categories

  @HiveField(11)
  Map<String, double> spendingLimits; // 🆕 Category spending limits

  @HiveField(12)
  bool hideBalance; // 🆕 Hide balance with passcode/biometric

  UserSettings({
    this.name = '',
    this.currency = '\$',
    this.profileImagePath = '',
    this.dateOfBirth,
    this.gender = '',
    this.dateTimeFormat = 'dd MMM yy',
    this.xp = 0,
    this.level = 1,
    this.taskStreak = 0,
    this.lastTaskCompletedAt,
    this.customCategories = const [],
    this.spendingLimits = const {},
    this.hideBalance = false, // default value
  });
}
