import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user_settings.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Box<Task> taskBox;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  void _addTask() {
    final titleController = TextEditingController();
    DateTime dueDate = DateTime.now().add(Duration(hours: 1));

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
                      child: Text("Pick Due Date: ${DateFormat('dd MMM yy').format(dueDate)}"),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newTask = Task(
                        title: titleController.text,
                        dueDate: dueDate,
                        stars: 0,
                        completed: false,
                        completedAt: null,
                      );
                      taskBox.add(newTask);
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

  void _showCompletedTasks(List<Task> completedTasks, String dateFormat) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: completedTasks.length,
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            return ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text(task.title),
              subtitle: Text(
                "Completed: ${DateFormat(dateFormat).format(task.completedAt!)} • ${'★' * task.stars}${'☆' * (3 - task.stars)}",
              ),
            );
          },
        );
      },
    );
  }

  void _completeTask(Task task) {
    if (task.completed) return;

    final now = DateTime.now();
    final duration = task.dueDate.difference(now).inSeconds;
    int stars = 1;

    if (duration >= 0) {
      final totalTime = task.dueDate.difference(now.subtract(Duration(hours: 1))).inSeconds;
      final elapsed = totalTime - duration;
      final percent = elapsed / totalTime;

      if (percent <= 0.25) {
        stars = 3;
      } else if (percent <= 0.5) {
        stars = 2;
      }
    }

    task.completed = true;
    task.completedAt = now;
    task.stars = stars;
    task.save();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserSettings>('settings').listenable(keys: ['user']),
      builder: (context, settingsBox, _) {
        final settings = settingsBox.get('user') ?? UserSettings();
        final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';

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
              body: pendingTasks.isEmpty
                  ? Center(child: Text("No pending tasks"))
                  : ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: pendingTasks.length,
                      itemBuilder: (context, index) {
                        final task = pendingTasks[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: Checkbox(
                              value: task.completed,
                              onChanged: (val) {
                                _completeTask(task);
                              },
                            ),
                            title: Text(task.title),
                            subtitle: Text(
                              "Due: ${DateFormat(dateFormat).format(task.dueDate)} • "
                              "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')} • "
                              "${'★' * task.stars}${'☆' * (3 - task.stars)}",
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => task.delete(),
                            ),
                          ),
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: _addTask,
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
