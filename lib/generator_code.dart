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
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _qrKey = GlobalKey(); // ✅ RepaintBoundary key
  String qrData = '';
  bool isSaving = false;

  void _generateQR() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text or URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => qrData = text);
    FocusScope.of(context).unfocus();
  }

  // ✅ RepaintBoundary দিয়ে image capture
  Future<File?> _captureQRImage() async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
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
        text: 'QR Code for: $qrData',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share QR Code')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
              // QR Code Display
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
                    // ✅ RepaintBoundary দিয়ে wrap করা
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
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
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

                    // Save & Share buttons
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

              // Input Field
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter text, URL, or any data...',
                  labelText: 'QR Code Data',
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
                    borderSide: const BorderSide(
                      color: Color(0xFF4CAF50),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),

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