import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/user_settings.dart';

class FinancePage extends StatefulWidget {
  @override
  _FinancePageState createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late Box<Transaction> transactionBox;
  late Box<UserSettings> settingsBox;

  @override
  void initState() {
    super.initState();
    transactionBox = Hive.box<Transaction>('transactions');
    settingsBox = Hive.box<UserSettings>('settings');
  }

  void _addTransaction() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String category = "General";
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Add Transaction"),
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
                    items: ["General", "Food", "Transport", "Shopping", "Bills", "Other"]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isIncome,
                        onChanged: (val) {
                          setState(() {
                            isIncome = val!;
                          });
                        },
                      ),
                      Text("Is Income?")
                    ],
                  ),
                  TextButton(
                    child: Text("Pick Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}"),
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
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Add"),
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      amountController.text.isNotEmpty) {
                    final newTransaction = Transaction(
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      date: selectedDate,
                      category: category,
                      isIncome: isIncome,
                    );
                    transactionBox.add(newTransaction);
                    Navigator.of(context).pop();
                  }
                },
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
    return ValueListenableBuilder(
      valueListenable: transactionBox.listenable(),
      builder: (context, Box<Transaction> box, _) {
        final settings = settingsBox.get('user') ?? UserSettings();
        final currency = settings.currency.isNotEmpty ? settings.currency : '\$';
        final transactions = box.values.toList();

        final balance = calculateBalance(transactions);

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Balance", style: TextStyle(fontSize: 18)),
                    Text(
                      "$currency${balance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? Center(child: Text("No transactions yet"))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[transactions.length - 1 - index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(tx.title),
                              subtitle: Text(
                                  "${tx.category} • ${DateFormat('dd MMM yyyy').format(tx.date)}"),
                              trailing: Text(
                                "${tx.isIncome ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: tx.isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
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
            onPressed: _addTransaction,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
