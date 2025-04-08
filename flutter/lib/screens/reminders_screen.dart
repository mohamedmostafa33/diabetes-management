import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_/services/http_service.dart';
import 'package:flutter_/services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReminderType;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = false;

  final List<String> _reminderTypes = [
    'قياس السكر',
    'الدواء',
    'شرب الماء',
  ];

  final Map<String, String> _reminderTypeToApiValue = {
    'قياس السكر': 'blood_glucose_test',
    'الدواء': 'medication',
    'شرب الماء': 'hydration',
  };

  final Map<String, String> _apiValueToReminderType = {
    'blood_glucose_test': 'قياس السكر',
    'medication': 'الدواء',
    'hydration': 'شرب الماء',
  };

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? refreshToken = prefs.getString('refresh_token');
      if (accessToken != null && refreshToken != null) {
        HttpService().setTokens(accessToken, refreshToken);
      }

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://127.0.0.1:8000/api/get-reminders/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _reminders = List<Map<String, dynamic>>.from(responseData).map((reminder) {
            return {
              ...reminder,
              'reminder_type': _apiValueToReminderType[reminder['reminder_type']] ?? reminder['reminder_type'],
            };
          }).toList();
        });

        for (var reminder in _reminders) {
          if (reminder['active']) {
            _scheduleNotificationForReminder(reminder);
          }
        }
      } else {
        _showSnackBar('فشل تحميل التذكيرات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      _showSnackBar('يرجى اختيار وقت التذكير', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var requestBody = {
        'reminder_type': _reminderTypeToApiValue[_selectedReminderType]!,
        'reminder_time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        'active': true,
      };

      var response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://127.0.0.1:8000/api/create-reminder/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 201) {
        var newReminder = jsonDecode(response.body);
        _showSnackBar('تم إضافة التذكير بنجاح!', Colors.green);
        _selectedReminderType = null;
        _selectedTime = null;

        _scheduleNotificationForReminder(newReminder);

        _loadReminders();
      } else {
        var responseData = jsonDecode(response.body);
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء إضافة التذكير', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateReminder(int id, String reminderType, TimeOfDay newTime) async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var requestBody = {
        'reminder_type': _reminderTypeToApiValue[reminderType]!,
        'reminder_time': '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00',
      };

      var response = await HttpService().makeRequest(
        method: 'PUT',
        url: Uri.parse('http://127.0.0.1:8000/api/update-reminder/$id/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        var updatedReminder = jsonDecode(response.body);
        _showSnackBar('تم تعديل التذكير بنجاح!', Colors.green);

        await NotificationService.cancelNotification(id);
        _scheduleNotificationForReminder(updatedReminder);

        _loadReminders();
      } else {
        var responseData = jsonDecode(response.body);
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء تعديل التذكير', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteReminder(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var response = await HttpService().makeRequest(
        method: 'DELETE',
        url: Uri.parse('http://127.0.0.1:8000/api/delete-reminder/$id/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 204) {
        _showSnackBar('تم حذف التذكير بنجاح!', Colors.green);
        await NotificationService.cancelNotification(id);
        _loadReminders();
      } else {
        _showSnackBar('فشل حذف التذكير', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _scheduleNotificationForReminder(Map<String, dynamic> reminder) {
    final timeParts = reminder['reminder_time'].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    NotificationService.scheduleDailyNotification(
      id: reminder['id'],
      title: 'تذكير: ${reminder['reminder_type']}',
      body: 'حان وقت ${reminder['reminder_type']}!',
      scheduledTime: scheduledTime,
    );
  }

  void _selectTime(BuildContext context, {TimeOfDay? initialTime, required Function(TimeOfDay) onTimeSelected}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatTime(TimeOfDay time) {
    final String period = time.period == DayPeriod.am ? "صباحًا" : "مساءً";
    return "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} $period";
  }

  void _showEditDialog(Map<String, dynamic> reminder) {
    String? editReminderType = _apiValueToReminderType[reminder['reminder_type']] ?? reminder['reminder_type'];
    TimeOfDay? editTime;
    final timeParts = reminder['reminder_time'].split(':');
    editTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل التذكير'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: editReminderType,
                    decoration: InputDecoration(
                      labelText: 'نوع التذكير',
                      border: OutlineInputBorder(),
                    ),
                    items: _reminderTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        editReminderType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار نوع التذكير';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectTime(
                            context,
                            initialTime: editTime,
                            onTimeSelected: (picked) {
                              setState(() {
                                editTime = picked;
                              });
                            },
                          ),
                          child: Text(
                            editTime == null ? 'اختر الوقت' : 'الوقت: ${_formatTime(editTime!)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (editReminderType != null && editTime != null) {
                  _updateReminder(reminder['id'], editReminderType!, editTime!);
                  Navigator.pop(context);
                } else {
                  _showSnackBar('يرجى ملء جميع الحقول', Colors.red);
                }
              },
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التذكيرات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إضافة تذكير جديد:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedReminderType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'نوع التذكير',
                      prefixIcon: Icon(Icons.notifications),
                    ),
                    items: _reminderTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedReminderType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار نوع التذكير';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _selectTime(
                            context,
                            onTimeSelected: (picked) {
                              setState(() {
                                _selectedTime = picked;
                              });
                            },
                          ),
                          child: Text(
                            _selectedTime == null
                                ? 'اختر الوقت'
                                : 'التذكير: ${_formatTime(_selectedTime!)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _addReminder,
                          child: Text('إضافة التذكير'),
                        ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'التذكيرات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _reminders.isEmpty
                      ? Center(child: Text('لا توجد تذكيرات'))
                      : ListView.builder(
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: Icon(Icons.notifications, color: Colors.blue),
                                title: Text(reminder['reminder_type']),
                                subtitle: Text('الوقت: ${reminder['reminder_time']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditDialog(reminder),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteReminder(reminder['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}