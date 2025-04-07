import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  void _addTask(String dateFormat) {
    final titleController = TextEditingController();
    DateTime dueDate = DateTime.now().add(Duration(hours: 1));
    bool setReminder = false;

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
                    SizedBox(height: 10),
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
                            dueDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              dueDate.hour,
                              dueDate.minute,
                            );
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
                            dueDate = DateTime(
                              dueDate.year,
                              dueDate.month,
                              dueDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: setReminder,
                          onChanged: (value) {
                            setModalState(() {
                              setReminder = value ?? false;
                            });
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
                        stars: 0,
                        completed: false,
                        completedAt: null,
                        streakCount: 0,
                      );
                      final key = await taskBox.add(newTask);

                      if (setReminder) {
                        bool granted = await NotificationService.requestPermission();
                        if (granted) {
                          NotificationService.scheduleNotification(
                            id: key,
                            title: "Task Reminder",
                            body: newTask.title,
                            scheduledTime: newTask.dueDate,
                          );
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
    bool setReminder = false; // Optionally load this if reminder exists
  
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
                    SizedBox(height: 10),
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
                            dueDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              dueDate.hour,
                              dueDate.minute,
                            );
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
                            dueDate = DateTime(
                              dueDate.year,
                              dueDate.month,
                              dueDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: setReminder,
                          onChanged: (value) {
                            setModalState(() {
                              setReminder = value ?? false;
                            });
                          },
                        ),
                        Text("Update Reminder"),
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
  
                    await task.save();
  
                    if (setReminder) {
                      bool granted = await NotificationService.requestPermission();
                      if (granted) {
                        NotificationService.scheduleNotification(
                          id: task.key,
                          title: "Task Reminder",
                          body: task.title,
                          scheduledTime: task.dueDate,
                        );
                      }
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
      builder: (context) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
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
                  );
                },
              ),
            ),
            if (completedTasks.isNotEmpty)
              TextButton(
                onPressed: () {
                  for (var task in completedTasks) {
                    task.delete();
                  }
                  Navigator.of(context).pop();
                },
                child: Text("Clear History", style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }

  void _completeTask(Task task) {
    if (task.completed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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

    // ✅ Only increment streak if it's a new day
    if (lastCompletedDate == null || lastCompletedDate.isBefore(today)) {
      settings.taskStreak += 1;
      settings.lastTaskCompletedAt = today;
    }

    settings.xp += 10;
    task.streakCount = settings.taskStreak;

    task.save();
    settings.save();
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
                                  ),
                                  elevation: 3,
                                  child: InkWell(
                                    onTap: () => _editTask(task, dateFormat), // 👈 Add this
                                    child: ListTile(
                                    leading: Checkbox(
                                      value: task.completed,
                                      onChanged: (_) => _completeTask(task),
                                    ),
                                    title: Text(task.title),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Due: ${DateFormat(dateFormat).format(task.dueDate)} • "
                                          "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}",
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            // Manually awarded stars
                                            ...List.generate(
                                              3,
                                              (index) => Icon(
                                                index < task.stars ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                            ),
                                            // Auto stars (gray-colored)
                                            if (task.autoStars > 0) ...[
                                              SizedBox(width: 4),
                                              Text("+"),
                                              SizedBox(width: 2),
                                              ...List.generate(
                                                task.autoStars,
                                                (index) => Icon(
                                                  Icons.star,
                                                  color: Colors.grey,
                                                  size: 18,
                                                ),
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
