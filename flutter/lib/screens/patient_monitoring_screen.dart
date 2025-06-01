import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'patient_health_record_screen.dart';

class PatientMonitoringScreen extends StatefulWidget {
  const PatientMonitoringScreen({super.key});

  @override
  PatientMonitoringScreenState createState() => PatientMonitoringScreenState();
}

class PatientMonitoringScreenState extends State<PatientMonitoringScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController!, curve: Curves.easeIn);
    _fetchPatients();
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/my-patients/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة الاتصال بالسيرفر');
      });

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
        _animationController?.forward(from: 0);
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات المرضى: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Patients Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب المرضى: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'متابعة المرضى',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      'جارٍ تحميل بيانات المرضى...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPatients,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_off,
                              color: Colors.grey,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد مرضى حاليًا',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : (_fadeAnimation == null || _animationController == null)
                        ? const Center(child: CircularProgressIndicator())
                        : FadeTransition(
                            opacity: _fadeAnimation!,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12.0),
                              itemCount: _patients.length,
                              itemBuilder: (context, index) {
                                final patient = _patients[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.teal.withOpacity(0.1),
                                      child: Text(
                                        (patient['first_name'] ?? 'غ').substring(0, 1),
                                        style: const TextStyle(
                                          color: Colors.teal,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${patient['first_name'] ?? 'غير متوفر'} ${patient['last_name'] ?? ''}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.teal,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PatientHealthRecordScreen(
                                            patientId: patient['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
      ),
    );
  }
}