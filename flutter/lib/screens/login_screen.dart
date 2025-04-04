import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'account_type_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final http.Client _client = http.Client();

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  Future<void> _saveSession(String email, String accountType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('account_type', accountType);
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى إدخال البريد الإلكتروني وكلمة المرور', Colors.red);
      return;
    } else if (!isValidEmail(email)) {
      _showSnackBar('يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
      return;
    } else if (password.length < 6) {
      _showSnackBar('يجب أن تكون كلمة المرور 6 أحرف أو أكثر', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await _client.post(
        Uri.parse('http://127.0.0.1:8000/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String accountType = data['user']['account_type'];
        await _saveSession(email, accountType);
        _showSnackBar('تم تسجيل الدخول بنجاح!', Colors.green);

        // ✅ توجيه المستخدم بناءً على نوع الحساب
        if (accountType == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AccountTypeScreen()),
          );
        }
      } else {
        _showSnackBar('فشل تسجيل الدخول: ${data['message']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
      print("Error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  } 

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسجيل الدخول')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '👋 مرحبًا!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('تسجيل الدخول'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: Text('هل نسيت كلمة المرور؟'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountTypeScreen()),
                );
              },
              child: Text("ليس لديك حساب؟ إنشاء حساب"),
            ),
          ],
        ),
      ),
    );
  }
}
