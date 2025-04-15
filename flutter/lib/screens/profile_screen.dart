import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileAndSettingsScreenState createState() => ProfileAndSettingsScreenState();
}

class ProfileAndSettingsScreenState extends State<ProfileScreen> {
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;
  String? _medicalHistory;
  bool _isLoading = false;
  Map<String, dynamic>? _linkedDoctor;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch profile data from API
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://127.0.0.1:8000/api/profile/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _email = responseData['email'];
          _firstName = responseData['first_name'];
          _lastName = responseData['last_name'];

          // Determine account type based on response fields
          if (responseData.containsKey('medical_history')) {
            _accountType = 'patient';
            _medicalHistory = responseData['medical_history'] ?? 'غير متوفر';
            _specialization = null;
          } else if (responseData.containsKey('specialization')) {
            _accountType = 'doctor';
            _specialization = responseData['specialization'] ?? 'غير محدد';
            _medicalHistory = null;
          } else {
            _accountType = null;
            _medicalHistory = null;
            _specialization = null;
          }
        });

        // Fetch linked doctor if the user is a patient
        if (_accountType == 'patient') {
          await _fetchLinkedDoctor();
        }
      } else {
        _showSnackBar('فشل جلب بيانات الملف الشخصي', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل تحميل البيانات: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLinkedDoctor() async {
    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://127.0.0.1:8000/api/my-doctor/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        debugPrint('Fetch Linked Doctor: Response is null');
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      debugPrint('My Doctor API Response Status: ${response.statusCode}');
      debugPrint('My Doctor API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('Parsed Response Data: $responseData');

        setState(() {
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            _linkedDoctor = null;
            debugPrint('No linked doctor found');
          } else if (responseData is Map<String, dynamic>) {
            _linkedDoctor = responseData;
            debugPrint('Linked doctor set: $_linkedDoctor');
          } else {
            _linkedDoctor = null;
            debugPrint('Unexpected response format');
          }
        });
      } else {
        debugPrint('Fetch Linked Doctor: Status code ${response.statusCode}');
        _showSnackBar('فشل جلب بيانات الدكتور المرتبط', Colors.red);
      }
    } catch (e) {
      debugPrint('Fetch Linked Doctor Error: $e');
      _showSnackBar('حدث خطأ: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الملف الشخصي',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient,
            ),
          ),
          elevation: 4,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      children: [
                        // الكارد الرئيسي
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.teal.shade50,
                                  Colors.white,
                                  Colors.teal.shade100,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // الصورة الرمزية
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.teal, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    backgroundImage: AssetImage(
                                      _accountType == 'doctor'
                                          ? 'assets/images/doctor_logo.png.webp'
                                          : 'assets/images/patient_logo.png.webp',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // الإيميل
                                Text(
                                  _email ?? 'الإيميل',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 8),
                                // الاسم
                                Text(
                                  '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.teal.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 8),
                                // نوع الحساب
                                Text(
                                  _accountType == 'doctor' ? 'دكتور' : 'مريض',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                  color: Colors.grey[300],
                                  thickness: 1.5,
                                ),
                                const SizedBox(height: 16),
                                // التخصص أو السجل الصحي
                                if (_accountType == 'doctor')
                                  Text(
                                    'التخصص: ${_specialization ?? 'غير محدد'}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                if (_accountType == 'patient') ...[
                                  Text(
                                    'السجل الصحي: ${_medicalHistory ?? 'غير متوفر'}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // كارد الدكتور المرتبط
                        if (_accountType == 'patient')
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الدكتور المرتبط',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.teal.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _linkedDoctor != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.person, color: Colors.teal, size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${_linkedDoctor!['first_name'] ?? 'غير متوفر'} ${_linkedDoctor!['last_name'] ?? ''}',
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                          color: Colors.black87,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.medical_services, color: Colors.teal, size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'التخصص: ${_linkedDoctor!['specialization'] ?? 'غير محدد'}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: Colors.grey[600],
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'لا يوجد دكتور مرتبط',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // زر تعديل البيانات
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                            if (result == true) {
                              await _loadUserData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'تعديل البيانات',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                              ),
                            ],
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