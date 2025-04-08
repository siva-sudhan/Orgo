import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<Transaction>('transactions');
    settingsBox = Hive.box<UserSettings>('settings');
    customCategories = (settingsBox.get('user')?.customCategories ?? []).cast<String>();
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
  
  void _goToPreviousDate() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
  }
  
  void _goToNextDate() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
  }

  void _addOrEditTransaction({Transaction? transaction, int? index}) {
    final titleController = TextEditingController(text: transaction?.title ?? '');
    final amountController =
        TextEditingController(text: transaction != null ? transaction.amount.toString() : '');
    final settings = settingsBox.get('user') ?? UserSettings();
    final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';
    DateTime selectedDate = transaction?.date ?? DateTime.now();
    String category = transaction?.category ?? "General";
    bool isIncome = transaction?.isIncome ?? false;

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
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: "Enter title"),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: "Enter amount"),
                  ),
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
                  if (titleController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    final newTx = Transaction(
                      title: titleController.text,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      date: selectedDate,
                      category: category,
                      isIncome: isIncome,
                    );

                    if (transaction != null && index != null) {
                      transactionBox.putAt(index, newTx);
                    } else {
                      transactionBox.add(newTx);
                      showTransactionFeedback(newTx.amount, newTx.isIncome);
                    }

                    if (!isIncome) {
                      final settings = settingsBox.get('user')!;
                      final categoryTotal = transactionBox.values
                          .where((t) => !t.isIncome && t.category == category)
                          .fold<double>(0.0, (sum, t) => sum + t.amount);
                      final limit = settings.spendingLimits[category] ?? double.infinity;
                      if (categoryTotal > limit) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Limit Exceeded"),
                            content: Text("You have exceeded the limit for $category!"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Okay"),
                              )
                            ],
                          ),
                        );
                      }
                    }

                    Navigator.of(context).pop();
                  }
                },
                child: Text(transaction == null ? "Add" : "Save"),
              )
            ],
          );
        });
      },
    );
  }

  double calculateBalance(List<Transaction> transactions) {
    double balance = 0.0;
    for (var tx in transactions) {
      balance += tx.isIncome ? tx.amount : -tx.amount;
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: transactionBox.listenable(),
      builder: (context, box, _) {
        final settings = settingsBox.get('user') ?? UserSettings();
        final dateFormat = settings.dateTimeFormat.isNotEmpty ? settings.dateTimeFormat : 'dd MMM yy';
        final currency = settings.currency.isNotEmpty ? settings.currency : '\$';
        final limits = settings.spendingLimits;
        final allTransactions = box.values.toList();
        final balance = calculateBalance(allTransactions);

        // Transactions to show for selected date and filtered categories
        final transactions = box.values.where((tx) {
          final isSameDate = DateFormat('yyyy-MM-dd').format(tx.date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          final isInSelectedCategory = selectedCategories.isEmpty || selectedCategories.contains(tx.category);
          return (showTotalBalance || isSameDate) && isInSelectedCategory;
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
              IconButton(
                icon: Icon(Icons.category),
                onPressed: _addCustomCategoryDialog,
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
                        Text(
                          "Balance: $currency${balance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Row(
                          children: [
                            Text("Today"),
                            Switch(
                              value: showTotalBalance,
                              onChanged: (val) {
                                setState(() {
                                  showTotalBalance = val;
                                });
                              },
                            ),
                            Text("Total"),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_left),
                          onPressed: _goToPreviousDate,
                        ),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Row(
                            children: [
                              Text(
                                DateFormat(dateFormat).format(selectedDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_right),
                          onPressed: _goToNextDate,
                        ),
                        TextButton(
                          onPressed: _goToToday,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addOrEditTransaction(),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
