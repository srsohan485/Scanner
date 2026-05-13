import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
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
                child: Icon(
                  Icons.qr_code_2,
                  size: 70.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 32.h),
              _FeatureCard(
                icon: Icons.qr_code_scanner,
                title: 'Scan QR Code',
                subtitle: 'Scan any QR code or barcode',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanQrCode()),
                ),
              ),
              SizedBox(height: 16.h),
              _FeatureCard(
                icon: Icons.add_box_outlined,
                title: 'Generate QR Code',
                subtitle: 'Create QR code from text or URL',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneratorCode()),
                ),
              ),
              SizedBox(height: 16.h),
              _FeatureCard(
                icon: Icons.document_scanner,
                title: 'Document Scanner',
                subtitle: 'Scan documents & save as PDF',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScannerPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
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
                    child: Icon(
                      Icons.qr_code_2,
                      size: 36.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'ScanPro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'QR Scanner & Document Manager',
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
                  title: 'Home',
                  color: const Color(0xFF2196F3),
                  onTap: () => Navigator.pop(context),
                ),
                _drawerItem(
                  icon: Icons.history,
                  title: 'Scan History',
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
                  title: 'Saved Documents',
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
                  title: 'Settings',
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
                  title: 'Rate Us',
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
                  title: 'Share App',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Check out ScanPro!\nhttps://play.google.com/store/apps/details?id=com.yourpackage.scanner',
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
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
                  title: 'Help & FAQ',
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
                  title: 'About',
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
              'Version $_version',
              style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
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
          color: const Color(0xFF333333),
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey),
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
              'ScanPro',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'Version $_version',
              style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'QR Scanner & Document Manager',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 8.h),
            Text(
              'Developed by',
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
            child: const Text('Close'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
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
                      color: const Color(0xFF333333),
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