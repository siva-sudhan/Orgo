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
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onSectionTap;
  const HomePage({super.key, required this.onSectionTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isBalanceVisible = false;

  Future<void> _attemptUnlock() async {
    final success = await AuthService.authenticateUser();
    if (success) {
      setState(() {
        isBalanceVisible = true;
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showProfileSwitcherDialog(UserSettings settings) {
    settings.fixNulls();
    final controller = TextEditingController();
    final transactionBox = Hive.box<Transaction>('transactions');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Switch Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...settings.profileList.map((profile) => ListTile(
                title: Text(profile),
                trailing: settings.activeProfile == profile
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  settings.activeProfile = profile;
                  settings.save();
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                },
                onLongPress: () {
                  if (profile == 'Main') return; // Prevent deleting default profile

                  final hasTransactions = transactionBox.values
                      .where((tx) => tx.profileName == profile)
                      .isNotEmpty;

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Delete Profile"),
                      content: Text(
                        hasTransactions
                            ? "This profile has transactions. Are you sure you want to delete '$profile'?"
                            : "Are you sure you want to delete '$profile'?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            final updatedProfiles = settings.profileList.where((p) => p != profile).toList();
                            settings.profileList = updatedProfiles;

                            if (settings.activeProfile == profile) {
                              settings.activeProfile = 'Main';
                            }

                            settings.save();
                            Navigator.pop(context); // Close confirm
                            Navigator.pop(context); // Close profile dialog

                            if (mounted) setState(() {});
                          },
                          child: Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              )),
              const Divider(),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "New profile name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newProfile = controller.text.trim();
                final exists = settings.profileList
                    .map((p) => p.toLowerCase())
                    .contains(newProfile.toLowerCase());

                if (newProfile.isNotEmpty && !exists) {
                  final updatedProfiles = [...settings.profileList, newProfile];
                  settings.profileList = updatedProfiles;
                  settings.activeProfile = newProfile;
                  settings.save();
                  controller.clear(); // Optional: reset text field
                  setStateDialog(() {}); // ✅ make dialog refresh its list
                }
              },
              child: Text("Add"),
            )
          ],
        ),
      ),
    );
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
        final limits = settings.spendingLimits;
        final activeProfile = settings.activeProfile;
        final profiles = settings.profileList;

        return ValueListenableBuilder<Box<Transaction>>(
          valueListenable: Hive.box<Transaction>('transactions').listenable(),
          builder: (context, transactionBox, _) {
            final transactions = transactionBox.values
                .where((tx) => tx.profileName == activeProfile)
                .toList();

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
                int completedTasks =
                    tasks.where((task) => task.completed).length;
                int totalTasks = tasks.length;

                double progress = (settings.level > 0)
                    ? settings.xp / (settings.level * 100)
                    : 0.0;

                progress = progress.isNaN || progress < 0 ? 0.0 : progress;

                return Scaffold(
                  appBar: AppBar(title: const Text("Orgo Dashboard")),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end: progress,
                                    ),
                                    duration: Duration(milliseconds: 600),
                                    builder: (context, value, _) {
                                      return CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 6,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                      );
                                    },
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: hasProfileImage ? FileImage(profileImageFile!) : null,
                                  backgroundColor: Colors.deepPurple,
                                  child: !hasProfileImage
                                      ? Text(
                                          userName[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 22, color: Colors.white),
                                        )
                                      : null,
                                ),
                                if (streak > 0)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_fire_department, size: 16, color: Colors.white),
                                          const SizedBox(width: 2),
                                          Text(
                                            "$streak",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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

                        /// 🔐 Balance Card with Long Press Unlock
                        GestureDetector(
                          onTap: () => widget.onSectionTap(1),
                          onLongPress: () {
                            if (settings.hideBalance) {
                              _attemptUnlock();
                            }
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total Balance (${activeProfile})",
                                          style: TextStyle(fontSize: 18),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          settings.hideBalance && !isBalanceVisible
                                              ? "$currency••••••"
                                              : "$currency${balance.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 22,
                                            color: balance >= 0 ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: IconButton(
                                      icon: Icon(Icons.settings),
                                      onPressed: () => _showProfileSwitcherDialog(settings),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
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
                                                "${entry.key} exceeded! Limit: $currency${limit.toStringAsFixed(2)} | Used: $currency${entry.value.toStringAsFixed(2)}",
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

                        InkWell(
                          onTap: () => widget.onSectionTap(2),
                          child: Card(
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
