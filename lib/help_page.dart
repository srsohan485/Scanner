import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  final List<Map<String, String>> faqs = const [
    {
      'q': 'কিভাবে QR code scan করব?',
      'a': 'Home page থেকে "Scan QR Code" button এ tap করুন। Camera বা Gallery থেকে scan করতে পারবেন।',
    },
    {
      'q': 'QR code generate কিভাবে করব?',
      'a': '"Generate QR Code" button এ tap করুন। Type select করুন (URL, WiFi, Contact ইত্যাদি), তারপর information দিন।',
    },
    {
      'q': 'Document scan করে PDF বানাব কিভাবে?',
      'a': '"Document Scanner" এ যান। "Start Scanning" দিয়ে document scan করুন, তারপর "Create PDF" button এ tap করুন।',
    },
    {
      'q': 'Scan history কোথায় পাব?',
      'a': 'Top right এর history icon অথবা Drawer থেকে "Scan History" তে যান।',
    },
    {
      'q': 'WiFi QR scan করলে কি automatically connect হবে?',
      'a': 'হ্যাঁ। WiFi QR scan করলে "Connect" button আসবে। সেটায় tap করলে automatically connect হবে।',
    },
    {
      'q': 'Document থেকে text copy করব কিভাবে?',
      'a': 'Document Scanner এ "Extract Text" button এ tap করুন। Text দেখার পর "Copy" button দিয়ে copy করুন।',
    },
    {
      'q': 'Generated QR code save করব কিভাবে?',
      'a': 'QR generate করার পর "Save" button এ tap করলে Gallery তে save হবে।',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Help & FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2196F3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Q',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                faqs[index]['q']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          faqs[index]['a']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}