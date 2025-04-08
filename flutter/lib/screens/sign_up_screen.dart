import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_/services/http_service.dart';

class SignUpScreen extends StatefulWidget {
  final String accountType;

  SignUpScreen({required this.accountType});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('http://127.0.0.1:8000/api/register/');
      var requestBody = {
        'email': _emailController.text.trim(),
        'password1': _passwordController.text.trim(), // Removed the backtick
        'password2': _confirmPasswordController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'account_type': widget.accountType,
      };

      if (widget.accountType == 'doctor') {
        requestBody['specialization'] = _specializationController.text.trim();
      }

      var response = await HttpService().makeRequest(
        method: 'POST',
        url: url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      var responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print('Response first_name: ${responseData['user']['first_name']}');
      print('Response last_name: ${responseData['user']['last_name']}');

      if (response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String accessToken = responseData['access'];
        String refreshToken = responseData['refresh'];
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_email', responseData['user']['email']);
        await prefs.setString('account_type', responseData['user']['account_type']);
        await prefs.setString('first_name', responseData['user']['first_name']);
        await prefs.setString('last_name', responseData['user']['last_name']);
        if (widget.accountType == 'doctor') {
          await prefs.setString('specialization', _specializationController.text.trim());
        }

        HttpService().setTokens(accessToken, refreshToken);
        _showSnackBar('تم إنشاء الحساب بنجاح!', Colors.green);
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showSnackBar(responseData['error'] ?? 'حدث خطأ ما', Colors.red);
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إنشاء حساب')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(labelText: 'الاسم الأول'),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال الاسم الأول';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(labelText: 'الاسم الأخير'),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال الاسم الأخير';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  if (widget.accountType == 'doctor')
                    Column(
                      children: [
                        TextFormField(
                          controller: _specializationController,
                          decoration: InputDecoration(labelText: 'التخصص'),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'يرجى إدخال التخصص';
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                      if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) return 'البريد الإلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                      if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
                      if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          child: Text('إنشاء الحساب'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}