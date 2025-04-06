import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home_page.dart';
import 'pages/tasks_page.dart';
import 'pages/finance_page.dart';
import 'pages/profile_page.dart';
import 'models/task.dart';
import 'models/transaction.dart';
import 'models/user_settings.dart';
import 'services/notification_service.dart'; // ✅ Local notification support
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //🧠 Uncomment below if you need to wipe Hive data during development
  final appDir = await getApplicationDocumentsDirectory();
  final hiveFiles = Directory(appDir.path)
      .listSync()
      .where((f) => f.path.endsWith('.hive'))
      .toList();
  for (var file in hiveFiles) {
    print('Deleting Hive file: ${file.path}');
    await File(file.path).delete();
  }

  // ✅ Initialize Hive and register adapters
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

  // ✅ Open Hive boxes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<UserSettings>('settings');

  // ✅ Initialize local notifications
  await NotificationService.initialize();
  await NotificationService.requestPermission();

  runApp(const OrgoApp());
}

class OrgoApp extends StatelessWidget {
  const OrgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
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
        title: const Text('Orgo'),
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