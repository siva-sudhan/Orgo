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
  List<String> customCategories;

  @HiveField(11)
  Map<String, double> spendingLimits;

  @HiveField(12)
  bool hideBalance;

  @HiveField(13)
  List<String> profileList; // NEW: List of user-defined financial profiles

  @HiveField(14)
  String activeProfile; // NEW: Currently selected profile name
  
  void fixNulls() {
    currency = currency.isNotEmpty ? currency : '\$';
    dateTimeFormat = dateTimeFormat.isNotEmpty ? dateTimeFormat : 'dd MMM yy';
    customCategories = customCategories ?? [];
    spendingLimits = spendingLimits ?? {};
    profileList = profileList == null || profileList.isEmpty ? ['Main'] : profileList;
    activeProfile = activeProfile == null || activeProfile.isEmpty ? 'Main' : activeProfile;
    hideBalance = hideBalance ?? false;
  }

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
    this.hideBalance = false,
    this.profileList = const ['Main'], // Default profile list
    this.activeProfile = 'Main',       // Default active profile
  });
}
