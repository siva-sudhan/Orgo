import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home_page.dart';
import 'pages/tasks_page.dart';
import 'pages/finance_page.dart';
import 'pages/profile_page.dart';
import 'models/task.dart';
import 'models/transaction.dart';
import 'models/user_settings.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters for both Tasks and Transactions
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TransactionAdapter()); // Register Transaction model
  Hive.registerAdapter(UserSettingsAdapter());

  // Open Hive Boxes
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Transaction>('transactions'); // Open Transaction box
  await Hive.openBox<UserSettings>('settings');

  runApp(OrgoApp());
}

class OrgoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    FinancePage(),
    TasksPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orgo'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

