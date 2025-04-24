import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:intl/intl.dart';

class PatientMonitoringScreen extends StatefulWidget {
  const PatientMonitoringScreen({super.key});

  @override
  PatientMonitoringScreenState createState() => PatientMonitoringScreenState();
}

class PatientMonitoringScreenState extends State<PatientMonitoringScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://10.0.2.2:8000/api/my-patients/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        setState(() {
          _errorMessage = 'فشل الاتصال بالسيرفر';
          _isLoading = false;
        });
        return;
      }

      debugPrint('My Patients Response Status: ${response.statusCode}');
      debugPrint('My Patients Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _patients = List<Map<String, dynamic>>.from(responseData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات المرضى: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Patients Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientHealthRecord(int patientId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://10.0.2.2:8000/api/patient-health-record/$patientId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        setState(() {
          _errorMessage = 'فشل الاتصال بالسيرفر';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Patient Health Record Response Status: ${response.statusCode}');
      debugPrint('Patient Health Record Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        responseData['full_name'] = '${responseData['first_name'] ?? 'غير متوفر'} ${responseData['last_name'] ?? ''}'.trim();
        if (mounted) {
          _showHealthRecordDialog(responseData);
        }
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل السجل المرضي: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Health Record Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ: $e';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _translateMedicalHistory(String? medicalHistory) {
    if (medicalHistory == null || medicalHistory.isEmpty) {
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

    for (String line in lines) {
      line = line.trim();

      if (line.toLowerCase().contains('glucose readings')) {
        continue;
      }

      RegExp regExp = RegExp(r'-\s*(.+?):\s*(\d+\.\d+|\d+)\s*mg/dL\s*on\s*(\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2})');
      var match = regExp.firstMatch(line);

      if (match != null) {
        String glucoseType = match.group(1) ?? '';
        String glucoseValue = match.group(2) ?? '0';
        String dateTimeStr = match.group(3) ?? '';

        String translatedType = glucoseTypeMap[glucoseType] ?? glucoseType;

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
        } catch (e) {
          debugPrint('خطأ في تحليل التاريخ في التاريخ المرضي: $e');
          translatedRecords.add({
            'type': translatedType,
            'value': '$glucoseValue mg/dL',
            'date': dateTimeStr,
            'time': '',
          });
        }
      }
    }

    if (translatedRecords.isEmpty) {
      return [
        {
          'type': '',
          'value': 'لا يوجد تاريخ مرضي',
          'date': '',
          'time': '',
        }
      ];
    }

    return translatedRecords;
  }

  void _showHealthRecordDialog(Map<String, dynamic> healthRecord) {
    List<Map<String, String>> translatedMedicalHistory = _translateMedicalHistory(healthRecord['medical_history']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'السجل المرضي للمريض',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.teal[800],
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthRecordItem(
                            context,
                            'الاسم الكامل',
                            healthRecord['full_name'] ?? 'غير متوفر',
                          ),
                          const Divider(color: Colors.teal, thickness: 0.5),
                          _buildHealthRecordItem(
                            context,
                            'البريد الإلكتروني',
                            healthRecord['email'] ?? 'غير متوفر',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    color: Colors.teal,
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجل مستوي السكر في الدم',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              border: TableBorder(
                                horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                verticalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                top: BorderSide(width: 1, color: Colors.grey.shade300),
                                bottom: BorderSide(width: 1, color: Colors.grey.shade300),
                                left: BorderSide(width: 1, color: Colors.grey.shade300),
                                right: BorderSide(width: 1, color: Colors.grey.shade300),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'نوع القياس',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'مستوي السكر',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'التوقيت',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              rows: translatedMedicalHistory.map((record) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        record['type'] ?? '',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.black87,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        record['value'] ?? '',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.black87,
                                              fontSize: 16,
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
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                ),
                                          ),
                                          Text(
                                            record['time'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              columnSpacing: 20,
                              dataRowMinHeight: 50,
                              dataRowMaxHeight: 70,
                              headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                              dividerThickness: 1,
                              showBottomBorder: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHealthRecordItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة المرضى'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPatients,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _patients.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد مرضى متربطين حاليًا',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.teal,
                                size: 40,
                              ),
                              title: Text(
                                '${patient['first_name'] ?? 'غير متوفر'} ${patient['last_name'] ?? ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              subtitle: Text(
                                patient['email'] ?? 'غير متوفر',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () {
                                _fetchPatientHealthRecord(patient['id']);
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}