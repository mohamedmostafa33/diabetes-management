import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'previous_readings_screen.dart';

class GlucoseTrackingScreen extends StatefulWidget {
  const GlucoseTrackingScreen({super.key});

  @override
  GlucoseTrackingScreenState createState() => GlucoseTrackingScreenState();
}

class GlucoseTrackingScreenState extends State<GlucoseTrackingScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedReadingType = 'صائم';
  List<Map<String, dynamic>> glucoseReadings = [];
  DateTime? _selectedDateTime;
  final HttpService _httpService = HttpService();
  String? _token;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchReadings();
  }

  Future<void> _loadTokenAndFetchReadings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      setState(() {
        _token = accessToken;
      });
      _httpService.setTokens(accessToken, '');
      await _fetchGlucoseReadings();
    } else {
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
    }
  }

  Future<void> _fetchGlucoseReadings() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/glucose/list/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            glucoseReadings = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        if (mounted) {
          _showSnackBar('فشل في جلب القراءات!', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في جلب القراءات: $e', Colors.red);
      }
    }
  }

  Future<void> _fetchMedicalHistory() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/profile/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String medicalHistory = responseData['medical_history'] ?? 'غير متوفر';
        await prefs.setString('medical_history', medicalHistory);
      } else {
        if (mounted) {
          _showSnackBar('فشل في جلب السجل الصحي!', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في جلب السجل الصحي: $e', Colors.red);
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDateTime);
    final String formattedTime = DateFormat('h:mm a')
        .format(pickedDateTime)
        .replaceAll('AM', 'صباحًا')
        .replaceAll('PM', 'مساءً');

    if (!mounted) return;
    setState(() {
      _dateController.text = formattedDate;
      _timeController.text = formattedTime;
      _selectedDateTime = pickedDateTime;
    });
  }

  Future<void> _addGlucoseReading() async {
    if (_token == null) {
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
      return;
    }

    if (_glucoseController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _selectedDateTime != null) {
      try {
        double glucoseValue = double.parse(_glucoseController.text);
        if (glucoseValue < 20 || glucoseValue > 600) {
          if (mounted) {
            _showSnackBar('أدخل القياس الصحيح للسكر (بين 20 و600 mg/dL)!', Colors.red);
          }
          return;
        }

        final Map<String, String> readingTypeMap = {
          'صائم': 'FBS',
          'عشوائي': 'RBS',
          'بعد الأكل': 'PPBS',
        };

        final String isoTimestamp = _selectedDateTime!.toUtc().toIso8601String();

        final body = {
          'glucose_type': readingTypeMap[_selectedReadingType]!,
          'glucose_value': glucoseValue,
          'timestamp': isoTimestamp,
        };

        final response = await _httpService.makeRequest(
          method: 'POST',
          url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/glucose/add/'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response != null && response.statusCode == 201) {
          setState(() {
            _glucoseController.clear();
            _dateController.clear();
            _timeController.clear();
            _selectedDateTime = null;
          });
          if (mounted) {
            _showSnackBar('تمت إضافة القراءة بنجاح!', Colors.green);
          }
          await _fetchGlucoseReadings();
          await _fetchMedicalHistory();
        } else {
          String errorMessage = 'فشل في إضافة القراءة!';
          if (response != null) {
            errorMessage += ' رمز الحالة: ${response.statusCode}';
            try {
              final responseBody = jsonDecode(response.body);
              errorMessage += ' - التفاصيل: ${responseBody['error'] ?? responseBody.toString()}';
            } catch (e) {
              errorMessage += ' - لا يمكن تحليل الاستجابة';
            }
          }
          if (mounted) {
            _showSnackBar(errorMessage, Colors.red);
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('فشل في إضافة القراءة: $e', Colors.red);
        }
      }
    } else {
      if (mounted) {
        _showSnackBar('يرجى ملء جميع الحقول!', Colors.red);
      }
    }
  }

  Future<void> _pickImage() async {
    PermissionStatus status;

    // تسجيل إصدار Android
    print('Android API Level: ${Platform.version}');

    if (Platform.isAndroid) {
      if (Platform.version.contains('API 33') || Platform.version.contains('API 34')) {
        status = await Permission.photos.status;
        print('Photos permission status: $status');
        if (!status.isGranted) {
          status = await Permission.photos.request();
          print('Photos permission after request: $status');
        }
      } else {
        status = await Permission.storage.status;
        print('Storage permission status: $status');
        if (!status.isGranted) {
          status = await Permission.storage.request();
          print('Storage permission after request: $status');
        }
      }
    } else {
      status = await Permission.photos.status;
      print('iOS Photos permission status: $status');
      if (!status.isGranted) {
        status = await Permission.photos.request();
        print('iOS Photos permission after request: $status');
      }
    }

    if (status.isGranted) {
      setState(() {
        _isUploading = true;
      });
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploading = false;
        });
        print('Image picked: ${pickedFile.path}');
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          _showSnackBar('لم يتم اختيار صورة.', Colors.red);
        }
        print('No image selected');
      }
    } else if (status.isDenied) {
      if (mounted) {
        _showSnackBar('يرجى منح إذن الوصول إلى الصور!', Colors.red);
      }
      print('Permission denied');
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showSnackBar('تم رفض الإذن بشكل دائم. يرجى تفعيله من إعدادات التطبيق.', Colors.red);
      }
      await openAppSettings();
      print('Permission permanently denied');
    } else {
      if (mounted) {
        _showSnackBar('حالة الإذن غير معروفة: $status', Colors.red);
      }
      print('Unknown permission status: $status');
    }
  }

  Future<void> _cancelImage() async {
    setState(() {
      _selectedImage = null;
      _descriptionController.clear();
    });
    if (mounted) {
      _showSnackBar('تم إلغاء الصورة المختارة.', Colors.blue);
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      if (mounted) {
        _showSnackBar('يرجى اختيار صورة أولاً!', Colors.red);
      }
      return;
    }

    if (_token == null) {
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/upload-analysis/'),
      );

      request.headers['Authorization'] = 'Bearer $_token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      if (_descriptionController.text.isNotEmpty) {
        request.fields['description'] = _descriptionController.text;
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        setState(() {
          _selectedImage = null;
          _descriptionController.clear();
        });
        if (mounted) {
          _showSnackBar('تم رفع الصورة بنجاح!', Colors.green);
        }
      } else if (response.statusCode == 400) {
        var errorData = jsonDecode(responseBody);
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: ${errorData['error']}', Colors.red);
        }
      } else if (response.statusCode == 403) {
        var errorData = jsonDecode(responseBody);
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: ${errorData['error']}', Colors.red);
        }
      } else {
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: خطأ غير معروف', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في رفع الصورة: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تتبع مستوى السكر',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviousReadingsScreen(readings: glucoseReadings),
                ),
              );
            },
            tooltip: 'القراءات السابقة',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل قراءات السكر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _glucoseController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'مستوى السكر (mg/dL)',
                            prefixIcon: const Icon(Icons.monitor_heart),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: () => _selectDateTime(context),
                                decoration: InputDecoration(
                                  labelText: 'التاريخ',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _timeController,
                                readOnly: true,
                                onTap: () => _selectDateTime(context),
                                decoration: InputDecoration(
                                  labelText: 'الوقت',
                                  prefixIcon: const Icon(Icons.access_time),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedReadingType,
                          items: ['صائم', 'عشوائي', 'بعد الأكل']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedReadingType = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'نوع القراءة',
                            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.teal),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addGlucoseReading,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'حفظ القراءة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(
                    color: Color.fromARGB(255, 137, 150, 0),
                    thickness: 6,
                    indent: 20,
                    endIndent: 20,
                  ),
                ),
                Text(
                  'رفع تحاليل السكر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'وصف الصورة (اختياري)',
                            prefixIcon: const Icon(Icons.description),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.photo_library),
                            label: Text(_isUploading ? 'جارٍ التحميل...' : 'اختيار من المعرض'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_selectedImage != null) ...[
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _cancelImage,
                              icon: const Icon(Icons.cancel),
                              label: const Text('إلغاء الصورة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : _uploadImage,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(_isUploading ? 'جارٍ الرفع...' : 'رفع الصورة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}