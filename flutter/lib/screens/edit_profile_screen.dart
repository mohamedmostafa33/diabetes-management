import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_/services/http_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  String? _accountType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _specializationController.text = prefs.getString('specialization') ?? '';
      _medicalHistoryController.text = prefs.getString('medical_history') ?? '';
      _accountType = prefs.getString('account_type');
    });

    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && refreshToken != null) {
      HttpService().setTokens(accessToken, refreshToken);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var requestBody = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
      };

      if (_accountType == 'doctor') {
        requestBody['specialization'] = _specializationController.text.trim();
      } else if (_accountType == 'patient') {
        requestBody['medical_history'] = _medicalHistoryController.text.trim();
      }

      var response = await HttpService().makeRequest(
        method: 'PUT',
        url: Uri.parse('http://10.0.2.2:8000/api/update-profile/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response == null) {
        _showSnackBar('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (response.statusCode == 200) {
        await prefs.setString('first_name', _firstNameController.text.trim());
        await prefs.setString('last_name', _lastNameController.text.trim());
        if (_accountType == 'doctor') {
          await prefs.setString('specialization', _specializationController.text.trim());
        } else if (_accountType == 'patient') {
          await prefs.setString('medical_history', _medicalHistoryController.text.trim());
        }

        _showSnackBar('تم تحديث البيانات بنجاح!', Colors.green);
        Navigator.pop(context, true);
      } else {
        var responseData = jsonDecode(response.body);
        _showSnackBar(responseData['message'] ?? 'حدث خطأ أثناء تحديث البيانات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الأول',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الاسم الأول';
                    }
                    if (!RegExp(r'^[\p{L}]+$', unicode: true).hasMatch(value)) {
                      return 'الاسم الأول يجب أن يحتوي على حروف فقط';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الأخير',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الاسم الأخير';
                    }
                    if (!RegExp(r'^[\p{L}]+$', unicode: true).hasMatch(value)) {
                      return 'الاسم الأخير يجب أن يحتوي على حروف فقط';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_accountType == 'doctor')
                  TextFormField(
                    controller: _specializationController,
                    decoration: const InputDecoration(
                      labelText: 'التخصص',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال التخصص';
                      }
                      if (value.length < 3) {
                        return 'التخصص يجب أن يكون 3 حروف على الأقل';
                      }
                      return null;
                    },
                  ),
                if (_accountType == 'patient')
                  TextFormField(
                    controller: _medicalHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'السجل الصحي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: const Text(
                              'حفظ التعديلات',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _cancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}