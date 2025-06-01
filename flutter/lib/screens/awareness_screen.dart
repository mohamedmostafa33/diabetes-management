import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:diabetes_management/config/theme.dart';

class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});

  @override
  AwarenessScreenState createState() => AwarenessScreenState();
}

class AwarenessScreenState extends State<AwarenessScreen> {
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      debugPrint('محاولة فتح الرابط: $url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('تم فتح الرابط بنجاح: $url');
      } else {
        debugPrint('لا يمكن فتح الرابط: لا يوجد تطبيق مناسب');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء فتح الرابط $url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء فتح الرابط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          '🚨 معلومات الطوارئ',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '🩸 في حالة انخفاض السكر:\n- تناول 3 تمرات\n- اشرب عصير\n- استرح 15 دقيقة وأعد القياس\n\n🔺 في حالة ارتفاع السكر:\n- شرب ماء\n- الراحة\n- إعادة القياس\n- مراجعة الطبيب',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
          textAlign: TextAlign.right,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إغلاق',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget buildListItem(String text, {bool isWarning = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: isWarning
            ? const Icon(Icons.warning, color: Colors.redAccent)
            : const Icon(Icons.check_circle_outline, color: Colors.teal),
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
        ),
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
            '🩺 التوعية والإرشادات',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildSectionTitle('✅ نصائح يومية'),
              buildListItem(
                '📏 قياس السكر بانتظام: قبل الأكل، وبعد الأكل بساعتين، وعند الشعور بأعراض',
              ),
              buildListItem(
                '🥗 اتباع نظام غذائي صحي: تقليل السكريات والحلويات، تناول الخضروات والفواكه قليلة السكر، الاعتماد على الحبوب الكاملة، تقسيم الوجبات',
              ),
              buildListItem(
                '🚶‍♂️ ممارسة الرياضة: المشي 30 دقيقة يوميًا، استشارة الطبيب قبل مجهود زائد',
              ),
              buildListItem(
                '💊 الالتزام بالأدوية: تناول الأدوية أو الإنسولين في مواعيدها وعدم تعديل الجرعات إلا باستشارة الطبيب',
              ),
              buildListItem(
                '💧 شرب كمية كافية من الماء لتجنب الجفاف',
              ),
              buildListItem(
                '🩺 متابعة الطبيب بشكل دوري: التحاليل، فحص القدمين والعينين والضغط',
              ),
              const Divider(
                color: Colors.teal,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              buildSectionTitle('⚠️ تحذيرات مهمة'),
              buildListItem(
                '❌ عدم تجاهل أعراض انخفاض أو ارتفاع السكر',
                isWarning: true,
              ),
              buildListItem(
                '❌ تجنب الأطعمة الجاهزة والمشروبات الغازية',
                isWarning: true,
              ),
              buildListItem(
                '❌ عدم ممارسة الرياضة وقت ارتفاع أو انخفاض السكر',
                isWarning: true,
              ),
              buildListItem(
                '❌ عدم التوقف عن الدواء بدون إذن الطبيب',
                isWarning: true,
              ),
              buildListItem(
                '❌ عدم استخدام الأعشاب أو الوصفات غير الموثوقة',
                isWarning: true,
              ),
              buildListItem(
                '❌ عدم إهمال جروح القدم، وتنظيفها فورًا ومراجعة الطبيب لو لم تلتئم',
                isWarning: true,
              ),
              const Divider(
                color: Colors.teal,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              buildSectionTitle('📹 فيديوهات ومصادر طبية'),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                  title: Text(
                    '🎥 التعامل مع انخفاض السكر',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _launchURL('https://youtu.be/8hdwXIv8XCk?si=tvdXRsESI_TvuY3T'),
                    child: Text(
                      'مشاهدة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                  title: Text(
                    '🎥 التعامل مع ارتفاع السكر',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _launchURL('https://youtu.be/bka7avp6_8s?si=bsfT21cuhx3Izr0_'),
                    child: Text(
                      'مشاهدة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.blueAccent),
                  title: Text(
                    '🌐 دليل وزارة الصحة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _launchURL('https://www.mohp.gov.eg/ArticleDetails.aspx?subject_id=2481'),
                    child: Text(
                      'زيارة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.blueAccent),
                  title: Text(
                    '🌐 هيئة الدواء المصرية',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _launchURL('https://edaegypt.gov.eg/'),
                    child: Text(
                      'زيارة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showEmergencyDialog(),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                label: Text(
                  '🚨 معلومات الطوارئ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}