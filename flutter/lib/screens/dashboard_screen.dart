import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_/services/http_service.dart';
import 'package:flutter_/services/notification_service.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name');
      _lastName = prefs.getString('last_name');
      _email = prefs.getString('user_email');
      _accountType = prefs.getString('account_type');
      _specialization = prefs.getString('specialization');
      print('Loaded first_name: $_firstName');
      print('Loaded last_name: $_lastName');
      print('Loaded email: $_email');
      print('Loaded account_type: $_accountType');
      print('Loaded specialization: $_specialization');
    });

    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && refreshToken != null) {
      HttpService().setTokens(accessToken, refreshToken);
      print('Tokens updated in HttpService: Access Token: $accessToken, Refresh Token: $refreshToken');
    }
  }

  Future<void> _logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      print('Access Token being sent: $accessToken');

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج')),
        );
        await prefs.clear();
        HttpService().clearTokens();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://127.0.0.1:8000/api/logout/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response == null) {
        await prefs.clear();
        HttpService().clearTokens();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      await prefs.clear();
      HttpService().clearTokens();

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الخروج: ${response.statusCode} - ${response.body}')),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج: $e')),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      HttpService().clearTokens();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget? screen, {bool isLogout = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue, size: 30),
        title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black, fontSize: 18)),
        onTap: () {
          if (isLogout) {
            _logout();
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
          }
        },
        trailing: null,
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required String title, required String imagePath, required Widget screen}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          print('Navigating to: $title');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              print('Navigating to: $title');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => screen),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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

  // دالة لعرض الإشعارات في Dialog
  void _showNotificationsDialog() async {
    List<Map<String, dynamic>> loggedNotifications = await NotificationService.getLoggedNotifications();

    // تصنيف الإشعارات حسب النوع
    Map<String, List<Map<String, dynamic>>> notificationsByType = {
      'Blood Glucose Test': [],
      'Medication': [],
      'Hydration': [],
    };

    for (var notification in loggedNotifications) {
      String reminderType = notification['reminder_type'];
      if (notificationsByType.containsKey(reminderType)) {
        notificationsByType[reminderType]!.add(notification);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('الإشعارات المرسلة'),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: notificationsByType.entries.map((entry) {
                String type = entry.key;
                List<Map<String, dynamic>> notifications = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('لا توجد إشعارات مرسلة من هذا النوع'),
                      )
                    else
                      ...notifications.map((notification) {
                        DateTime scheduledTime = DateTime.parse(notification['scheduled_time']);
                        return ListTile(
                          title: Text(notification['title']),
                          subtitle: Text(
                            'الوقت: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                          ),
                        );
                      }).toList(),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الصفحة الرئيسية',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _showNotificationsDialog, // استدعاء الدالة لعرض الإشعارات
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        _accountType == 'doctor' ? 'assets/images/doctor_logo.png.webp' : 'assets/images/patient_logo.png.webp',
                        height: 80,
                        width: 80,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _email ?? 'الإيميل',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _accountType == 'doctor' ? 'دكتور' : 'مريض',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(context, 'تتبع مستوى السكر', Icons.monitor_heart, GlucoseTrackingScreen()),
              _buildDrawerItem(context, 'التذكيرات', Icons.notifications, RemindersScreen()),
              _buildDrawerItem(context, 'التنبؤ بمرض السكر', Icons.analytics, AIAnalysisScreen()),
              _buildDrawerItem(context, 'الأدوية البديلة', Icons.medical_services, AlternativeMedicationsScreen()),
              _buildDrawerItem(context, 'الشات بوت', Icons.chat, ChatbotScreen()),
              _buildDrawerItem(context, 'الملف الشخصي', Icons.person, ProfileScreen()),
              const Divider(),
              const Spacer(),
              _buildDrawerItem(context, 'تسجيل الخروج', Icons.logout, null, isLogout: true),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_showWelcomeMessage)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'مرحبًا بك في تطبيق إدارة مرض السكري',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: DashboardGrid(
                  buildDashboardButton: _buildDashboardButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final Widget Function(BuildContext context, {required String title, required String imagePath, required Widget screen}) buildDashboardButton;

  const DashboardGrid({Key? key, required this.buildDashboardButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
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

final List<Map<String, dynamic>> _dashboardItems = [
  {
    'title': 'تتبع مستوى السكر',
    'imagePath': 'assets/images/glucose_tracking.png.webp',
    'screen': GlucoseTrackingScreen(),
  },
  {
    'title': 'التذكيرات',
    'imagePath': 'assets/images/reminders.png.webp',
    'screen': RemindersScreen(),
  },
  {
    'title': 'التنبؤ بمرض السكر',
    'imagePath': 'assets/images/ai_analysis.png.webp',
    'screen': AIAnalysisScreen(),
  },
  {
    'title': 'الأدوية البديلة',
    'imagePath': 'assets/images/medications.png.webp',
    'screen': AlternativeMedicationsScreen(),
  },
  {
    'title': 'الشات بوت',
    'imagePath': 'assets/images/chatbot.png.webp',
    'screen': ChatbotScreen(),
  },
  {
    'title': 'الملف الشخصي',
    'imagePath': 'assets/images/profile.png.webp',
    'screen': ProfileScreen(),
  },
];