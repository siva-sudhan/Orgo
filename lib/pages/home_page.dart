import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/transaction.dart';
import '../models/task.dart';
import '../models/user_settings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<UserSettings>('settings');
    final transactionBox = Hive.box<Transaction>('transactions');
    final taskBox = Hive.box<Task>('tasks');

    final settings = settingsBox.get('user') ?? UserSettings();
    final currency = settings.currency;
    final userName = settings.name.isNotEmpty ? settings.name : 'Friend';

    final transactions = transactionBox.values.toList();
    final tasks = taskBox.values.toList();

    double balance = 0.0;
    Map<String, double> categoryMap = {};
    int completedTasks = 0;
    int totalTasks = tasks.length;

    for (var tx in transactions) {
      balance += tx.isIncome ? tx.amount : -tx.amount;
      if (!tx.isIncome) {
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
      }
    }

    for (var task in tasks) {
      if (task.completed) completedTasks++;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Orgo Dashboard")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${getGreeting()}, $userName 👋",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: ListTile(
                title: Text("Total Balance", style: TextStyle(fontSize: 18)),
                subtitle: Text(
                  "$currency${balance.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 22,
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 20),
            if (categoryMap.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Spending by Category",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 10),
                      PieChart(
                        dataMap: categoryMap,
                        animationDuration: Duration(milliseconds: 800),
                        chartType: ChartType.ring,
                        chartValuesOptions: ChartValuesOptions(showChartValuesInPercentage: true),
                        colorList: [
                          Colors.blue,
                          Colors.orange,
                          Colors.green,
                          Colors.purple,
                          Colors.red,
                          Colors.brown
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: ListTile(
                title: Text("Tasks Overview"),
                subtitle: Text(
                    "$completedTasks of $totalTasks tasks completed",
                    style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.task_alt, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
