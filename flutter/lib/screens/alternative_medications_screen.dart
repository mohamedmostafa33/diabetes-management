import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
  final String baseUrl = "https://diabetesmanagement.pythonanywhere.com/api";

  // Fetch drug suggestions for Autocomplete
  Future<List<String>> _getDrugSuggestions(String query) async {
    try {
      final response = await httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('$baseUrl/drug-suggestions/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: {'query': query},
      );

      if (response == null) {
        throw Exception('فشل في الاتصال: الرجاء تسجيل الدخول مرة أخرى');
      }

      print('Drug suggestions raw response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<String>();
      } else {
        throw Exception('فشل في جلب اقتراحات الأدوية: ${response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في جلب اقتراحات الأدوية: $e');
    }
  }

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
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: {'drug_name': drugName},
      );

      if (response == null) {
        setState(() {
          errorMessage = 'فشل في الاتصال: الرجاء تسجيل الدخول مرة أخرى';
        });
        return;
      }

      print('Alternative medications raw response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(utf8.decode(response.bodyBytes));
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

          if (mounted) {
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
                    Expanded(
                      child: Text(
                        'يرجى اتباع تعليمات الدكتور وإعلامه بالدواء',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TypeAheadField<String>(
                      controller: _searchController,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'أدخل اسم الدواء الأساسي...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                          ),
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (pattern.isEmpty) return [];
                        return await _getDrugSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(
                            suggestion,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        );
                      },
                      onSelected: (suggestion) {
                        _searchController.text = suggestion;
                        _searchMedication(suggestion);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'بحث',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (showAlternativeText && filteredMedications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'الأدوية البديلة للدواء المدخل',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Expanded(
                child: showAlternativeText && filteredMedications.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredMedications.length,
                        itemBuilder: (context, index) {
                          final med = filteredMedications[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'الدواء ${index + 1}: ${med['name']}',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: Colors.teal.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.teal.shade200, width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الوصف:',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.teal.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            med['description']!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontFamily: 'Cairo',
                                                ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade200, width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الآثار الجانبية:',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            med['sideEffect']!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontFamily: 'Cairo',
                                                ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade200, width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'طريقة الاستخدام:',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.blue.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            med['howToUse']!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontFamily: 'Cairo',
                                                ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'ابحث عن دواء لعرض البدائل',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                            fontStyle: FontStyle.italic,
                          ),
                          textDirection: TextDirection.rtl,
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