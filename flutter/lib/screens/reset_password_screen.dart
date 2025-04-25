import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'dart:convert';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String otp = _codeController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/password_reset_confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: {
          'otp': otp,
          'new_password': newPassword,
          'confirm_new_password': confirmPassword,
        },
      );

      if (response == null) {
        debugPrint('Response is null');
        if (mounted) {
          _showSnackBar('فشل الاتصال بالخادم. تأكد من أن الخادم يعمل.', Colors.red);
        }
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('تم إعادة تعيين كلمة المرور بنجاح', Colors.green);
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        }
      } else {
        var responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        String errorMessage;
        if (responseBody['error'] == 'Invalid OTP') {
          errorMessage = 'الكود غير صحيح .. من فضلك ادخل الكود الصحيح';
        } else if (responseBody['error'] == 'New password cannot be the same as the old password') {
          errorMessage = 'كلمة المرور الجديدة لا يمكن أن تكون نفس كلمة المرور القديمة';
        } else {
          errorMessage = responseBody['error'] ?? 'حدث خطأ أثناء إعادة التعيين (كود الحالة: ${response.statusCode})';
        }
        if (mounted) {
          _showSnackBar(errorMessage, Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        _showSnackBar('حدث خطأ: ${e.toString()}', Colors.red);
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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'إعادة تعيين كلمة المرور',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'أدخل الكود المكون من 6 أرقام الذي تلقيته عبر البريد الإلكتروني',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'الكود',
                            counterText: '',
                            prefixIcon: const Icon(Icons.code),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال الكود';
                            }
                            if (value.length != 6) {
                              return 'يجب أن يكون الكود مكونًا من 6 أرقام';
                            }
                            if (!RegExp(r'^[\d\u0660-\u0669]{6}$').hasMatch(value)) {
                              return 'يجب أن يحتوي الكود على أرقام فقط';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _isObscure1,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور الجديدة',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure1 ? Icons.visibility_off : Icons.visibility,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure1 = !_isObscure1;
                                });
                              },
                            ),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة المرور الجديدة';
                            }
                            if (value.length < 6) {
                              return 'يجب أن تكون كلمة المرور على الأقل 6 أحرف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _isObscure2,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure2 ? Icons.visibility_off : Icons.visibility,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure2 = !_isObscure2;
                                });
                              },
                            ),
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
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'كلمة المرور لا تطابق التأكيد';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _resetPassword,
                                child: Text(
                                  'إعادة تعيين كلمة المرور',
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
        ),
      ),
    );
  }
}