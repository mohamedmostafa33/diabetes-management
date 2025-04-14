import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management/config/theme.dart';

class GlucoseTrackingScreen extends StatefulWidget {
  const GlucoseTrackingScreen({super.key});

  @override
  GlucoseTrackingScreenState createState() => GlucoseTrackingScreenState();
}

class GlucoseTrackingScreenState extends State<GlucoseTrackingScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedReadingType = 'صائم';
  List<Map<String, String>> glucoseReadings = [];

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDateTime);
    final String formattedTime = DateFormat('h:mm a')
        .format(pickedDateTime)
        .replaceAll('AM', 'صباحًا')
        .replaceAll('PM', 'مساءً');

    if (!mounted) return;
    setState(() {
      _dateController.text = formattedDate;
      _timeController.text = formattedTime;
    });
  }

  void _addGlucoseReading() {
    if (_glucoseController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty) {
      setState(() {
        glucoseReadings.add({
          'value': _glucoseController.text,
          'date': _dateController.text,
          'time': _timeController.text,
          'type': _selectedReadingType,
        });
        _glucoseController.clear();
        _dateController.clear();
        _timeController.clear();
      });

      _showSnackBar('تمت إضافة القراءة بنجاح!', Colors.green);
    } else {
      _showSnackBar('يرجى ملء جميع الحقول!', Colors.red);
    }
  }

  void _deleteReading(int index) {
    setState(() {
      glucoseReadings.removeAt(index);
    });
    _showSnackBar('تم حذف القراءة بنجاح!', Colors.green);
  }

  void _editReading(int index) {
    final reading = glucoseReadings[index];
    _glucoseController.text = reading['value']!;
    _dateController.text = reading['date']!;
    _timeController.text = reading['time']!;
    setState(() {
      _selectedReadingType = reading['type']!;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل القراءة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _glucoseController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'مستوى السكر (mg/dL)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                ),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'الوقت',
                ),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedReadingType,
                items: ['صائم', 'قبل الأكل', 'بعد الأكل']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReadingType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'نوع القراءة',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (_glucoseController.text.isNotEmpty &&
                  _dateController.text.isNotEmpty &&
                  _timeController.text.isNotEmpty) {
                setState(() {
                  glucoseReadings[index] = {
                    'value': _glucoseController.text,
                    'date': _dateController.text,
                    'time': _timeController.text,
                    'type': _selectedReadingType,
                  };
                });
                _glucoseController.clear();
                _dateController.clear();
                _timeController.clear();
                Navigator.of(context).pop();
                _showSnackBar('تم تعديل القراءة بنجاح!', Colors.green);
              } else {
                _showSnackBar('يرجى ملء جميع الحقول!', Colors.red);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تتبع مستوى السكر',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'أدخل مستوى السكر',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _glucoseController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'مستوى السكر (mg/dL)',
                  prefixIcon: const Icon(Icons.monitor_heart),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      onTap: () => _selectDateTime(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'الوقت',
                        prefixIcon: const Icon(Icons.access_time),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      onTap: () => _selectDateTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedReadingType,
                items: ['صائم', 'قبل الأكل', 'بعد الأكل']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReadingType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'نوع القراءة',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addGlucoseReading,
                child: const Text('حفظ القراءة'),
              ),
              const SizedBox(height: 20),
              Text(
                'القراءات السابقة',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: glucoseReadings.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.water_drop, color: Colors.teal),
                        title: Text(
                          '${glucoseReadings[index]['value']} mg/dL',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ: ${glucoseReadings[index]['date']}'),
                            Text('الوقت: ${glucoseReadings[index]['time']}'),
                            Text('نوع القراءة: ${glucoseReadings[index]['type']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editReading(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteReading(index),
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
      ),
    );
  }
}