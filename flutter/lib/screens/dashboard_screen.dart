import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/notification_service.dart';
import 'package:diabetes_management/config/theme.dart';

// شاشة متابعة المرضى (للدكتور فقط)
class PatientMonitoringScreen extends StatelessWidget {
  const PatientMonitoringScreen({super.key});

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
        child: const Center(
          child: Text(
            'هنا سيتم عرض بيانات المرضى للمتابعة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;
  int _notificationCount = 0;
  Timer? _notificationTimer;
  List<Map<String, dynamic>> _lastNotifications = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startNotificationPolling();
    _searchController.addListener(() {
      setState(() {}); // لتحديث واجهة المستخدم عند تغيير النص (لإظهار/إخفاء زر المسح)
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name') ?? 'غير متوفر';
      _lastName = prefs.getString('last_name') ?? '';
      _email = prefs.getString('user_email') ?? 'غير متوفر';
      _accountType = prefs.getString('account_type');
      _specialization = prefs.getString('specialization');
      debugPrint('Loaded first_name: $_firstName');
      debugPrint('Loaded last_name: $_lastName');
      debugPrint('Loaded email: $_email');
      debugPrint('Loaded account_type: $_accountType');
      debugPrint('Loaded specialization: $_specialization');
    });

    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && refreshToken != null) {
      HttpService().setTokens(accessToken, refreshToken);
      debugPrint('Tokens updated in HttpService: Access Token: $accessToken, Refresh Token: $refreshToken');
    }
  }

