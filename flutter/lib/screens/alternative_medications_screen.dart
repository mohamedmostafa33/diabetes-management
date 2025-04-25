import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart'; 
import 'dart:convert';

class AlternativeMedicationsScreen extends StatefulWidget {
  const AlternativeMedicationsScreen({super.key});

  @override
  AlternativeMedicationsScreenState createState() => AlternativeMedicationsScreenState();
}

class AlternativeMedicationsScreenState extends State<AlternativeMedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredMedications = [];
  bool isLoading = false;
  String? errorMessage;
  bool showAlternativeText = false;

  // Instance of HttpService
  final HttpService httpService = HttpService();
  final String baseUrl = "http://10.0.2.2:8000/api"; // Adjust if needed

  // Fetch alternative medications from the API using HttpService
  Future<void> _searchMedication(String drugName) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      filteredMedications = [];
      showAlternativeText = false;
    });

    try {
      final response = await httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('$baseUrl/alternative-medicine/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {'drug_name': drugName},
      );

      if (response == null) {
        setState(() {
          errorMessage = 'فشل في الاتصال: الرجاء تسجيل الدخول مرة أخرى';
        });
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result.containsKey('error')) {
          setState(() {
            errorMessage = result['error'];
          });
        } else {
          final List<dynamic> recommendedDrugs = result['recommended_drugs'];
          setState(() {
            filteredMedications = recommendedDrugs.map((drug) => {
                  'name': drug['Drug Name'].toString(),
                  'description': drug['Description'].toString(),
                  'sideEffect': drug['Side Effects'].toString(),
                  'howToUse': drug['How to use with'].toString(),
                }).toList();
            showAlternativeText = true;
          });

          // Show warning SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.yellow,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'يرجى اتباع تعليمات الدكتور وإعلامه بالدواء',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 7),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'فشل في جلب الأدوية البديلة: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الأدوية البديلة',
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
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'أدخل اسم الدواء الأساسي...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_searchController.text.isNotEmpty) {
                              _searchMedication(_searchController.text);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('بحث'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              if (!isLoading && errorMessage == null && showAlternativeText) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    'الأدوية البديلة للدواء المدخل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'نتائج البحث عن الأدوية البديلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      dividerThickness: 2.0,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 60,
                      columnSpacing: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      border: TableBorder(
                        verticalInside: const BorderSide(
                          width: 2.0,
                          color: Colors.grey,
                        ),
                        horizontalInside: const BorderSide(
                          width: 2.0,
                          color: Colors.grey,
                        ),
                      ),
                      columns: const [
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'اسم الدواء',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'الوصف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'الأثر الجانبي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'طريقة الاستخدام',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: filteredMedications.map((med) {
                        return DataRow(
                          cells: [
                            DataCell(Text(med['name']!)),
                            DataCell(Text(med['description']!)),
                            DataCell(Text(med['sideEffect']!)),
                            DataCell(Text(med['howToUse']!)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}