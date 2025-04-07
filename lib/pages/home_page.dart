import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/transaction.dart';
import '../models/task.dart';
import '../models/user_settings.dart';
import '../widgets/level_progress_card.dart';

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
        final profileImagePath = settings.profileImagePath;
        final hasProfileImage = profileImagePath.isNotEmpty && File(profileImagePath).existsSync();
        final profileImageFile = hasProfileImage ? File(profileImagePath) : null;
        final currency = settings.currency;
        final streak = settings.taskStreak;
        final dateFormat = settings.dateTimeFormat;
        final limits = settings.spendingLimits;

        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: Hive.box<Transaction>('transactions').listenable(),
          builder: (context, transactionBox, _) {
            final transactions = transactionBox.values.toList();
            double balance = 0.0;
            Map<String, double> categoryMap = {};

            for (var tx in transactions) {
              balance += tx.isIncome ? tx.amount : -tx.amount;
              if (!tx.isIncome) {
                categoryMap[tx.category] =
                    (categoryMap[tx.category] ?? 0) + tx.amount;
              }
            }

            return ValueListenableBuilder<Box<Task>>(
              valueListenable: Hive.box<Task>('tasks').listenable(),
              builder: (context, taskBox, _) {
                final tasks = taskBox.values.toList();
                int completedTasks =
                    tasks.where((task) => task.completed).length;
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: hasProfileImage ? FileImage(profileImageFile!) : null,
                              backgroundColor: Colors.deepPurple,
                              child: !hasProfileImage
                                  ? Text(
                                      userName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 18, color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${getGreeting()}, $userName 👋",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (streak > 0) ...[
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Colors.orange, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                "$streak-Day Streak",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            title: const Text("Total Balance",
                                style: TextStyle(fontSize: 18)),
                            subtitle: Text(
                              "$currency${balance.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 22,
                                color:
                                    balance >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (categoryMap.isNotEmpty)
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Spending by Category",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  PieChart(
                                    dataMap: categoryMap,
                                    animationDuration:
                                        const Duration(milliseconds: 800),
                                    chartType: ChartType.ring,
                                    chartValuesOptions:
                                        const ChartValuesOptions(
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
                                  const SizedBox(height: 10),

                                  // 🛑 Spending Limit Warnings
                                  ...categoryMap.entries.map((entry) {
                                    final limit = limits[entry.key];
                                    if (limit != null &&
                                        entry.value > limit) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning,
                                                color: Colors.red, size: 20),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "${entry.key} spending exceeded! Limit: $currency${limit.toStringAsFixed(2)} | Used: $currency${entry.value.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        LevelProgressCard(
                          xp: settings.xp,
                          level: settings.level,
                          xpToNextLevel: settings.xp % 100,
                        ),

                        const SizedBox(height: 20),

                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            title: const Text("Tasks Overview"),
                            subtitle: Text(
                              "$completedTasks of $totalTasks tasks completed",
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.task_alt,
                                color: Colors.deepPurple),
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
