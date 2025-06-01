import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'full_image_screen.dart';

class PatientHealthRecordScreen extends StatefulWidget {
  final int patientId;

  const PatientHealthRecordScreen({super.key, required this.patientId});

  @override
  PatientHealthRecordScreenState createState() => PatientHealthRecordScreenState();
}

class PatientHealthRecordScreenState extends State<PatientHealthRecordScreen> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _healthRecord;
  String? _errorMessage;
  bool _isLoading = true;
  String? _token;
  final HttpService _httpService = HttpService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      if (accessToken != null) {
        setState(() {
          _token = accessToken;
        });
        _httpService.setTokens(accessToken, '');
        await _fetchPatientHealthRecord();
      } else {
        setState(() {
          _errorMessage = 'لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientHealthRecord() async {
    debugPrint('Starting fetch health record for patient ID: ${widget.patientId}');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Sending request to fetch patient health record');
      final healthResponse = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/patient-health-record/${widget.patientId}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة جلب السجل المرضي');
      });

      if (healthResponse == null) {
        throw Exception('فشل الاتصال بالسيرفر');
      }

      debugPrint('Patient Health Record Response Status: ${healthResponse.statusCode}');
      debugPrint('Patient Health Record Response Body: ${healthResponse.body}');

      if (healthResponse.statusCode == 200) {
        debugPrint('Parsing health record response');
        final healthData = jsonDecode(utf8.decode(healthResponse.bodyBytes));
        healthData['full_name'] = '${healthData['first_name'] ?? 'غير متوفر'} ${healthData['last_name'] ?? ''}'.trim();

        // Fetch patient analysis
        debugPrint('Fetching patient analysis');
        List<Map<String, dynamic>> analysisData = [];
        try {
          analysisData = await _fetchPatientAnalysis(widget.patientId);
        } catch (e) {
          debugPrint('Failed to fetch analysis, proceeding with health record: $e');
        }
        healthData['analysis'] = analysisData;

        debugPrint('Health record data prepared: $healthData');
        setState(() {
          _healthRecord = healthData;
          _isLoading = false;
        });
      } else {
        final responseData = jsonDecode(healthResponse.body);
        throw Exception(responseData['error'] ?? 'فشل تحميل السجل المرضي: ${healthResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Health Record Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب السجل المرضي: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPatientAnalysis(int patientId) async {
    debugPrint('Fetching analysis for patient ID: $patientId');
    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/patient-analysis/$patientId/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة جلب تحاليل المريض');
      });

      if (response == null) {
        throw Exception('فشل الاتصال بالسيرفر');
      }

      debugPrint('Patient Analysis Response Status: ${response.statusCode}');
      debugPrint('Patient Analysis Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? 'فشل جلب تحاليل المريض: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Patient Analysis Error: $e');
      throw Exception('حدث خطأ أثناء جلب تحاليل المريض: $e');
    }
  }

  Future<void> _addCommentToAnalysis(int analysisId, String comment) async {
    if (_token == null) {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      return;
    }

    try {
      final response = await _httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/add-comment-to-analysis/$analysisId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      debugPrint('Add Comment Response Status: ${response.statusCode}');
      debugPrint('Add Comment Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('تم إضافة التعليق بنجاح!', Colors.green);
        await _fetchPatientHealthRecord(); // Refresh data to update the UI
      } else {
        final responseData = jsonDecode(response.body);
        _showSnackBar(responseData['error'] ?? 'فشل في إضافة التعليق!', Colors.red);
      }
    } catch (e) {
      debugPrint('Add Comment Error: $e');
      _showSnackBar('فشل في إضافة التعليق: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        elevation: 6,
      ),
    );
  }

  Future<void> _showCommentDialog(int analysisId) async {
    final TextEditingController commentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'إضافة تعليق',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal.shade800,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
        ),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: 'اكتب تعليقك هنا',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.teal.shade50,
            labelStyle: const TextStyle(fontFamily: 'Cairo'),
          ),
          maxLines: 3,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontFamily: 'Cairo',
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) {
                _showSnackBar('التعليق لا يمكن أن يكون فارغًا', Colors.red);
                return;
              }
              Navigator.pop(context);
              _addCommentToAnalysis(analysisId, commentController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'إرسال',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _translateMedicalHistory(String? medicalHistory) {
    debugPrint('Translating medical history: $medicalHistory');
    try {
      if (medicalHistory == null || medicalHistory.isEmpty) {
        debugPrint('Medical history is null or empty');
        return [
          {
            'type': '',
            'value': 'لا يوجد تاريخ مرضي',
            'date': '',
            'time': '',
          }
        ];
      }

      const glucoseTypeMap = {
        'Postprandial Blood Sugar': 'بعد الأكل',
        'Random Blood Sugar': 'عشوائي',
        'Fasting Blood Sugar': 'صائم',
      };

      List<String> lines = medicalHistory.split('\n');
      List<Map<String, String>> translatedRecords = [];
      const int maxRecords = 50; // Limit to prevent performance issues

      debugPrint('Processing ${lines.length} lines of medical history');
      for (String line in lines.take(maxRecords)) {
        line = line.trim();
        debugPrint('Processing line: $line');

        if (line.toLowerCase().contains('glucose readings')) {
          debugPrint('Skipping glucose readings header');
          continue;
        }

        RegExp regExp = RegExp(r'-\s*(.+?):\s*(\d+\.\d+|\d+)\s*mg/dL\s*on\s*(\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}(?::\d{2})?)');
        var match = regExp.firstMatch(line);

        if (match != null) {
          String glucoseType = match.group(1) ?? '';
          String glucoseValue = match.group(2) ?? '0';
          String dateTimeStr = match.group(3) ?? '';

          String translatedType = glucoseTypeMap[glucoseType] ?? glucoseType;
          debugPrint('Matched: type=$glucoseType, value=$glucoseValue, date=$dateTimeStr');

          dateTimeStr = dateTimeStr.trim();

          try {
            DateTime dateTime = DateTime.parse(dateTimeStr);
            String date = '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
            String time = DateFormat('h:mm a')
                .format(dateTime)
                .replaceAll('AM', 'صباحاً')
                .replaceAll('PM', 'مساءً');

            translatedRecords.add({
              'type': translatedType,
              'value': '$glucoseValue mg/dL',
              'date': date,
              'time': time,
            });
            debugPrint('Added record: $translatedRecords.last');
          } catch (e) {
            debugPrint('Error parsing date in medical history: $e');
            translatedRecords.add({
              'type': translatedType,
              'value': '$glucoseValue mg/dL',
              'date': dateTimeStr,
              'time': '',
            });
          }
        } else {
          debugPrint('No match for line: $line');
        }
      }

      if (translatedRecords.isEmpty) {
        debugPrint('No records translated');
        return [
          {
            'type': '',
            'value': 'لا يوجد تاريخ مرضي',
            'date': '',
            'time': '',
          }
        ];
      }

      debugPrint('Translated ${translatedRecords.length} records');
      return translatedRecords;
    } catch (e) {
      debugPrint('Error in translateMedicalHistory: $e');
      return [
        {
          'type': '',
          'value': 'خطأ في معالجة السجل المرضي',
          'date': '',
          'time': '',
        }
      ];
    }
  }

  Widget _buildHealthRecordItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                  fontFamily: 'Cairo',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'السجل المرضي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
        elevation: 8,
        shadowColor: Colors.teal.withOpacity(0.3),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.red.shade700,
                                fontSize: 18,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadTokenAndFetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                            shadowColor: Colors.teal.withOpacity(0.4),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _healthRecord == null
                    ? Center(
                        child: Text(
                          'لا يوجد سجل مرضي متاح',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                fontFamily: 'Cairo',
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20.0),
                        children: [
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: const EdgeInsets.only(bottom: 20.0),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHealthRecordItem(
                                    context,
                                    'اسم المريض ',
                                    _healthRecord!['full_name'] ?? 'غير متوفر',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            color: Colors.teal,
                            thickness: 2,
                            indent: 20,
                            endIndent: 20,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'سجل مستوي السكر في الدم',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  border: TableBorder(
                                    horizontalInside: BorderSide(width: 1, color: Colors.grey.shade200),
                                    verticalInside: BorderSide(width: 1, color: Colors.grey.shade200),
                                    top: BorderSide(width: 1, color: Colors.grey.shade200),
                                    bottom: BorderSide(width: 1, color: Colors.grey.shade200),
                                    left: BorderSide(width: 1, color: Colors.grey.shade200),
                                    right: BorderSide(width: 1, color: Colors.grey.shade200),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'نوع القياس',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                              color: Colors.teal.shade900,
                                            ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'مستوي السكر',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                              color: Colors.teal.shade900,
                                            ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'التوقيت',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                              color: Colors.teal.shade900,
                                            ),
                                      ),
                                    ),
                                  ],
                                  rows: _translateMedicalHistory(_healthRecord!['medical_history']).map((record) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            record['type'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.grey.shade800,
                                                  fontSize: 16,
                                                  fontFamily: 'Cairo',
                                                ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            record['value'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.grey.shade800,
                                                  fontSize: 16,
                                                  fontFamily: 'Cairo',
                                                ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record['date'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.grey.shade800,
                                                      fontSize: 16,
                                                      fontFamily: 'Cairo',
                                                    ),
                                              ),
                                              Text(
                                                record['time'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.grey.shade800,
                                                      fontSize: 16,
                                                      fontFamily: 'Cairo',
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  columnSpacing: 24,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 80,
                                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                                  dividerThickness: 1.5,
                                  showBottomBorder: true,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(
                            color: Colors.teal,
                            thickness: 2,
                            indent: 20,
                            endIndent: 20,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'تحاليل السكر',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'اضغط على الصورة لعرضها بالكامل أو على أيقونة التعليق لإضافة توصية',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Cairo',
                                ),
                          ),
                          const SizedBox(height: 16),
                          _healthRecord!['analysis'].isEmpty
                              ? Center(
                                  child: Text(
                                    'لا توجد تحاليل متاحة',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'Cairo',
                                          fontSize: 16,
                                        ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _healthRecord!['analysis'].length,
                                  itemBuilder: (context, index) {
                                    final imageData = _healthRecord!['analysis'][index];
                                    final int analysisId = imageData['id'] ?? 0;
                                    final String imageUrl = imageData['image'] ?? '';
                                    final String description = imageData['description'] ?? 'بدون وصف';
                                    final String comment = imageData['comment'] ?? 'لا يوجد تعليق';
                                    final String uploadedAt = imageData['uploaded_at'] ?? DateTime.now().toString();
                                    DateTime uploadDate;
                                    try {
                                      uploadDate = DateTime.parse(uploadedAt);
                                    } catch (e) {
                                      debugPrint('Error parsing uploaded_at: $e');
                                      uploadDate = DateTime.now();
                                    }
                                    final String formattedDate = DateFormat('yyyy-MM-dd').format(uploadDate);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: imageUrl.isEmpty || kIsWeb
                                                  ? null
                                                  : () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => FullImageScreen(
                                                            imageUrl: 'https://diabetesmanagement.pythonanywhere.com$imageUrl',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                ),
                                                child: imageUrl.isEmpty || kIsWeb
                                                    ? Container(
                                                        height: 200,
                                                        color: Colors.grey.shade100,
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                            color: Colors.grey.shade400,
                                                          ),
                                                        ),
                                                      )
                                                    : Image.network(
                                                        'https://diabetesmanagement.pythonanywhere.com$imageUrl',
                                                        height: 200,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Container(
                                                            height: 200,
                                                            color: Colors.grey.shade100,
                                                            child: Center(
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        (loadingProgress.expectedTotalBytes ?? 1)
                                                                    : null,
                                                                color: Colors.teal,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          height: 200,
                                                          color: Colors.grey.shade100,
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.broken_image,
                                                              size: 50,
                                                              color: Colors.grey.shade400,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'تاريخ الرفع: $formattedDate',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: Colors.grey.shade700,
                                                                fontFamily: 'Cairo',
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.comment,
                                                          color: Colors.teal.shade700,
                                                          size: 30,
                                                        ),
                                                        tooltip: 'إضافة تعليق',
                                                        onPressed: () {
                                                          _showCommentDialog(analysisId);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(16.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.teal.shade200, width: 1.5),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'وصف المريض',
                                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                color: Colors.teal.shade900,
                                                                fontWeight: FontWeight.bold,
                                                                fontFamily: 'Cairo',
                                                              ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          description,
                                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                                color: Colors.grey.shade800,
                                                                fontFamily: 'Cairo',
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(16.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.blue.shade200, width: 1.5),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'تعليق الدكتور',
                                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                color: Colors.blue.shade900,
                                                                fontWeight: FontWeight.bold,
                                                                fontFamily: 'Cairo',
                                                              ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          comment,
                                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                                color: comment == 'لا يوجد تعليق'
                                                                    ? Colors.grey.shade600
                                                                    : Colors.grey.shade800,
                                                                fontFamily: 'Cairo',
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
      ),
    );
  }
}