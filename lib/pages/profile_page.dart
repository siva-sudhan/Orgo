import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user_settings.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();

  final List<String> currencies = ['\$', '€', '₹', '£', '¥'];
  final List<String> dateFormats = ['dd MMM yy', 'MM/dd/yyyy', 'yyyy-MM-dd'];

  late Box<UserSettings> settingsBox;
  late UserSettings settings;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<UserSettings>('settings');
    settings = settingsBox.get('user') ?? UserSettings();

    nameController.text = settings.name;
    ageController.text = settings.age.toString();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = Platform.isIOS ? ImageSource.gallery : ImageSource.camera;
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final filename = p.basename(picked.path);
      final savedImage = await File(picked.path).copy('${appDir.path}/$filename');
      setState(() {
        settings.profileImagePath = savedImage.path;
      });
      await settingsBox.put('user', settings);
    }
  }

  void _saveProfile() {
    settings.name = nameController.text;
    settings.age = int.tryParse(ageController.text) ?? 18;
    settingsBox.put('user', settings);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile updated!")),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = settings.profileImagePath != null &&
            File(settings.profileImagePath!).existsSync()
        ? FileImage(File(settings.profileImagePath!))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImage,
              child: profileImage == null ? Icon(Icons.person, size: 50) : null,
            ),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text("Change Picture"),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Age"),
            ),
            _buildSectionTitle("Finance Settings"),
            DropdownButtonFormField<String>(
              value: settings.currency.isNotEmpty ? settings.currency : currencies.first,
              decoration: InputDecoration(labelText: "Currency"),
              items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() {
                  settings.currency = val!;
                  settingsBox.put('user', settings);
                });
              },
            ),
            _buildSectionTitle("Task Settings"),
            DropdownButtonFormField<String>(
              value: settings.dateTimeFormat.isNotEmpty
                  ? settings.dateTimeFormat
                  : dateFormats.first,
              decoration: InputDecoration(labelText: "Date Format"),
              items: dateFormats.map((df) => DropdownMenuItem(value: df, child: Text(df))).toList(),
              onChanged: (val) {
                setState(() {
                  settings.dateTimeFormat = val!;
                  settingsBox.put('user', settings);
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text("Save Changes"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}
