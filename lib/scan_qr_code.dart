import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'history_service.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({Key? key}) : super(key: key);

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  String qrResult = '';
  bool isScanned = false;
  bool isLoading = false;

  // ✅ Camera দিয়ে scan
  Future<void> scanQR() async {
    setState(() => isLoading = true);

    try {
      String? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SimpleBarcodeScannerPage(),
        ),
      );

      if (!mounted) return;

      if (result != null && result != '-1' && result.isNotEmpty) {
        _handleResult(result);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to scan QR code');
    }
  }

  // ✅ Gallery থেকে image scan
  Future<void> scanFromGallery() async {
    setState(() => isLoading = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        setState(() => isLoading = false);
        return;
      }

      // ML Kit দিয়ে QR scan
      final inputImage = InputImage.fromFilePath(image.path);
      final barcodeScanner = BarcodeScanner(
        formats: [BarcodeFormat.qrCode, BarcodeFormat.all],
      );

      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (!mounted) return;

      if (barcodes.isNotEmpty) {
        final result = barcodes.first.rawValue ?? '';
        if (result.isNotEmpty) {
          _handleResult(result);
        } else {
          setState(() => isLoading = false);
          _showErrorSnackBar('No QR code found in image');
        }
      } else {
        setState(() => isLoading = false);
        _showErrorSnackBar('No QR code found in image');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to scan image');
    }
  }

  // ✅ Result handle করা
  void _handleResult(String result) async {
    setState(() {
      qrResult = result;
      isScanned = true;
      isLoading = false;
    });

    await HistoryService.saveToHistory(result);

    if (result.startsWith('http://') || result.startsWith('https://')) {
      _showUrlDialog(result);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
      if (!launched && mounted) {
        _showErrorSnackBar('Could not open URL');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Invalid URL');
    }
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('URL Detected'),
          ],
        ),
        content: Text(
          url,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(url);
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: qrResult));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ✅ Camera/Gallery choice dialog
  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Scan Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Camera option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                scanQR();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF2196F3),
                ),
              ),
              title: const Text(
                'Use Camera',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Scan QR code with camera'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const Divider(),

            // Gallery option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                scanFromGallery();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF4CAF50),
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Pick an image with QR code'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2196F3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result Card
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
                    Icon(
                      isScanned ? Icons.check_circle : Icons.qr_code_scanner,
                      size: 60,
                      color: isScanned
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isScanned ? 'Scan Result' : 'Ready to Scan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // URL হলে clickable
                    if (isScanned &&
                        (qrResult.startsWith('http://') ||
                            qrResult.startsWith('https://')))
                      GestureDetector(
                        onTap: () => _showUrlDialog(qrResult),
                        child: Text(
                          qrResult,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2196F3),
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Text(
                        isScanned ? qrResult : 'Tap the button below to scan',
                        style: TextStyle(
                          fontSize: 14,
                          color: isScanned ? Colors.black87 : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),

                    if (isScanned) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Scan Button - click করলে bottom sheet আসবে
              isLoading
                  ? const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Scanning...'),
                ],
              )
                  : SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showScanOptions, // ✅ bottom sheet খুলবে
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(
                    isScanned ? 'Scan Again' : 'Scan QR Code',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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