import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    return ValueListenableBuilder<Box<UserSettings>>(
      valueListenable: Hive.box<UserSettings>('settings').listenable(),
      builder: (context, settingsBox, _) {
        final settings = settingsBox.get('user') ?? UserSettings();
        final userName = settings.name.isNotEmpty ? settings.name : 'Friend';
        final currency = settings.currency;

        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: Hive.box<Transaction>('transactions').listenable(),
          builder: (context, transactionBox, _) {
            final transactions = transactionBox.values.toList();
            double balance = 0.0;
            Map<String, double> categoryMap = {};

            for (var tx in transactions) {
              balance += tx.isIncome ? tx.amount : -tx.amount;
              if (!tx.isIncome) {
                categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
              }
            }

            return ValueListenableBuilder<Box<Task>>(
              valueListenable: Hive.box<Task>('tasks').listenable(),
              builder: (context, taskBox, _) {
                final tasks = taskBox.values.toList();
                int completedTasks = tasks.where((task) => task.completed).length;
                int totalTasks = tasks.length;

                double progress = settings.xp / (settings.level * 100);
                if (progress > 1.0) progress = 1.0;

                return Scaffold(
                  appBar: AppBar(title: const Text("Orgo Dashboard")),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${getGreeting()}, $userName 👋",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // XP Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Level: ${settings.level}", style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("XP: ${settings.xp}"),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Balance Card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            title: const Text("Total Balance", style: TextStyle(fontSize: 18)),
                            subtitle: Text(
                              "$currency${balance.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 22,
                                color: balance >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Pie Chart
                        if (categoryMap.isNotEmpty)
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Spending by Category",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  PieChart(
                                    dataMap: categoryMap,
                                    animationDuration: const Duration(milliseconds: 800),
                                    chartType: ChartType.ring,
                                    chartValuesOptions: const ChartValuesOptions(
                                        showChartValuesInPercentage: true),
                                    colorList: [
                                      Colors.blue,
                                      Colors.orange,
                                      Colors.green,
                                      Colors.purple,
                                      Colors.red,
                                      Colors.brown,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Tasks Overview
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            title: const Text("Tasks Overview"),
                            subtitle: Text(
                              "$completedTasks of $totalTasks tasks completed",
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.task_alt, color: Colors.deepPurple),
                          ),
                        ),

                        if (transactions.isEmpty && tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Center(
                              child: Text(
                                "No data yet. Start adding tasks or transactions!",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
