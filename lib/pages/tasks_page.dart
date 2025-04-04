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
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Task"),
              content: Column(
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
                        setState(() {
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
                        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserSettings>('settings').listenable(),
      builder: (context, Box<UserSettings> settingsBox, _) {
        final settings = settingsBox.get('settings') ?? UserSettings();
        final dateFormat = settings.dateTimeFormat.isNotEmpty
            ? settings.dateTimeFormat
            : 'dd MMM yyyy';

        return ValueListenableBuilder(
          valueListenable: taskBox.listenable(),
          builder: (context, Box<Task> box, _) {
            final tasks = box.values.toList();

            return Scaffold(
              body: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: ListTile(
                      leading: Checkbox(
                        value: task.completed,
                        onChanged: task.completed
                            ? null
                            : (val) {
                                task.completed = true;
                                task.completedAt = DateTime.now();
                                task.save();
                              },
                      ),
                      title: Text(task.title),
                      subtitle: Text(
                        "Due: ${DateFormat(dateFormat).format(task.dueDate)} • ${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')} • ${'★' * task.stars}${'☆' * (3 - task.stars)}",
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          box.deleteAt(index);
                        },
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
