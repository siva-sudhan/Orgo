import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../models/user_settings.dart';

class GamificationService {
  /// Call this function after a task is completed
  static void evaluateTask(Task task) {
    if (!task.completed || task.completedAt == null) return;

    final taskBox = Hive.box<Task>('tasks');
    final settingsBox = Hive.box<UserSettings>('settings');
    final settings = settingsBox.get('user') ?? UserSettings();

    int score = 0;

    // 🎯 1. Timeliness: On time or early = +1
    if (!task.completedAt!.isAfter(task.dueDate)) {
      score += 1;
    }

    // 🔁 2. Repetition: Similar task done before
    final previousTasks = taskBox.values
        .where((t) => t.title == task.title && t.key != task.key)
        .toList();

    if (previousTasks.isNotEmpty) {
      score += 1;
    }

    // 📅 3. Consistency: Completed daily streak
    int streak = calculateStreak(task);
    task.streakCount = streak;
    if (streak >= 3) {
      score += 1;
    }

    // 🌟 Auto-Star Rating (0–3)
    task.autoStars = score.clamp(0, 3);
    task.save();

    // ⚡ XP Update
    int gainedXP = task.autoStars * 10;
    settings.xp += gainedXP;

    // 🧠 Level up logic
    while (settings.xp >= settings.level * 100) {
      settings.xp -= settings.level * 100;
      settings.level += 1;
    }

    // 💾 Save XP and level
    settingsBox.put('user', settings);

    // ✅ Fetch updated settings to ensure latest data
    final latestSettings = settingsBox.get('user')!;
    _updateGlobalDailyStreak(latestSettings, task.completedAt!);

    // 💾 Save updated streak
    settingsBox.put('user', latestSettings);
  }

  /// Calculates streak for a specific task title
  static int calculateStreak(Task currentTask) {
    final taskBox = Hive.box<Task>('tasks');
    final allTasks = taskBox.values
        .where((t) =>
            t.title == currentTask.title &&
            t.completed &&
            t.completedAt != null)
        .toList();

    allTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    if (allTasks.isEmpty) return 0;

    int streak = 1;
    for (int i = 0; i < allTasks.length - 1; i++) {
      final curr = allTasks[i].completedAt!;
      final next = allTasks[i + 1].completedAt!;

      DateTime currDate = DateTime(curr.year, curr.month, curr.day);
      DateTime nextExpected = currDate.subtract(Duration(days: 1));
      DateTime nextDate = DateTime(next.year, next.month, next.day);

      if (nextDate == nextExpected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Updates global task streak (1 per calendar day)
  static void _updateGlobalDailyStreak(UserSettings settings, DateTime taskCompletedAt) {
    final currentDate = DateTime(taskCompletedAt.year, taskCompletedAt.month, taskCompletedAt.day);

    final lastDate = settings.lastTaskCompletedAt;
    final lastDateOnly = lastDate != null
        ? DateTime(lastDate.year, lastDate.month, lastDate.day)
        : null;

    if (lastDateOnly == currentDate) {
      // ✅ Already counted for today
      return;
    }

    if (lastDateOnly != null &&
        currentDate.difference(lastDateOnly).inDays == 1) {
      // ✅ Consecutive day: increment streak
      settings.taskStreak += 1;
    } else {
      // ❌ Missed or first task: reset streak
      settings.taskStreak = 1;
    }

    settings.lastTaskCompletedAt = currentDate;
    settings.save();
  }
  /// Call this during app startup to reset streak if a day was missed
  /// Returns true if streak was reset
  static bool checkAndResetDailyStreak() {
    final settingsBox = Hive.box<UserSettings>('settings');
    final settings = settingsBox.get('user') ?? UserSettings();
  
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final last = settings.lastTaskCompletedAt;
    final lastDateOnly = last != null
        ? DateTime(last.year, last.month, last.day)
        : null;
  
    if (lastDateOnly == null) return false;
  
    final diff = todayDateOnly.difference(lastDateOnly).inDays;
  
    if (diff > 1) {
      // ❌ Missed a day, reset streak
      settings.taskStreak = 0;
      settingsBox.put('user', settings);
      return true; // indicate streak was reset
    }
  
    return false;
  }
}
