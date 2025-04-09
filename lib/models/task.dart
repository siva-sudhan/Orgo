import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime dueDate;

  @HiveField(2, defaultValue: 0)
  int stars; // Manual stars (if needed in future)

  @HiveField(3, defaultValue: false)
  bool completed;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5, defaultValue: 0)
  int autoStars; // Stars calculated automatically (1–3)

  @HiveField(6, defaultValue: 0)
  int streakCount;

  @HiveField(7, defaultValue: false)
  bool isRecurring; // Needed for gamification logic

  @HiveField(8, defaultValue: "low")
  String priority; // "low", "medium", "high"

  @HiveField(9, defaultValue: false)
  bool isAcknowledged;

  @HiveField(10)
  DateTime? snoozedUntil;

  Task({
    required this.title,
    required this.dueDate,
    this.stars = 0,
    this.completed = false,
    this.completedAt,
    this.autoStars = 0,
    this.streakCount = 0,
    this.isRecurring = false,
    this.priority = "low",
    this.isAcknowledged = false,
    this.snoozedUntil,
  });
}
