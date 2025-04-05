import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_settings.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Box<UserSettings> settingsBox;
  late UserSettings settings;

  final _nameController = TextEditingController();

  final List<String> currencyOptions = ['\$', '€', '£', '₹', '¥', '₩'];
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> dateFormats = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'dd MMM yyyy',
    'dd MMM yy',
  ];

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<UserSettings>('settings');
    settings = settingsBox.get('user') as UserSettings? ?? UserSettings();
    _nameController.text = settings.name;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imageFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Image',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            '${_nameController.text.trim().replaceAll(' ', '_')}_profile.jpg';
        final savedImage =
            await File(croppedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          settings.profileImagePath = savedImage.path;
        });
        settingsBox.put('user', settings);
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: settings.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        settings.dateOfBirth = picked;
      });
      settingsBox.put('user', settings);
    }
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _updateSettings() {
    settings.name = _nameController.text;
    settingsBox.put('user', settings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile Updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: settings.profileImagePath.isNotEmpty
                    ? FileImage(File(settings.profileImagePath))
                    : null,
                backgroundColor: Colors.deepPurple,
                child: settings.profileImagePath.isEmpty
                    ? Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : '?',
                        style: TextStyle(fontSize: 40, color: Colors.white),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (_) => settings.name = _nameController.text,
            ),

            SizedBox(height: 20),

            // Profile Settings
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Profile Settings",
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(height: 10),

            // Date of Birth
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Date of Birth"),
              subtitle: Text(
                settings.dateOfBirth != null
                    ? "${DateFormat('dd MMM yyyy').format(settings.dateOfBirth!)} (${_calculateAge(settings.dateOfBirth!).toString()} years)"
                    : "Not set",
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: _pickDateOfBirth,
            ),
            SizedBox(height: 10),

            // Gender
            DropdownButtonFormField<String>(
              value: genderOptions.contains(settings.gender)
                  ? settings.gender
                  : null,
              decoration: InputDecoration(labelText: 'Gender'),
              items: genderOptions.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() => settings.gender = value ?? '');
                settingsBox.put('user', settings);
              },
            ),

            SizedBox(height: 20),

            // Finance Settings
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Finance Settings",
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(height: 10),

            // Currency
            DropdownButtonFormField<String>(
              value: currencyOptions.contains(settings.currency)
                  ? settings.currency
                  : null,
              decoration: InputDecoration(labelText: 'Currency'),
              items: currencyOptions.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                setState(() => settings.currency = value ?? '\$');
                settingsBox.put('user', settings);
              },
            ),

            SizedBox(height: 20),

            // Task Settings
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Task Settings",
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(height: 10),

            // Date Format
            DropdownButtonFormField<String>(
              value: dateFormats.contains(settings.dateTimeFormat)
                  ? settings.dateTimeFormat
                  : 'dd MMM yy',
              decoration: InputDecoration(labelText: 'Date Format'),
              items: dateFormats
                  .where((format) => format != 'yyyy-MM-dd')
                  .map((format) {
                final now = DateTime.now();
                final formatted = DateFormat(format).format(now);
                return DropdownMenuItem(
                    value: format, child: Text("$format  ($formatted)"));
              }).toList(),
              onChanged: (value) {
                setState(() => settings.dateTimeFormat = value ?? 'dd MMM yy');
                settingsBox.put('user', settings);
              },
            ),

            SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _updateSettings,
              icon: Icon(Icons.save),
              label: Text("Save"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
