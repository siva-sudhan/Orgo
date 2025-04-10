import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_settings.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Box<UserSettings> settingsBox;
  late UserSettings settings;

  bool hideBalanceWithPasscode = false; // 🆕 local state
  final _nameController = TextEditingController();
  bool _hasChanges = false;

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
    hideBalanceWithPasscode = settings.hideBalance;
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100, // Ensures JPEG if camera is used
    );
  
    if (imageFile != null) {
      final croppedFile = await ImageCropper().cropImage(
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
        final cacheDir = await getTemporaryDirectory();
        final fileName =
            '${_nameController.text.trim().replaceAll(' ', '_')}_profile.jpg';
        final newImagePath = '${cacheDir.path}/$fileName';
  
        // Always compress and convert to JPEG
        final compressed = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          newImagePath,
          quality: 70,
          format: CompressFormat.jpeg,
        );
  
        if (compressed != null) {
          // Delete old image if exists
          if (settings.profileImagePath.isNotEmpty) {
            final oldFile = File(settings.profileImagePath);
            if (await oldFile.exists()) await oldFile.delete();
          }
  
          setState(() {
            settings.profileImagePath = compressed.path;
            _hasChanges = true;
          });

          settingsBox.put('user', settings);
        }
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    if (settings.profileImagePath.isNotEmpty) {
      final file = File(settings.profileImagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      settings.profileImagePath = '';
      _hasChanges = true;
    });
    settingsBox.put('user', settings);
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text("Take a Picture"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Remove Profile Picture"),
              onTap: () {
                Navigator.pop(context);
                _removeProfilePicture();
              },
            ),
          ],
        ),
      ),
    );
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
        _hasChanges = true;
      });
      settingsBox.put('user', settings);
    }
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _updateSettings() {
    settings.name = _nameController.text;
    settingsBox.put('user', settings);
    setState(() {
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile Updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileImagePath = settings.profileImagePath;
    File? profileImageFile;
    bool hasProfileImage = false;
    if (profileImagePath.isNotEmpty) {
      profileImageFile = File(profileImagePath);
      hasProfileImage = profileImageFile.existsSync();
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image with Edit Icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: hasProfileImage ? FileImage(profileImageFile!) : null,
                    backgroundColor: Colors.deepPurple,
                    child: !hasProfileImage
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : '?',
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                      onPressed: _showImageOptions,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
      
            // Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (_) {
                setState(() {
                  settings.name = _nameController.text;
                  _hasChanges = true;
                });
              },
            ),

            SizedBox(height: 20),
      
            // Settings collapsible section
            ExpansionTile(
              title: Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              children: [
      
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
                  value: genderOptions.contains(settings.gender) ? settings.gender : null,
                  decoration: InputDecoration(labelText: 'Gender'),
                  items: genderOptions.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      settings.gender = value ?? '';
                      _hasChanges = true;
                    });
                    settingsBox.put('user', settings);
                  },
                ),
      
                SizedBox(height: 20),
      
                // Currency
                DropdownButtonFormField<String>(
                  value: currencyOptions.contains(settings.currency) ? settings.currency : null,
                  decoration: InputDecoration(labelText: 'Currency'),
                  items: currencyOptions.map((currency) {
                    return DropdownMenuItem(value: currency, child: Text(currency));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      settings.currency = value ?? '\$';
                      _hasChanges = true;
                    });
                    settingsBox.put('user', settings);
                  },

                ),
      
                SizedBox(height: 20),
      
                // Date Format
                DropdownButtonFormField<String>(
                  value: dateFormats.contains(settings.dateTimeFormat) ? settings.dateTimeFormat : 'dd MMM yy',
                  decoration: InputDecoration(labelText: 'Date Format'),
                  items: dateFormats.map((format) {
                    final now = DateTime.now();
                    final formatted = DateFormat(format).format(now);
                    return DropdownMenuItem(value: format, child: Text("$format  ($formatted)"));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      settings.dateTimeFormat = value ?? 'dd MMM yy';
                      _hasChanges = true;
                    });
                    settingsBox.put('user', settings);
                  },
                ),
                SwitchListTile(
                  title: Text("Hide Balance with Passcode"),
                  subtitle: Text("Require Face ID / Fingerprint / Password to view balance"),
                  value: hideBalanceWithPasscode,
                  onChanged: (value) async {
                    setState(() {
                      hideBalanceWithPasscode = value;
                      settings.hideBalance = value;
                      _hasChanges = true;
                    });
                    await settings.save();
                  },
                  activeColor: Colors.deepPurple,
                ),
                SizedBox(height: 10),
              ],
            ),
      
            SizedBox(height: 30),
      
            ElevatedButton.icon(
              onPressed: _hasChanges ? _updateSettings : null,
              icon: Icon(Icons.save),
              label: Text("Save"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: _hasChanges ? Colors.deepPurple : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
