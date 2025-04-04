import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الصفحة الرئيسية',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('اسم المستخدم', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(context, 'تتبع مستوى السكر', Icons.monitor_heart, GlucoseTrackingScreen()),
            _buildDrawerItem(context, 'التذكيرات', Icons.notifications, RemindersScreen()),
            _buildDrawerItem(context, 'الشات بوت', Icons.chat, ChatbotScreen()),
            _buildDrawerItem(context, 'الأدوية البديلة', Icons.medical_services, AlternativeMedicationsScreen()),
            _buildDrawerItem(context, 'التنبؤ بمرض السكر', Icons.analytics, AIAnalysisScreen()),
            const Divider(),
            _buildDrawerItem(context, 'التواصل عبر واتساب', FontAwesomeIcons.whatsapp, null, isWhatsApp: true),
            _buildDrawerItem(context, 'تسجيل الخروج', Icons.logout, LoginScreen(), isLogout: true),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (_showWelcomeMessage)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'مرحبًا بك في تطبيق إدارة مرض السكري',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            const Expanded(child: DashboardGrid()),
          ],
        ),
      ),
    );
  }
}

Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget? screen, {bool isWhatsApp = false, bool isLogout = false}) {
  return ListTile(
    leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue),
    title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black)),
    onTap: () {
      if (isWhatsApp) {
        launchUrl(Uri.parse("https://wa.me/+201276619806"));
      } else if (isLogout) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
      }
    },
  );
}

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: _dashboardItems.length,
      itemBuilder: (context, index) {
        final item = _dashboardItems[index];
        return _buildDashboardButton(
          context,
          title: item['title'],
          imagePath: item['imagePath'],
          screen: item['screen'],
        );
      },
    );
  }
}

Widget _buildDashboardButton(BuildContext context, {
  required String title,
  required String imagePath,
  required Widget screen,
}) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    },
    borderRadius: BorderRadius.circular(12),
    splashColor: Colors.blue.withOpacity(0.2),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  height: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
    'title': 'الشات بوت',
    'imagePath': 'assets/images/chatbot.png.webp',
    'screen': ChatbotScreen(),
  },
  {
    'title': 'الأدوية البديلة',
    'imagePath': 'assets/images/medications.png.webp',
    'screen': AlternativeMedicationsScreen(),
  },
  {
    'title': 'التنبؤ بمرض السكر',
    'imagePath': 'assets/images/ai_analysis.png.webp',
    'screen': AIAnalysisScreen(),
  },
];