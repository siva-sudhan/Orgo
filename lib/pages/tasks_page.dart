import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'dart:async'; // For Timer

import '../models/task.dart';
import '../models/user_settings.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Box<Task> taskBox;
  bool showStreakBanner = true;
  // For high-priority subtle vibration animation
  Offset _shakeOffset = Offset.zero;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  void _startVibrationEffect(Task task) {
    if (!mounted || task.isAcknowledged || (task.snoozedUntil?.isAfter(DateTime.now()) ?? false)) return;
  
    _vibrationTimer?.cancel(); // cancel any existing timer
  
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (!mounted || task.isAcknowledged || task.snoozedUntil?.isAfter(DateTime.now()) == true) {
        timer.cancel();
        setState(() => _shakeOffset = Offset.zero);
        return;
      }
  
      // Heartbeat style: bump–bump–pause
      HapticFeedback.lightImpact(); // bump 1
      await Future.delayed(Duration(milliseconds: 100));
      HapticFeedback.lightImpact(); // bump 2
      // pause handled by timer interval
    });
  }

  void _addTask(String dateFormat) {
    final titleController = TextEditingController();
    DateTime dueDate = DateTime.now().add(Duration(hours: 1));
    bool setReminder = false;
    String selectedPriority = 'low';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("Add Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: "Enter task title"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: InputDecoration(labelText: "Priority"),
                      items: [
                        DropdownMenuItem(value: 'low', child: Text("🟢 Low")),
                        DropdownMenuItem(value: 'medium', child: Text("🟡 Medium")),
                        DropdownMenuItem(value: 'high', child: Text("🔴 High")),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedPriority = value ?? 'low');
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      child: Text("Pick Due Date: ${DateFormat(dateFormat).format(dueDate)}"),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dueDate = DateTime(picked.year, picked.month, picked.day, dueDate.hour, dueDate.minute);
                          });
                        }
                      },
                    ),
                    TextButton(
                      child: Text("Pick Due Time: ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}"),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(dueDate),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, picked.hour, picked.minute);
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: setReminder,
                          onChanged: (value) {
                            setModalState(() => setReminder = value ?? false);
                          },
                        ),
                        Text("Set Reminder"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final newTask = Task(
                        title: titleController.text,
                        dueDate: dueDate,
                        priority: selectedPriority,
                      );
                      final key = await taskBox.add(newTask);

                      if (setReminder) {
                        await NotificationService.requestPermission();

                        // 🔔 Main reminder
                        await NotificationService.schedulePriorityNotifications(
                          taskId: key,
                          title: "⏰ Task Reminder",
                          body: newTask.title,
                          dueDate: newTask.dueDate,
                          priority: selectedPriority,
                          allowRepeat: selectedPriority == 'high',
                        );
                        // 🔔 Pre-alert (15 mins before) for medium/high priority
                        if (selectedPriority != 'low') {
                          final preAlertTime = newTask.dueDate.subtract(Duration(minutes: 15));
                          if (preAlertTime.isAfter(DateTime.now())) {
                            await NotificationService.scheduleNotification(
                              id: key + 100000, // offset for pre-alert
                              title: "⚠️ Upcoming Task",
                              body: "${newTask.title} is due soon!",
                              scheduledTime: preAlertTime,
                            );

                          }
                        }
                      }

                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editTask(Task task, String dateFormat) {
    final titleController = TextEditingController(text: task.title);
    DateTime dueDate = task.dueDate;
    bool setReminder = true;
    String selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: "Edit task title"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: InputDecoration(labelText: "Priority"),
                      items: [
                        DropdownMenuItem(value: 'low', child: Text("🟢 Low")),
                        DropdownMenuItem(value: 'medium', child: Text("🟡 Medium")),
                        DropdownMenuItem(value: 'high', child: Text("🔴 High")),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedPriority = value ?? 'low');
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      child: Text("Pick Due Date: ${DateFormat(dateFormat).format(dueDate)}"),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dueDate = DateTime(picked.year, picked.month, picked.day, dueDate.hour, dueDate.minute);
                          });
                        }
                      },
                    ),
                    TextButton(
                      child: Text("Pick Due Time: ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}"),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(dueDate),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, picked.hour, picked.minute);
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: setReminder,
                          onChanged: (value) {
                            setModalState(() => setReminder = value ?? false);
                          },
                        ),
                        Text("Set Reminder"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    task.title = titleController.text;
                    task.dueDate = dueDate;
                    task.priority = selectedPriority;
                    task.isAcknowledged = false;
                    task.snoozedUntil = null;

                    await task.save();

                    if (setReminder) {
                      await NotificationService.requestPermission();

                      // Cancel old notifications
                      await NotificationService.cancelNotification(task.key);
                      await NotificationService.cancelNotification(task.key + 100000);

                      // Schedule new main alert
                      await NotificationService.schedulePriorityNotifications(
                        taskId: task.key,
                        title: "Task Reminder",
                        body: task.title,
                        dueDate: task.dueDate,
                        priority: selectedPriority,
                        allowRepeat: selectedPriority == 'high',
                      );

                      // Pre-alert for medium & high priority
                      if (selectedPriority != 'low') {
                        final preAlertTime = task.dueDate.subtract(Duration(minutes: 15));
                        if (preAlertTime.isAfter(DateTime.now())) {
                          await NotificationService.scheduleNotification(
                            id: task.key + 100000,
                            title: "⚠️ Upcoming Task",
                            body: "${task.title} is due soon!",
                            scheduledTime: preAlertTime,
                          );
                        }
                      }
                    } else {
                      await NotificationService.cancelNotification(task.key);
                      await NotificationService.cancelNotification(task.key + 100000);
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompletedTasks(List<Task> completedTasks, String dateFormat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: completedTasks.length,
                      itemBuilder: (context, index) {
                        final task = completedTasks[index];
                        return ListTile(
                          leading: Icon(Icons.check_circle, color: Colors.green),
                          title: Text(task.title),
                          subtitle: Text(
                            "Completed: ${DateFormat(dateFormat).format(task.completedAt!)} • "
                            "${'★' * task.stars}${'☆' * (3 - task.stars)}",
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Move Task Back"),
                                content: Text("Do you want to move this task back to active list?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    onPressed: () async {
                                      task.completed = false;
                                      task.completedAt = null;
                                      await task.save();
                                      Navigator.of(context).pop(); // Close dialog
                                      Navigator.of(context).pop(); // Close bottom sheet
                                    },
                                    child: Text("Move to Active"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  if (completedTasks.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        for (var task in completedTasks) {
                          task.delete();
                        }
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.delete),
                      label: Text("Clear History"),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask(Task task) async {
    if (task.completed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    
    final settingsBox = Hive.box<UserSettings>('settings');
    final settings = settingsBox.get('user') ?? UserSettings();
    
    final lastCompletedDate = settings.lastTaskCompletedAt != null
        ? DateTime(
            settings.lastTaskCompletedAt!.year,
            settings.lastTaskCompletedAt!.month,
            settings.lastTaskCompletedAt!.day,
          )
        : null;
    
    task.completed = true;
    task.completedAt = now;
    
    GamificationService.evaluateTask(task);
    
    if (lastCompletedDate == null) {
      settings.taskStreak = 1;
    } else if (lastCompletedDate == yesterday) {
      settings.taskStreak += 1;
    } else if (lastCompletedDate != today) {
      settings.taskStreak = 1;
    }
    
    // Update last completion date
    settings.lastTaskCompletedAt = today;
    settings.xp += 10;
    task.streakCount = settings.taskStreak;
    
    await task.save();
    await settings.save();

  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserSettings>('settings').listenable(keys: ['user']),
      builder: (context, settingsBox, _) {
        final settings = settingsBox.get('user') ?? UserSettings();
        final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';
        final globalStreak = settings.taskStreak;

        return ValueListenableBuilder(
          valueListenable: taskBox.listenable(),
          builder: (context, box, _) {
            final tasks = box.values.toList();
            final pendingTasks = tasks.where((t) => !t.completed).toList();
            final completedTasks = tasks.where((t) => t.completed).toList();

            return Scaffold(
              appBar: AppBar(
                title: Text("Tasks"),
                actions: [
                  if (completedTasks.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.history),
                      tooltip: "Completed Tasks",
                      onPressed: () => _showCompletedTasks(completedTasks, dateFormat),
                    ),
                ],
              ),
              body: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: (globalStreak > 0 && showStreakBanner)
                        ? GestureDetector(
                            key: ValueKey("streakBanner"),
                            onTap: () => setState(() => showStreakBanner = false),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "$globalStreak-Day Streak 🔥",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.flash_on, color: Colors.amber, size: 18),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "XP Boost Active ⚡ Keep up the momentum!",
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                  Expanded(
                    child: pendingTasks.isEmpty
                        ? Center(child: Text("No pending tasks"))
                        : ListView.builder(
                            padding: EdgeInsets.all(16.0),
                            itemCount: pendingTasks.length,
                            itemBuilder: (context, index) {
                              final task = pendingTasks[index];
                              final now = DateTime.now();
                              final timeDiff = task.dueDate.difference(now).inMinutes;
                              final isHighPriority = task.priority == 'high';
                              final isMediumPriority = task.priority == 'medium';
                              final isLowPriority = task.priority == 'low';
                              final isUrgent = isHighPriority && timeDiff <= 15 && !task.isAcknowledged;
                              final isSnoozed = task.snoozedUntil?.isAfter(now) ?? false;
                              if (isUrgent && !isSnoozed) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _startVibrationEffect(task);
                                });
                              }
                              return Dismissible(
                                key: Key(task.key.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  color: Colors.redAccent,
                                  child: Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => task.delete(),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isHighPriority
                                          ? (isUrgent ? Colors.red : Colors.redAccent)
                                          : isMediumPriority
                                              ? Colors.amber
                                              : Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  color: isUrgent ? Colors.red.withOpacity(0.1) : null,
                                  elevation: 3,
                                  child: InkWell(
                                    onTap: () => _editTask(task, dateFormat),
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.completed,
                                        onChanged: (_) => _completeTask(task),
                                      ),
                                      title: Text(task.title),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                task.priority == 'high'
                                                    ? Icons.warning
                                                    : task.priority == 'medium'
                                                        ? Icons.notifications_active
                                                        : Icons.notifications_none,
                                                color: task.priority == 'high'
                                                    ? Colors.red
                                                    : task.priority == 'medium'
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                task.priority == 'high'
                                                    ? "🔴 High Priority"
                                                    : task.priority == 'medium'
                                                        ? "🟡 Medium Priority"
                                                        : "🟢 Low Priority",
                                                style: TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              if (isUrgent && !isSnoozed) ...[
                                                Spacer(),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: Text("🔔 ${task.title}"),
                                                        content: Text("This high-priority task is due soon."),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () async {
                                                              task.isAcknowledged = true;
                                                              await task.save();
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text("Acknowledge"),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              final snoozeUntil = DateTime.now().add(Duration(minutes: 5));
                                                              task.snoozedUntil = snoozeUntil;
                                                              await task.save();
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text("Snooze 5m"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  child: Text("⚠️"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent,
                                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                                  ),
                                                )
                                              ]
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Due: ${DateFormat(dateFormat).format(task.dueDate)} • "
                                            "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}",
                                          ),
                                          if (isSnoozed)
                                          Row(
                                            children: [
                                              Icon(Icons.snooze, color: Colors.blueGrey, size: 16),
                                              SizedBox(width: 4),
                                              Text("Snoozed until ${DateFormat('hh:mm a').format(task.snoozedUntil!)}"),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              ...List.generate(
                                                3,
                                                (i) => Icon(
                                                  i < task.stars ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                              ),
                                              if (task.autoStars > 0) ...[
                                                SizedBox(width: 4),
                                                Text("+"),
                                                SizedBox(width: 2),
                                                ...List.generate(
                                                  task.autoStars,
                                                  (i) => Icon(Icons.star, color: Colors.grey, size: 18),
                                                ),
                                              ]
                                            ],
                                          ),
                                          if (task.streakCount > 1)
                                            Row(
                                              children: [
                                                Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                                                SizedBox(width: 4),
                                                Text('${task.streakCount}-day streak'),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                        ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _addTask(dateFormat),
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }
}
