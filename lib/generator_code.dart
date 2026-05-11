import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GeneratorCode extends StatefulWidget {
  const GeneratorCode({Key? key}) : super(key: key);

  @override
  State<GeneratorCode> createState() => _GeneratorCodeState();
}

class _GeneratorCodeState extends State<GeneratorCode> {
  final GlobalKey _qrKey = GlobalKey();
  String qrData = '';
  bool isSaving = false;
  String selectedType = 'Text';

  // ✅ সব QR Type এর controllers
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();
  final TextEditingController _smsPhoneController = TextEditingController();
  final TextEditingController _smsMessageController = TextEditingController();
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  String _wifiType = 'WPA';
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  final List<Map<String, dynamic>> _types = [
    {'label': 'Text', 'icon': Icons.text_fields},
    {'label': 'URL', 'icon': Icons.link},
    {'label': 'Phone', 'icon': Icons.phone},
    {'label': 'Email', 'icon': Icons.email},
    {'label': 'SMS', 'icon': Icons.sms},
    {'label': 'WiFi', 'icon': Icons.wifi},
    {'label': 'Location', 'icon': Icons.location_on},
    {'label': 'Contact', 'icon': Icons.contact_page},
  ];

  void _generateQR() {
    String data = '';
    switch (selectedType) {
      case 'Text':
        data = _textController.text.trim();
        break;
      case 'URL':
        data = _urlController.text.trim();
        if (!data.startsWith('http')) data = 'https://$data';
        break;
      case 'Phone':
        data = 'tel:${_phoneController.text.trim()}';
        break;
      case 'Email':
        data =
        'mailto:${_emailController.text.trim()}?subject=${_emailSubjectController.text.trim()}&body=${_emailBodyController.text.trim()}';
        break;
      case 'SMS':
        data =
        'smsto:${_smsPhoneController.text.trim()}:${_smsMessageController.text.trim()}';
        break;
      case 'WiFi':
        data =
        'WIFI:T:$_wifiType;S:${_wifiSsidController.text.trim()};P:${_wifiPasswordController.text.trim()};;';
        break;
      case 'Location':
        data = 'geo:${_latController.text.trim()},${_lngController.text.trim()}';
        break;
      case 'Contact':
        data = '''BEGIN:VCARD
VERSION:3.0
FN:${_contactNameController.text.trim()}
TEL:${_contactPhoneController.text.trim()}
EMAIL:${_contactEmailController.text.trim()}
END:VCARD''';
        break;
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => qrData = data);
    FocusScope.of(context).unfocus();
  }

  Future<File?> _captureQRImage() async {
    try {
      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveQRCode() async {
    if (qrData.isEmpty) return;
    setState(() => isSaving = true);
    try {
      final file = await _captureQRImage();
      if (file == null) throw Exception('Capture failed');
      final bytes = await file.readAsBytes();
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
        androidRelativePath: 'Pictures/QRCodes',
        androidExistNotSave: false,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code saved to Gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save QR Code'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _shareQRCode() async {
    if (qrData.isEmpty) return;
    try {
      final file = await _captureQRImage();
      if (file == null) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code generated by QR Scanner App',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share QR Code')),
      );
    }
  }

  // ✅ Type অনুযায়ী Input Fields
  Widget _buildInputFields() {
    switch (selectedType) {
      case 'Text':
        return _buildField(_textController, 'Enter text', Icons.text_fields, maxLines: 4);

      case 'URL':
        return _buildField(_urlController, 'Enter URL (e.g. google.com)', Icons.link);

      case 'Phone':
        return _buildField(_phoneController, 'Enter phone number', Icons.phone, type: TextInputType.phone);

      case 'Email':
        return Column(
          children: [
            _buildField(_emailController, 'Email address', Icons.email, type: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _buildField(_emailSubjectController, 'Subject (optional)', Icons.subject),
            const SizedBox(height: 10),
            _buildField(_emailBodyController, 'Message (optional)', Icons.message, maxLines: 3),
          ],
        );

      case 'SMS':
        return Column(
          children: [
            _buildField(_smsPhoneController, 'Phone number', Icons.phone, type: TextInputType.phone),
            const SizedBox(height: 10),
            _buildField(_smsMessageController, 'Message (optional)', Icons.message, maxLines: 3),
          ],
        );

      case 'WiFi':
        return Column(
          children: [
            _buildField(_wifiSsidController, 'Network Name (SSID)', Icons.wifi),
            const SizedBox(height: 10),
            _buildField(_wifiPasswordController, 'Password', Icons.lock, isPassword: true),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _wifiType,
              decoration: InputDecoration(
                labelText: 'Security Type',
                prefixIcon: const Icon(Icons.security),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ['WPA', 'WEP', 'nopass']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _wifiType = v!),
            ),
          ],
        );

      case 'Location':
        return Column(
          children: [
            _buildField(_latController, 'Latitude (e.g. 23.8103)', Icons.location_on, type: TextInputType.number),
            const SizedBox(height: 10),
            _buildField(_lngController, 'Longitude (e.g. 90.4125)', Icons.location_on, type: TextInputType.number),
          ],
        );

      case 'Contact':
        return Column(
          children: [
            _buildField(_contactNameController, 'Full Name', Icons.person),
            const SizedBox(height: 10),
            _buildField(_contactPhoneController, 'Phone Number', Icons.phone, type: TextInputType.phone),
            const SizedBox(height: 10),
            _buildField(_contactEmailController, 'Email (optional)', Icons.email, type: TextInputType.emailAddress),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType type = TextInputType.text,
        int maxLines = 1,
        bool isPassword = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _smsPhoneController.dispose();
    _smsMessageController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Generate QR Code',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // QR Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (qrData.isNotEmpty)
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: QrImageView(
                            data: qrData,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'QR will appear here',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    if (qrData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isSaving
                              ? const CircularProgressIndicator()
                              : TextButton.icon(
                            onPressed: _saveQRCode,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Save'),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: _shareQRCode,
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Type Selector
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    final isSelected = selectedType == type['label'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = type['label'];
                          qrData = '';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Dynamic Input Fields
              _buildInputFields(),

              const SizedBox(height: 16),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generateQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text(
                    'Generate QR Code',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}