import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_/services/http_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  void _sendOTP(BuildContext context) async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(context, 'يرجى إدخال البريد الإلكتروني', Colors.red);
    } else if (!isValidEmail(email)) {
      _showSnackBar(context, 'يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
    } else {
      try {
        setState(() {
          _isLoading = true;
        });

        var response = await HttpService().makeRequest(
          method: 'POST',
          url: Uri.parse('http://10.0.2.2:8000/api/password_reset/'),
          headers: {'Content-Type': 'application/json'},
          body: {'email': email}, // رجعنا الـ body يكون map
        );

        if (response == null) {
          print('Response is null');
          _showSnackBar(context, 'فشل الاتصال بالخادم. تأكد من أن الخادم يعمل.', Colors.red);
          return;
        }

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          _showSnackBar(context, 'تم إرسال الكود بنجاح على الإيميل!', Colors.green);
          await Future.delayed(const Duration(seconds: 1));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email),
            ),
          );
        } else {
          var responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          String errorMessage = responseBody['error'] ?? 'حدث خطأ أثناء إرسال الكود (كود الحالة: ${response.statusCode})';
          _showSnackBar(context, errorMessage, Colors.red);
        }
      } catch (e) {
        print('Error: $e');
        _showSnackBar(context, 'حدث خطأ: $e', Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _sendOTP(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('إرسال الكود'),
            ),
          ],
        ),
      ),
    );
  }
}