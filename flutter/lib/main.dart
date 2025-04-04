import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/glucose_tracking_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/alternative_medications_screen.dart';
import 'screens/account_type_screen.dart'; // تم إضافة شاشة اختيار نوع الحساب

void main() {
  runApp(DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diabetes Management',
      theme: ThemeData(
        primaryColor: Colors.blue[600],
        scaffoldBackgroundColor: Colors.blue[50],
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue[600],
          textTheme: ButtonTextTheme.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueGrey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/glucose_tracking': (context) => GlucoseTrackingScreen(),
        '/reminders': (context) => RemindersScreen(),
        '/ai_analysis': (context) => AIAnalysisScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/chatbot': (context) => ChatbotScreen(),
        '/alternative_medications': (context) => AlternativeMedicationsScreen(),
        '/account_type': (context) => AccountTypeScreen(), // إضافة مسار لشاشة اختيار نوع الحساب
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/sign_up') {
          final role = settings.arguments as String? ?? 'مريض';
          return MaterialPageRoute(
            builder: (context) => SignUpScreen(accountType: role),
          );
        }
        return null;
      },
    );
  }
}
