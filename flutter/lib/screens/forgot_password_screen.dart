import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'reset_password_screen.dart';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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

  Future<void> _sendOTP() async {
    if (!mounted) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      if (mounted) {
        _showSnackBar('يرجى إدخال البريد الإلكتروني', Colors.red);
      }
      return;
    }

    if (!isValidEmail(email)) {
      if (mounted) {
        _showSnackBar('يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/password_reset/'),
        headers: {'Content-Type': 'application/json'},
        body: {'email': email},
      );

      if (!mounted) return;

      if (response == null) {
        debugPrint('Response is null');
        _showSnackBar('فشل الاتصال بالخادم. تأكد من أن الخادم يعمل.', Colors.red);
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('تم إرسال الكود بنجاح على الإيميل!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email),
            ),
          );
        }
      } else {
        final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = responseBody['error'] ?? 'حدث خطأ أثناء إرسال الكود (كود الحالة: ${response.statusCode})';
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إعادة تعيين كلمة المرور',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient, // استخدام تدرج AppBar من الثيم
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient, // استخدام تدرج الخلفية من الثيم
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email),
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        filled: true, // تفعيل الخلفية
                        fillColor: Colors.white, // خلفية بيضاء
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), // زوايا دائرية خفيفة
                          borderSide: const BorderSide(color: Colors.black, width: 1), // خط أسود رفيع
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1), // نفس الخط لما يكون مش متفعل
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5), // خط أسمك لما يكون متفعل
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _sendOTP,
                            child: Text(
                              'إرسال الكود',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}