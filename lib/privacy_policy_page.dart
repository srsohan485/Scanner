import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2196F3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(
            'Data Collection',
            'ScanPro does not collect any personal data. All scanned QR codes and documents are stored locally on your device only.',
          ),
          _section(
            'Camera Permission',
            'Camera permission is used only for scanning QR codes and documents. We do not store or share any camera data.',
          ),
          _section(
            'Storage Permission',
            'Storage permission is used to save scanned documents and generated QR codes to your device.',
          ),
          _section(
            'Internet Permission',
            'Internet permission is used only when you choose to open URLs from scanned QR codes.',
          ),
          _section(
            'Third Party Services',
            'This app uses Google ML Kit for text recognition. Please refer to Google\'s privacy policy for more information.',
          ),
          _section(
            'Contact',
            'If you have any questions about this privacy policy, please contact us.',
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}