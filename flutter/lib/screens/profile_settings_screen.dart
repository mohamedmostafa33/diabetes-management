import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;
  String? _medicalHistory;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  
  bool _isEditing = false; // Flag to switch between read-only and edit modes

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name');
      _lastName = prefs.getString('last_name');
      _email = prefs.getString('user_email');
      _accountType = prefs.getString('account_type');
      _specialization = prefs.getString('specialization');
      _medicalHistory = prefs.getString('medical_history') ?? 'غير محدد';

      _firstNameController.text = _firstName ?? '';
      _lastNameController.text = _lastName ?? '';
      _specializationController.text = _specialization ?? '';
      _medicalHistoryController.text = _medicalHistory ?? '';
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('session_id');

      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الجلسة غير موجودة، يرجى تسجيل الدخول مجددًا')),
        );
        return;
      }

      try {
        Map<String, dynamic> data = {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
        };

        if (_accountType == 'doctor') {
          data['specialization'] = _specializationController.text;
        } else if (_accountType == 'patient') {
          data['medical_history'] = _medicalHistoryController.text;
        }

        final response = await http.put(
          Uri.parse('http://127.0.0.1:8000/api/update-profile/'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'sessionid=$sessionId',  // Sending the session cookie
          },
          body: jsonEncode(data),
        );

        if (response.statusCode == 200) {
          await prefs.setString('first_name', _firstNameController.text);
          await prefs.setString('last_name', _lastNameController.text);
          if (_accountType == 'doctor') {
            await prefs.setString('specialization', _specializationController.text);
          } else if (_accountType == 'patient') {
            await prefs.setString('medical_history', _medicalHistoryController.text);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
          );
          setState(() {
            _isEditing = false;  // Exit the editing mode
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تحديث الملف: ${response.statusCode} - ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الملف الشخصي'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _accountType == 'doctor'
                            ? 'assets/images/doctor_logo.png.webp'
                            : 'assets/images/patient_logo.png.webp',
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _email ?? 'الإيميل',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              readOnly: !_isEditing, // Make the field readonly unless editing
                              decoration: const InputDecoration(
                                labelText: 'الاسم الأول',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: Colors.teal),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال الاسم الأول';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              readOnly: !_isEditing, // Make the field readonly unless editing
                              decoration: const InputDecoration(
                                labelText: 'الاسم الأخير',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: Colors.teal),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال الاسم الأخير';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_accountType == 'doctor')
                              TextFormField(
                                controller: _specializationController,
                                readOnly: !_isEditing, // Make the field readonly unless editing
                                decoration: const InputDecoration(
                                  labelText: 'التخصص',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: Colors.teal),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال التخصص';
                                  }
                                  return null;
                                },
                              ),
                            if (_accountType == 'patient')
                              TextFormField(
                                controller: _medicalHistoryController,
                                readOnly: !_isEditing, // Make the field readonly unless editing
                                decoration: const InputDecoration(
                                  labelText: 'التاريخ الطبي',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: Colors.teal),
                                ),
                                maxLines: 3,
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isEditing ? _updateProfile : () {
                                setState(() {
                                  _isEditing = true; // Switch to edit mode
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _isEditing ? 'تحديث' : 'تعديل',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
