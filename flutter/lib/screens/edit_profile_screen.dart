import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  String? _accountType;
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

      if (_accountType == 'patient') {
        await _fetchLinkedDoctor();
      }
    } catch (e) {
      debugPrint('Load User Data Error: $e');
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
        url: Uri.parse('http://10.0.2.2:8000/api/my-doctor/'),
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

  Future<void> _unlinkFromDoctor() async {
    if (_linkedDoctor == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/unlink-from-doctor/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctor_id': _linkedDoctor!['id']}),
      );

      if (response == null) {
        debugPrint('Unlink Doctor: Response is null');
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      debugPrint('Unlink Doctor API Response Status: ${response.statusCode}');
      debugPrint('Unlink Doctor API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _linkedDoctor = null;
        });
        _showSnackBar('تم إلغاء الارتباط بالدكتور بنجاح', Colors.green);
      } else {
        debugPrint('Unlink Doctor: Status code ${response.statusCode}');
        _showSnackBar('فشل إلغاء الارتباط', Colors.red);
      }
    } catch (e) {
      debugPrint('Unlink Doctor Error: $e');
      _showSnackBar('حدث خطأ: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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

      if (!mounted) return;

      if (response == null) {
        _showSnackBar('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        var responseData = jsonDecode(response.body);
        _showSnackBar(responseData['message'] ?? 'حدث خطأ أثناء تحديث البيانات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancel() {
    Navigator.pop(context);
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
            'تعديل الملف الشخصي',
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // حقل الاسم الأول
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الأول',
                                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.teal.shade700,
                                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.teal.shade50,
                                prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال الاسم الأول';
                                }
                                if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                  return 'الاسم الأول يجب أن يحتوي على حروف ومسافات فقط';
                                }
                                if (value.trim().isEmpty) {
                                  return 'الاسم الأول لا يمكن أن يكون مسافات فقط';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // حقل الاسم الأخير
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الأخير',
                                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.teal.shade700,
                                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.teal.shade50,
                                prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال الاسم الأخير';
                                }
                                if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                  return 'الاسم الأخير يجب أن يحتوي على حروف ومسافات فقط';
                                }
                                if (value.trim().isEmpty) {
                                  return 'الاسم الأخير لا يمكن أن يكون مسافات فقط';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // حقل التخصص (للدكتور)
                          if (_accountType == 'doctor')
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _specializationController,
                                decoration: InputDecoration(
                                  labelText: 'التخصص',
                                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.teal.shade700,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.teal.shade50,
                                  prefixIcon: Icon(Icons.medical_services, color: Colors.teal),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال التخصص';
                                  }
                                  if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                    return 'التخصص يجب أن يحتوي على حروف ومسافات فقط';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'التخصص يجب أن يكون 3 حروف على الأقل';
                                  }
                                  if (value.trim().isEmpty) {
                                    return 'التخصص لا يمكن أن يكون مسافات فقط';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          // السجل الصحي والدكتور المرتبط (للمريض)
                          if (_accountType == 'patient') ...[
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _medicalHistoryController,
                                decoration: InputDecoration(
                                  labelText: 'السجل الصحي',
                                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.teal.shade700,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.teal.shade50,
                                  prefixIcon: Icon(Icons.history, color: Colors.teal),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 3,
                                validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^[\p{L}\s\d\u0660-\u0669:\/\-\.,]*$', unicode: true).hasMatch(value)) {
                                            return 'السجل الصحي يحتوي على رموز غير مسموح بها';
                                        }
                                        if (value.trim().isEmpty) {
                                            return 'السجل الصحي لا يمكن أن يكون مسافات فقط';
                                        }
                                    }
                                    return null;
                                },
                               ),
                            ),
                            const SizedBox(height: 16),
                            // كارد الدكتور المرتبط
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
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person, color: Colors.teal, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${_linkedDoctor!['first_name'] ?? 'غير متوفر'} ${_linkedDoctor!['last_name'] ?? ''}',
                                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                              color: Colors.black87,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.medical_services, color: Colors.teal, size: 20),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'التخصص: ${_linkedDoctor!['specialization'] ?? 'غير محدد'}',
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                              color: Colors.grey[600],
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              ElevatedButton(
                                                onPressed: _unlinkFromDoctor,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade600,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  elevation: 2,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.link_off, color: Colors.white, size: 18),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'إلغاء الارتباط',
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
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
                          ],
                          const SizedBox(height: 24),
                          // أزرار الحفظ والإلغاء
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'حفظ التعديلات',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _cancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'إلغاء',
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
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}