  Future<void> _updateNotificationCount() async {
    List<Map<String, dynamic>> notifications = await NotificationService.getLoggedNotifications();
    debugPrint('Fetched notifications: ${notifications.length}');
    if (!mounted) return;
    setState(() {
      _notificationCount = notifications.length;
      debugPrint('Updated notification count: $_notificationCount');
    });

    if (notifications.length > _lastNotifications.length) {
      var newNotifications = notifications
          .where((n) => !_lastNotifications.any((ln) => ln['id'] == n['id'] && ln['scheduled_time'] == n['scheduled_time']))
          .toList();
      debugPrint('New notifications: ${newNotifications.length}');
      _lastNotifications = List.from(notifications);
      if (newNotifications.isNotEmpty && mounted) {
        debugPrint('Showing dialog for new notification: ${newNotifications.last}');
        _showNewNotificationDialog(newNotifications.last);
      }
    }
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        await _updateNotificationCount();
      }
    });
  }

  void _showNewNotificationDialog(Map<String, dynamic> notification) {
    DateTime scheduledTime = DateTime.parse(notification['scheduled_time']);
    final hour = scheduledTime.hour > 12
        ? scheduledTime.hour - 12
        : scheduledTime.hour == 0
            ? 12
            : scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = scheduledTime.hour >= 12 ? 'مساءً' : 'صباحًا';

    IconData notificationIcon;
    Color notificationColor;
    switch (notification['reminder_type'].toLowerCase()) {
      case 'blood_glucose_test':
        notificationIcon = Icons.monitor_heart;
        notificationColor = Colors.teal;
        break;
      case 'hydration':
        notificationIcon = Icons.water_drop;
        notificationColor = Colors.tealAccent;
        break;
      case 'medication':
        notificationIcon = Icons.medical_services;
        notificationColor = Colors.teal;
        break;
      default:
        notificationIcon = Icons.notifications_active;
        notificationColor = Theme.of(context).primaryColor;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  notificationIcon,
                  size: 40,
                  color: notificationColor,
                ),
                const SizedBox(height: 16),
                Text(
                  notification['title'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: notificationColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'الوقت: $hour:$minute $period',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (notification['reminder_type'].toLowerCase() == 'medication' &&
                    notification['medication_name'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الدواء: ${notification['medication_name']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إغلاق',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        if (mounted) {
          _updateNotificationCount();
        }
      });
    }
  }

  void _showAllNotificationsDialog() async {
    List<Map<String, dynamic>> loggedNotifications = await NotificationService.getLoggedNotifications();
    debugPrint('Showing all notifications dialog with ${loggedNotifications.length} notifications');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'الإشعارات المرسلة',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: loggedNotifications.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد إشعارات حاليًا',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: loggedNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = loggedNotifications[index];
                            DateTime scheduledTime = DateTime.parse(notification['scheduled_time']);
                            final hour = scheduledTime.hour > 12
                                ? scheduledTime.hour - 12
                                : scheduledTime.hour == 0
                                    ? 12
                                    : scheduledTime.hour;
                            final minute = scheduledTime.minute.toString().padLeft(2, '0');
                            final period = scheduledTime.hour >= 12 ? 'مساءً' : 'صباحًا';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الوقت: $hour:$minute $period',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: loggedNotifications.isEmpty
                        ? null
                        : () async {
                            await NotificationService.clearLoggedNotifications();
                            setState(() {
                              loggedNotifications.clear();
                              if (mounted) {
                                _updateNotificationCount();
                              }
                            });
                          },
                    child: Text(
                      'مسح الكل',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: loggedNotifications.isEmpty ? Colors.grey : Colors.teal,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إغلاق',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((_) {
        if (mounted) {
          _updateNotificationCount();
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      debugPrint('Access Token being sent: $accessToken');

      if (accessToken == null) {
        if (!mounted) return;
        _showSnackBar('تم تسجيل الخروج', Colors.green);
        await prefs.clear();
        HttpService().clearTokens();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/logout/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        if (!mounted) return;
        await prefs.clear();
        HttpService().clearTokens();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      await prefs.clear();
      HttpService().clearTokens();

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        _showSnackBar('تم تسجيل الخروج بنجاح', Colors.green);
      } else {
        if (!mounted) return;
        _showSnackBar('فشل تسجيل الخروج: ${response.statusCode} - ${response.body}', Colors.red);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _showSnackBar('حدث خطأ أثناء تسجيل الخروج: $e', Colors.red);
      await prefs.clear();
      HttpService().clearTokens();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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

  Future<List<Map<String, dynamic>>> _fetchDoctors(String query) async {
    final response = await HttpService().makeRequest(
      method: 'GET',
      url: Uri.parse('http://10.0.2.2:8000/api/search-doctors/?query=$query'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response == null) {
      throw Exception('فشل الاتصال بالسيرفر');
    }

    debugPrint('Search API Response Status: ${response.statusCode}');
    debugPrint('Search API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint('Parsed Response Data: $responseData');

      if (responseData is List) {
        return List<Map<String, dynamic>>.from(responseData);
      } else if (responseData is Map) {
        var doctorsData = responseData['doctors'];
        if (doctorsData is List) {
          return List<Map<String, dynamic>>.from(doctorsData);
        } else if (doctorsData is Map) {
          return doctorsData.values.map((value) => Map<String, dynamic>.from(value)).toList();
        }
      }
    }
    return [];
  }

  Future<void> _searchDoctors(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final queryParts = query.trim().split(' ');

      if (queryParts.length >= 2) {
        final firstNameQuery = queryParts[0];
        final lastNameQuery = queryParts[1];

        final firstNameResults = await _fetchDoctors(firstNameQuery);
        final lastNameResults = await _fetchDoctors(lastNameQuery);

        _searchResults = [];

        final Map<String, Map<String, dynamic>> uniqueDoctors = {};

        for (var doctor in firstNameResults) {
          final firstName = (doctor['first_name'] ?? '').toString().toLowerCase();
          if (firstName.contains(firstNameQuery.toLowerCase())) {
            final doctorId = doctor['id'].toString();
            uniqueDoctors[doctorId] = doctor;
          }
        }

        for (var doctor in lastNameResults) {
          final lastName = (doctor['last_name'] ?? '').toString().toLowerCase();
          final doctorId = doctor['id'].toString();
          if (lastName.contains(lastNameQuery.toLowerCase()) && uniqueDoctors.containsKey(doctorId)) {
            _searchResults.add(uniqueDoctors[doctorId]!);
          }
        }

        if (_searchResults.isEmpty) {
          _searchError = 'لا توجد نتائج مطابقة';
        }
      } else {
        _searchResults = await _fetchDoctors(query);
        if (_searchResults.isEmpty) {
          _searchError = 'لا توجد نتائج مطابقة';
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        _searchError = 'حدث خطأ: $e';
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget? screen, {
    bool isLogout = false,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).primaryColor,
          size: 30,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLogout ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () async {
          if (isLogout) {
            _logout();
          } else {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => screen!),
            );
            if (title == 'الملف الشخصي' && result == true && mounted) {
              await _loadUserData();
            }
          }
        },
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required String imagePath,
    required Widget screen,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            debugPrint('Navigating to: $title');
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => screen),
            );
            if (title == 'الملف الشخصي' && result == true && mounted) {
              await _loadUserData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ),
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
            'الصفحة الرئيسية',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient,
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _showAllNotificationsDialog,
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.appBarGradient,
                  ),
                  child: SizedBox(
                    height: 250, // زيادة الارتفاع لتوسيع الجزء السماوي
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          _accountType == 'doctor'
                              ? 'assets/images/doctor_logo.png.webp'
                              : 'assets/images/patient_logo.png.webp',
                          height: 90, // زيادة حجم الصورة لتبدو أوضح
                          width: 90,
                        ),
                        const SizedBox(height: 12), // زيادة المسافة بين الصورة والنص
                        Text(
                          '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28, // زيادة حجم الخط
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8), // زيادة المسافة بين النصوص
                        Text(
                          _email ?? 'الإيميل',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18, // زيادة حجم الخط
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8), // زيادة المسافة بين النصوص
                        Text(
                          _accountType == 'doctor' ? 'دكتور' : 'مريض',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20, // زيادة حجم الخط
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10), // زيادة المسافة لتحريك الأيقونات لأسفل أكثر
                _buildDrawerItem(
                  context,
                  'الملف الشخصي',
                  Icons.person,
                  const ProfileScreen(),
                ),
                if (_accountType == 'patient') ...[
                  _buildDrawerItem(
                    context,
                    'تتبع تحليل السكر',
                    Icons.monitor_heart,
                    const GlucoseTrackingScreen(),
                  ),
                  _buildDrawerItem(
                    context,
                    'التذكيرات',
                    Icons.notifications,
                    const RemindersScreen(),
                  ),
                  _buildDrawerItem(
                    context,
                    'التنبؤ بمرض السكر',
                    Icons.analytics,
                    const AIAnalysisScreen(),
                  ),
                  _buildDrawerItem(
                    context,
                    'الأدوية البديلة',
                    Icons.medical_services,
                    const AlternativeMedicationsScreen(),
                  ),
                  _buildDrawerItem(
                    context,
                    'الشات بوت',
                    Icons.chat,
                    const ChatbotScreen(),
                  ),
                ],
                if (_accountType == 'doctor')
                  _buildDrawerItem(
                    context,
                    'متابعة المرضى',
                    Icons.people,
                    const PatientMonitoringScreen(),
                  ),
                const Divider(),
                const SizedBox(height: 10), // مسافة قبل "تسجيل الخروج"
                _buildDrawerItem(
                  context,
                  'تسجيل الخروج',
                  Icons.logout,
                  null,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (_showWelcomeMessage)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'مرحبًا بك في تطبيق إدارة مرض السكري',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_accountType == 'patient') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'البحث عن الطبيب',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.teal),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _searchError = null;
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: (value) {
                        _searchDoctors(value);
                      },
                    ),
                  ),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator()),
                  if (_searchError != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _searchError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final doctor = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.teal),
                              title: Text(
                                '${doctor['first_name'] ?? 'غير متوفر'} ${doctor['last_name'] ?? ''}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              subtitle: Text(
                                doctor['specialization'] ?? 'غير محدد',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final response = await HttpService().makeRequest(
                                      method: 'POST',
                                      url: Uri.parse('http://10.0.2.2:8000/api/link-to-doctor/'),
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode({'doctor_id': doctor['id']}),
                                    );

                                    if (response == null) {
                                      _showSnackBar(
                                        'فشل الاتصال بالسيرفر',
                                        Colors.red,
                                      );
                                      return;
                                    }

                                    debugPrint('Link Doctor Response Status: ${response.statusCode}');
                                    debugPrint('Link Doctor Response Body: ${response.body}');

                                    if (response.statusCode == 201) {
                                      _showSnackBar(
                                        'تم طلب استشارة مع الدكتور ${doctor['first_name']} ${doctor['last_name']}',
                                        Colors.green,
                                      );
                                    } else {
                                      String errorMessage = 'خطأ غير معروف';
                                      if (response.headers['content-type']?.contains('application/json') == true) {
                                        try {
                                          final responseData = jsonDecode(response.body);
                                          errorMessage = responseData['error'] ?? 'خطأ غير معروف';
                                        } catch (e) {
                                          errorMessage = 'فشل تحليل الاستجابة: ${response.body}';
                                        }
                                      } else {
                                        errorMessage = 'استجابة غير متوقعة من السيرفر: ${response.body}';
                                      }
                                      _showSnackBar(
                                        'فشل طلب الاستشارة: $errorMessage',
                                        Colors.red,
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Link Doctor Error: $e');
                                    _showSnackBar(
                                      'حدث خطأ: $e',
                                      Colors.red,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text(
                                  'طلب استشارة',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              onTap: () {
                                _showSnackBar(
                                  'تم تحديد الطبيب: ${doctor['first_name']}',
                                  Colors.green,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isSearching && _searchResults.isEmpty && _searchError == null)
                    Expanded(
                      child: DashboardGrid(
                        buildDashboardButton: _buildDashboardButton,
                        accountType: _accountType,
                      ),
                    ),
                ] else
                  Expanded(
                    child: DashboardGrid(
                      buildDashboardButton: _buildDashboardButton,
                      accountType: _accountType,
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

class DashboardGrid extends StatelessWidget {
  final Widget Function(
    BuildContext context, {
    required String title,
    required String imagePath,
    required Widget screen,
  }) buildDashboardButton;
  final String? accountType;

  const DashboardGrid({
    super.key,
    required this.buildDashboardButton,
    required this.accountType,
  });

  List<Map<String, dynamic>> get _dashboardItems {
    List<Map<String, dynamic>> items = [
      {
        'title': 'الملف الشخصي',
        'imagePath': 'assets/images/profile.png.webp',
        'screen': const ProfileScreen(),
      },
    ];

    if (accountType == 'patient') {
      items.insertAll(0, [
        {
          'title': 'تتبع تحليل السكر',
          'imagePath': 'assets/images/glucose_tracking.png.webp',
          'screen': const GlucoseTrackingScreen(),
        },
        {
          'title': 'التذكيرات',
          'imagePath': 'assets/images/reminders.png.webp',
          'screen': const RemindersScreen(),
        },
        {
          'title': 'التنبؤ بمرض السكر',
          'imagePath': 'assets/images/ai_analysis.png.webp',
          'screen': const AIAnalysisScreen(),
        },
        {
          'title': 'الأدوية البديلة',
          'imagePath': 'assets/images/medications.png.webp',
          'screen': const AlternativeMedicationsScreen(),
        },
        {
          'title': 'الشات بوت',
          'imagePath': 'assets/images/chatbot.png.webp',
          'screen': const ChatbotScreen(),
        },
      ]);
    } else if (accountType == 'doctor') {
      items.insert(0, {
        'title': 'متابعة المرضى',
        'imagePath': 'assets/images/patient_monitoring.png.webp',
        'screen': const PatientMonitoringScreen(),
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _dashboardItems.length,
      itemBuilder: (context, index) {
        final item = _dashboardItems[index];
        return buildDashboardButton(
          context,
          title: item['title'],
          imagePath: item['imagePath'],
          screen: item['screen'],
        );
      },
    );
  }
}