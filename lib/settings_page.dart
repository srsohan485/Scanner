import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoOpenUrl = true;
  bool _saveHistory = true;
  String _language = 'en';

  // ✅ Language helper
  String _t(String en, String bn) => _language == 'bn' ? bn : en;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoOpenUrl = prefs.getBool('auto_open_url') ?? true;
      _saveHistory = prefs.getBool('save_history') ?? true;
      _language = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Settings', 'সেটিংস')),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _sectionTitle(_t('Scanner', 'স্ক্যানার')),
          _settingCard(cardColor, [
            _switchTile(
              _t('Auto Open URL', 'স্বয়ংক্রিয় URL খোলা'),
              _t('Automatically open browser when URL is scanned',
                  'URL স্ক্যান হলে স্বয়ংক্রিয়ভাবে ব্রাউজার খুলবে'),
              Icons.link,
              Colors.blue,
              _autoOpenUrl,
                  (value) {
                setState(() => _autoOpenUrl = value);
                _saveSetting('auto_open_url', value);
              },
            ),
            _switchTile(
              _t('Save History', 'ইতিহাস সেভ করুন'),
              _t('Save scan history', 'স্ক্যান ইতিহাস সংরক্ষণ করুন'),
              Icons.history,
              Colors.orange,
              _saveHistory,
                  (value) {
                setState(() => _saveHistory = value);
                _saveSetting('save_history', value);
              },
            ),
          ]),

          SizedBox(height: 16.h),

          _sectionTitle(_t('Storage', 'স্টোরেজ')),
          _settingCard(cardColor, [
            ListTile(
              leading: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.delete_sweep,
                  color: Colors.red,
                  size: 20.sp,
                ),
              ),
              title: Text(
                _t('Clear Scan History', 'স্ক্যান ইতিহাস মুছুন'),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
              subtitle: Text(
                _t('Delete all scan history', 'সব স্ক্যান ইতিহাস মুছে ফেলবে'),
                style: TextStyle(fontSize: 12.sp),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
              onTap: () => _showClearDialog(
                _t('Clear History', 'ইতিহাস মুছুন'),
                _t('Delete all scan history?', 'সব স্ক্যান ইতিহাস মুছে ফেলবেন?'),
                    () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('scan_history');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _t('History cleared!', 'ইতিহাস মুছে গেছে!'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2196F3),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2196F3),
      ),
    );
  }

  void _showClearDialog(
      String title,
      String content,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Cancel', 'বাতিল')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _t('Clear', 'মুছুন'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}