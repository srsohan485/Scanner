import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'scan_qr_code.dart';
import 'generator_code.dart';
import 'document_scanner_page.dart';
import 'history_page.dart';
import 'saved_documents_page.dart';
import 'settings_page.dart';
import 'privacy_policy_page.dart';
import 'help_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _version = '';
  String _language = 'en';

  String _t(String en, String bn) => _language == 'bn' ? bn : en;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadLanguage();
    localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _language = prefs.getString('language') ?? 'en');
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _language = prefs.getString('language') ?? 'en');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('ScanPro', 'স্ক্যানপ্রো')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
            tooltip: _t('Scan History', 'স্ক্যান ইতিহাস'),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.qr_code_2, size: 70.sp, color: Colors.white),
              ),
              SizedBox(height: 32.h),
              Text(
                _t('What would you like to do?', 'আপনি কী করতে চান?'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 32.h),
              _FeatureCard(
                icon: Icons.qr_code_scanner,
                title: _t('Scan QR Code', 'QR কোড স্ক্যান'),
                subtitle: _t(
                  'Scan any QR code or barcode',
                  'যেকোনো QR কোড স্ক্যান করুন',
                ),
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanQrCode()),
                ),
              ),
              SizedBox(height: 16.h),
              _FeatureCard(
                icon: Icons.add_box_outlined,
                title: _t('Generate QR Code', 'QR কোড তৈরি'),
                subtitle: _t(
                  'Create QR code from text or URL',
                  'টেক্সট থেকে QR তৈরি করুন',
                ),
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneratorCode()),
                ),
              ),
              SizedBox(height: 16.h),
              _FeatureCard(
                icon: Icons.document_scanner,
                title: _t('Document Scanner', 'ডকুমেন্ট স্ক্যানার'),
                subtitle: _t(
                  'Scan documents & save as PDF',
                  'ডকুমেন্ট স্ক্যান করুন',
                ),
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentScannerPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = darkModeNotifier.value;
    final drawerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(Icons.qr_code_2, size: 36.sp, color: Colors.white),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _t('ScanPro', 'স্ক্যানপ্রো'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _t(
                      'QR Scanner & Document Manager',
                      'QR স্ক্যানার ও ডকুমেন্ট ম্যানেজার',
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  icon: Icons.home,
                  title: _t('Home', 'হোম'),
                  color: const Color(0xFF2196F3),
                  onTap: () => Navigator.pop(context),
                ),
                _drawerItem(
                  icon: Icons.history,
                  title: _t('Scan History', 'স্ক্যান ইতিহাস'),
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.folder_open,
                  title: _t('Saved Documents', 'সংরক্ষিত ডকুমেন্ট'),
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedDocumentsPage(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.settings,
                  title: _t('Settings', 'সেটিংস'),
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                _drawerItem(
                  icon: Icons.star_rate,
                  title: _t('Rate Us', 'রেটিং দিন'),
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.yourpackage.scanner',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.share,
                  title: _t('Share App', 'অ্যাপ শেয়ার করুন'),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      _t(
                        'Check out ScanPro!\nhttps://play.google.com/store/apps/details?id=com.yourpackage.scanner',
                        'স্ক্যানপ্রো দেখুন!\nhttps://play.google.com/store/apps/details?id=com.yourpackage.scanner',
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.privacy_tip,
                  title: _t('Privacy Policy', 'গোপনীয়তা নীতি'),
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.help_outline,
                  title: _t('Help & FAQ', 'সাহায্য ও FAQ'),
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                _drawerItem(
                  icon: Icons.info_outline,
                  title: _t('About', 'সম্পর্কে'),
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              '${_t('Version', 'ভার্সন')} $_version',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = darkModeNotifier.value;
    return ListTile(
      onTap: onTap,
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
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF333333),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14.sp,
        color: Colors.grey,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(Icons.qr_code_2, size: 40.sp, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text(
              _t('ScanPro', 'স্ক্যানপ্রো'),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_t('Version', 'ভার্সন')} $_version',
              style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              _t(
                'QR Scanner & Document Manager',
                'QR স্ক্যানার ও ডকুমেন্ট ম্যানেজার',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 8.h),
            Text(
              _t('Developed by', 'ডেভেলপার'),
              style: TextStyle(color: Colors.grey, fontSize: 12.sp),
            ),
            Text(
              'Sayedur Rahman Sohan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(_t('Close', 'বন্ধ করুন')),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 30.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}