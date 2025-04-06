import 'package:flutter/material.dart';

class AccountTypeScreen extends StatefulWidget {
  @override
  _AccountTypeScreenState createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String? _selectedAccountType;

  void _navigateToSignUp() {
    if (_selectedAccountType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار نوع الحساب'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/sign_up',
      arguments: _selectedAccountType!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختر نوع الحساب')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اختر نوع الحساب الخاص بك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildAccountTypeOption('مريض', 'patient', 'assets/images/patient_logo.png.webp'),
            SizedBox(height: 10),
            _buildAccountTypeOption('دكتور', 'doctor', 'assets/images/doctor_logo.png.webp'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _navigateToSignUp,
              child: Text('التالي', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption(String title, String value, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = value;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _selectedAccountType == value ? Colors.blue.withOpacity(0.2) : Colors.white,
          border: Border.all(color: _selectedAccountType == value ? Colors.blue : Colors.grey, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 80),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _selectedAccountType == value ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}