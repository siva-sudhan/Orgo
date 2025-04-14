import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class FinancePage extends StatefulWidget {
  @override
  _FinancePageState createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late Box<Transaction> transactionBox;
  late Box<UserSettings> settingsBox;
  
  List<String> defaultCategories = ["General", "Food", "Transport", "Shopping", "Bills", "Other"];
  List<String> customCategories = [];
  List<String> selectedCategories = [];
  DateTime selectedDate = DateTime.now();
  String? animatedAmountText;
  Color animatedAmountColor = Colors.green;
  bool animateUpward = true;
  AudioPlayer audioPlayer = AudioPlayer();
  bool showTotalBalance = false; // true = total balance, false = daily balance
  bool isBalanceVisible = false;
  int _selectedIndex = 1;
  final List<DateTime> _dateCarousel = [];

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<Transaction>('transactions');
    settingsBox = Hive.box<UserSettings>('settings');
    customCategories = (settingsBox.get('user')?.customCategories ?? []).cast<String>();
    _generateDateCarousel();
  }

  void _generateDateCarousel() {
    _dateCarousel.clear();
    for (int i = -1; i <= 1; i++) {
      _dateCarousel.add(selectedDate.add(Duration(days: i)));
    }
  }

  Future<void> _attemptUnlock() async {
    final settings = settingsBox.get('user') ?? UserSettings();
    settings.fixNulls();
    if (!settings.hideBalance) return;

    final success = await AuthService.authenticateUser();
    if (success) {
      setState(() {
        isBalanceVisible = true;
      });
    }
  }

  void showTransactionFeedback(double amount, bool isIncome) async {
    setState(() {
      animatedAmountText =
          isIncome ? "+₹${amount.toStringAsFixed(2)}" : "-₹${amount.toStringAsFixed(2)}";
      animatedAmountColor = isIncome ? Colors.green : Colors.red;
      animateUpward = isIncome;
    });
  
    await Future.delayed(Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  
    final soundPath = isIncome ? 'sounds/income.wav' : 'sounds/expense.wav';
    await audioPlayer.play(AssetSource(soundPath));
  }

  void _addCustomCategoryDialog() {
    final categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Custom Category"),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final cat = categoryController.text.trim();
              if (cat.isNotEmpty && !customCategories.contains(cat)) {
                setState(() {
                  customCategories.add(cat);
                });
                final updated = settingsBox.get('user')!;
                updated.customCategories = customCategories;
                updated.save();
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  void _setLimitForCategory(String category) {
    final limitController = TextEditingController();
    final currentLimit = settingsBox.get('user')?.spendingLimits[category];
    if (currentLimit != null) {
      limitController.text = currentLimit.toString();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Set Limit for $category"),
        content: TextField(
          controller: limitController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter limit amount"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = double.tryParse(limitController.text.trim());
              if (val != null) {
                final updated = settingsBox.get('user')!;
                updated.spendingLimits[category] = val;
                updated.save();
              }
              Navigator.pop(context);
            },
            child: Text("Set"),
          )
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Date',
    );
  
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  
  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
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
                  settings.save(); // ✅ Required
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
  void _addOrEditTransaction({Transaction? transaction, int? index, bool? isIncomePreset}) {
    final titleController = TextEditingController(text: transaction?.title ?? '');
    final amountController =
        TextEditingController(text: transaction != null ? transaction.amount.toString() : '');
    final settings = settingsBox.get('user') ?? UserSettings();
    settings.fixNulls();
    final activeProfile = settings.activeProfile;
    final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';
    DateTime selectedDate = transaction?.date ?? DateTime.now();
    String category = transaction?.category ?? "General";
    final isEditing = transaction != null;
    bool isIncome = isEditing
        ? transaction!.isIncome
        : (isIncomePreset ?? false); // respect preset for adding only

    final allCategories = [...defaultCategories, ...customCategories];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(transaction == null ? "Add Transaction" : "Edit Transaction"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: category,
                    onChanged: (newValue) {
                      setState(() {
                        category = newValue!;
                      });
                    },
                    items: allCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: "Enter title"),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: "Enter amount"),
                  ),
                  if (isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => isIncome = true),
                        child: Text("Add Income"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIncome ? Colors.green : Colors.grey[300],
                          foregroundColor: isIncome ? Colors.white : Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => isIncome = false),
                        child: Text("Add Spending"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isIncome ? Colors.red : Colors.grey[300],
                          foregroundColor: !isIncome ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    child: Text("Pick Date: ${DateFormat(dateFormat).format(selectedDate)}"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (transaction != null)
                TextButton(
                  onPressed: () {
                    transaction.delete();
                    Navigator.of(context).pop();
                  },
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty) {
                    String finalTitle = titleController.text.trim().isEmpty ? category : titleController.text.trim();
                    final newTx = Transaction(
                      title: finalTitle,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      date: selectedDate,
                      category: category,
                      isIncome: isIncome,
                      profileName: activeProfile,
                    );

                    if (isEditing && index != null) {
                      transactionBox.putAt(index, newTx);
                    } else {
                      transactionBox.add(newTx);
                      showTransactionFeedback(newTx.amount, newTx.isIncome);
                    }

                    Navigator.of(context).pop();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: isIncome ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isEditing ? "Save" : "Add"),
              )
            ],
          );
        });
      },
    );
  }

  double calculateBalance(List<Transaction> transactions, String profileName) {
    double balance = 0.0;
    for (var tx in transactions) {
      if (tx.profileName == profileName) {
        balance += tx.isIncome ? tx.amount : -tx.amount;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final settings = settingsBox.get('user') ?? UserSettings();
    settings.fixNulls();
    final activeProfile = settings.activeProfile;
    final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';
    final currency = settings.currency.isNotEmpty ? settings.currency : '\$';

    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: transactionBox.listenable(),
      builder: (context, box, _) {
        final allTransactions = box.values.toList();
        final balance = calculateBalance(allTransactions, activeProfile);

        final transactions = box.values.where((tx) {
          final isSameDate = DateFormat('yyyy-MM-dd').format(tx.date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          final isInSelectedCategory = selectedCategories.isEmpty || selectedCategories.contains(tx.category);
          final isInActiveProfile = tx.profileName == activeProfile;
          return (showTotalBalance || isSameDate) && isInSelectedCategory && isInActiveProfile;
        }).toList();

        final categoryTotals = <String, double>{};
        for (var tx in transactions) {
          if (!tx.isIncome) {
            categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Finance"),
            actions: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Tooltip(
                      message: "Toggle between today's transactions and total balance",
                      child: ToggleButtons(
                        isSelected: [!showTotalBalance, showTotalBalance],
                        onPressed: (index) {
                          setState(() => showTotalBalance = index == 1);
                        },
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Colors.white,
                        fillColor: Colors.deepPurple,
                        splashColor: Colors.deepPurpleAccent.withOpacity(0.2),
                        selectedBorderColor: Colors.deepPurple,
                        borderColor: Colors.transparent,
                        borderWidth: 0.8,
                        constraints: BoxConstraints(minWidth: 48, minHeight: 36),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Today", style: TextStyle(fontSize: 14)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("Total", style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined),
                    tooltip: "Switch Profile",
                    onPressed: () => _showProfileSwitcherDialog(settings),
                  ),
                  IconButton(
                    icon: Icon(Icons.category),
                    tooltip: "Add Custom Category",
                    onPressed: _addCustomCategoryDialog,
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if ((settings.hideBalance) && !isBalanceVisible) {
                              _attemptUnlock();
                            }
                          },
                          child: Row(
                            children: [
                              Text("Balance (${activeProfile}):", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                              Text(
                                settings.hideBalance && !isBalanceVisible
                                    ? "$currency••••••"
                                    : "$currency${balance.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: balance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                settings.hideBalance && !isBalanceVisible ? Icons.lock : Icons.lock_open,
                                size: 18,
                                color: settings.hideBalance && !isBalanceVisible ? Colors.grey : Colors.green,
                              ),
                              const SizedBox(width: 10),
                            ],
                          )
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity != null) {
                                if (details.primaryVelocity! < 0) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    selectedDate = selectedDate.add(Duration(days: 1));
                                    _generateDateCarousel();
                                  });
                                } else if (details.primaryVelocity! > 0) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    selectedDate = selectedDate.subtract(Duration(days: 1));
                                    _generateDateCarousel();
                                  });
                                }
                              }
                            },
                            child: SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _dateCarousel.length,
                                itemBuilder: (context, index) {
                                  final date = _dateCarousel[index];
                                  final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                                      DateFormat('yyyy-MM-dd').format(selectedDate);

                                  return GestureDetector(
                                    onTap: () async {
                                      if (isSelected) {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            selectedDate = picked;
                                            _generateDateCarousel();
                                          });
                                        }
                                      } else {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          selectedDate = date;
                                          _generateDateCarousel();
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('E').format(date),
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : Colors.grey,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('d MMM').format(date),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isSelected ? Colors.black : Colors.grey,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedDate = DateTime.now();
                              _generateDateCarousel();
                            });
                          },
                          child: Text("Today"),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: ExpansionTile(
                        title: Text(
                          selectedCategories.isEmpty
                              ? "Filter by Categories"
                              : "Filtered: ${selectedCategories.join(', ')}",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Wrap(
                            spacing: 10,
                            children: [
                              ...[...defaultCategories, ...customCategories].map((cat) {
                                final isSelected = selectedCategories.contains(cat);
                                return FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedCategories.add(cat);
                                      } else {
                                        selectedCategories.remove(cat);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              child: Text("Clear Filters"),
                              onPressed: () {
                                setState(() {
                                  selectedCategories.clear();
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return GestureDetector(
                          onTap: () => _addOrEditTransaction(transaction: tx, index: index),
                          onLongPress: () {
                            if (!tx.isIncome) _setLimitForCategory(tx.category);
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx.isIncome ? Colors.green : Colors.red,
                                child: Icon(
                                  tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(tx.title),
                              subtitle: Text(
                                "${DateFormat(dateFormat).format(tx.date)} • ${tx.category}",
                              ),
                              trailing: Text(
                                "${tx.isIncome ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: tx.isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (animatedAmountText != null)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: Duration(seconds: 2),
                          onEnd: () {
                            setState(() {
                              animatedAmountText = null;
                            });
                          },
                          builder: (context, opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: animateUpward
                                    ? Offset(0, -100 * (1 - opacity))
                                    : Offset(0, 100 * (1 - opacity)),
                                child: Text(
                                  animatedAmountText!,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: animatedAmountColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrEditTransaction(isIncomePreset: true),
                    icon: Icon(Icons.arrow_upward, color: Colors.white),
                    label: Text("Add Income"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrEditTransaction(isIncomePreset: false),
                    icon: Icon(Icons.arrow_downward, color: Colors.white),
                    label: Text("Add Spending"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
