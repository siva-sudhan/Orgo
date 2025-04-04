import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime dueDate;

  @HiveField(2)
  int stars;

  @HiveField(3, defaultValue: false)  // Ensure default is false
  bool completed;

  @HiveField(4)
  DateTime? completedAt;

  Task({
    required this.title,
    required this.dueDate,
    this.stars = 0,
    this.completed = false, // Ensure this is always initialized
    this.completedAt,
  });
}
