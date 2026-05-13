import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'history_service.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({Key? key}) : super(key: key);

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  String qrResult = '';
  String qrType = '';
  bool isScanned = false;
  bool isLoading = false;

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

  Future<void> scanFromGallery() async {
    setState(() => isLoading = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => isLoading = false);
        return;
      }
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

  void _handleResult(String result) async {
    final type = _detectType(result);
    setState(() {
      qrResult = result;
      qrType = type;
      isScanned = true;
      isLoading = false;
    });
    await HistoryService.saveToHistory(result);
    _showActionDialog(result, type);
  }

  // ✅ QR Type detect করা
  String _detectType(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return 'url';
    } else if (value.startsWith('tel:') || RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value) || value.startsWith('00880') || value.startsWith('+880')) {
      return 'phone';
    } else if (value.startsWith('mailto:') || RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(value)) {
      return 'email';
    } else if (value.startsWith('smsto:') || value.startsWith('sms:')) {
      return 'sms';
    } else if (value.startsWith('WIFI:')) {
      return 'wifi';
    } else if (value.startsWith('geo:')) {
      return 'location';
    } else if (value.startsWith('BEGIN:VCARD')) {
      return 'contact';
    } else {
      return 'text';
    }
  }

  // ✅ Type অনুযায়ী Action Dialog
  void _showActionDialog(String value, String type) {
    IconData icon;
    Color color;
    String title;
    List<Widget> actions;

    switch (type) {
      case 'url':
        icon = Icons.link;
        color = const Color(0xFF2196F3);
        title = 'URL Detected';
        actions = [
          _dialogButton('Open Browser', Icons.open_in_browser, color, () {
            Navigator.pop(context);
            _launchUrl(value);
          }),
        ];
        break;

      case 'phone':
        icon = Icons.phone;
        color = const Color(0xFF4CAF50);
        title = 'Phone Number';
        final number = value.replaceAll('tel:', '');
        actions = [
          _dialogButton('Call', Icons.call, color, () {
            Navigator.pop(context);
            _launchUrl('Tel:$number');
          }),SizedBox(height: 10,),
          _dialogButton('SMS', Icons.sms, Colors.orange, () {
            Navigator.pop(context);
            _launchUrl('sms:$number');
          }),SizedBox(height: 10,),
          // ✅ bKash এর বদলে Payment button
          _dialogButton('Payment', Icons.payment, const Color(0xFF2196F3), () {
            Navigator.pop(context);
            _showPaymentDialog(number); // ✅ Payment dialog খুলবে
          }),
        ];
        break;

      case 'email':
        icon = Icons.email;
        color = Colors.orange;
        title = 'Email Detected';
        final email = value.replaceAll('mailto:', '');
        actions = [
          _dialogButton('Send Email', Icons.send, color, () {
            Navigator.pop(context);
            _launchUrl('mailto:$email');
          }),
        ];
        break;

      case 'sms':
        icon = Icons.sms;
        color = Colors.purple;
        title = 'SMS Detected';
        actions = [
          _dialogButton('Send SMS', Icons.sms, color, () {
            Navigator.pop(context);
            _launchUrl(value);
          }),
        ];
        break;

      case 'wifi':
        icon = Icons.wifi;
        color = const Color(0xFF2196F3);
        title = 'WiFi QR Code';
        final wifiInfo = _parseWifi(value);
        actions = [
          // ✅ Connect
          _dialogButton('Connect', Icons.wifi, color, () {
            Navigator.pop(context);
            _connectToWifi(
              wifiInfo['ssid'] ?? '',
              wifiInfo['password'] ?? '',
              wifiInfo['type'] ?? 'WPA',
            );
          }),
          // ✅ Copy Password
          _dialogButton('Copy Password', Icons.copy, Colors.grey, () {
            Navigator.pop(context);
            Clipboard.setData(
              ClipboardData(text: wifiInfo['password'] ?? ''),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password copied!'),
                backgroundColor: Colors.green,
              ),
            );
          }),
          // ✅ Share WiFi info
          _dialogButton('Share', Icons.share, Colors.green, () {
            Navigator.pop(context);
            _shareWifiInfo(
              wifiInfo['ssid'] ?? '',
              wifiInfo['password'] ?? '',
              wifiInfo['type'] ?? 'WPA',
            );
          }),
          // ✅ Forget WiFi
          _dialogButton('Forget', Icons.wifi_off, Colors.red, () {
            Navigator.pop(context);
            _forgetWifi(wifiInfo['ssid'] ?? '');
          }),
        ];
        break;

      case 'location':
        icon = Icons.location_on;
        color = Colors.red;
        title = 'Location Detected';
        actions = [
          _dialogButton('Open Maps', Icons.map, color, () {
            Navigator.pop(context);
            final coords = value.replaceAll('geo:', '').split(',');
            _launchUrl(
              'https://www.google.com/maps?q=${coords[0]},${coords[1]}',
            );
          }),
        ];
        break;

      case 'contact':
        icon = Icons.contact_page;
        color = Colors.teal;
        title = 'Contact Detected';
        actions = [
          _dialogButton('Copy Info', Icons.copy, color, () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact info copied!')),
            );
          }),
        ];
        break;

      default:
        icon = Icons.text_fields;
        color = Colors.grey;
        title = 'Text Detected';
        actions = [
          _dialogButton('Copy', Icons.copy, color, () {
            Navigator.pop(context);
            _copyToClipboard();
          }),
        ];
    }

    // WiFi হলে extra info দেখাবে
    String displayValue = value;
    if (type == 'wifi') {
      final info = _parseWifi(value);
      displayValue =
      'Network: ${info['ssid']}\nPassword: ${info['password']}\nType: ${info['type']}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(
          displayValue,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _dialogButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Map<String, String> _parseWifi(String value) {
    final ssid = RegExp(r'S:([^;]+)').firstMatch(value)?.group(1) ?? '';
    final password = RegExp(r'P:([^;]+)').firstMatch(value)?.group(1) ?? '';
    final type = RegExp(r'T:([^;]+)').firstMatch(value)?.group(1) ?? '';
    return {'ssid': ssid, 'password': password, 'type': type};
  }

  Future<void> _connectToWifi(String ssid, String password, String type) async {
    try {
      // ✅ Android 10+ এ এভাবে connect করতে হবে
      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: type == 'WPA'
            ? NetworkSecurity.WPA
            : type == 'WEP'
            ? NetworkSecurity.WEP
            : NetworkSecurity.NONE,
        joinOnce: false,      // ✅ false করুন
        withInternet: true,   // ✅ internet সহ connect করবে
      );

      if (!mounted) return;

      if (connected) {
        // ✅ Force করে সেই WiFi তে bind করবে
        await WiFiForIoTPlugin.forceWifiUsage(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to $ssid!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ✅ Connect না হলে Settings এ নিয়ে যাবে
        _showWifiSettingsDialog(ssid, password);
      }
    } catch (e) {
      if (!mounted) return;
      // ✅ Error হলেও Settings এ নিয়ে যাবে
      _showWifiSettingsDialog(ssid, password);
    }
  }
  // ✅ WiFi Forget করা
  Future<void> _forgetWifi(String ssid) async {
    try {
      await WiFiForIoTPlugin.disconnect();
      await WiFiForIoTPlugin.removeWifiNetwork(ssid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ssid removed!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // ✅ কাজ না করলে Settings এ নিয়ে যাবে
      launchUrl(
        Uri.parse('android.settings.WIFI_SETTINGS'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

// ✅ WiFi Share করা
  void _shareWifiInfo(String ssid, String password, String type) {
    Share.share(
      'WiFi Network: $ssid\nPassword: $password\nSecurity: $type',
      subject: 'WiFi Password for $ssid',
    );
  }

// ✅ WiFi Settings dialog
  void _showWifiSettingsDialog(String ssid, String password) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Connect to WiFi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not connect automatically.\nPlease connect manually:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text(
                        'Network: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        ssid,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text(
                        'Password: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        password,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // ✅ Password copy
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password copied!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Password'),
          ),
          // ✅ WiFi Settings এ যাবে
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              WiFiForIoTPlugin.disconnect();
              launchUrl(
                Uri.parse('android.settings.WIFI_SETTINGS'),
                mode: LaunchMode.externalApplication,
              ).catchError((_) {
                launchUrl(
                  Uri.parse('app-settings:'),
                  mode: LaunchMode.externalApplication,
                );
              });
            },
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open WiFi Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showErrorSnackBar('Could not open');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Invalid data');
    }
  }

  void _showPaymentDialog(String number) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose payment method:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          // ✅ bKash
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse('bkash://pay?number=$number'),
                mode: LaunchMode.externalApplication,
              ).catchError((_) {
                launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.bKash.customerapp',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              });
            },
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('bKash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2136E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),SizedBox(height: 10,),
          // ✅ Nagad
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse('nagad://pay?number=$number'),
                mode: LaunchMode.externalApplication,
              ).catchError((_) {
                launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.nagad.mobilebanking',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              });
            },
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Nagad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ✅ Type অনুযায়ী Icon ও Color
  IconData _getTypeIcon() {
    switch (qrType) {
      case 'url': return Icons.link;
      case 'phone': return Icons.phone;
      case 'email': return Icons.email;
      case 'sms': return Icons.sms;
      case 'wifi': return Icons.wifi;
      case 'location': return Icons.location_on;
      case 'contact': return Icons.contact_page;
      default: return Icons.text_fields;
    }
  }

  Color _getTypeColor() {
    switch (qrType) {
      case 'url': return const Color(0xFF2196F3);
      case 'phone': return const Color(0xFF4CAF50);
      case 'email': return Colors.orange;
      case 'sms': return Colors.purple;
      case 'wifi': return const Color(0xFF2196F3);
      case 'location': return Colors.red;
      case 'contact': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (qrType) {
      case 'url': return 'URL';
      case 'phone': return 'Phone Number';
      case 'email': return 'Email';
      case 'sms': return 'SMS';
      case 'wifi': return 'WiFi';
      case 'location': return 'Location';
      case 'contact': return 'Contact';
      default: return 'Text';
    }
  }

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                child: const Icon(Icons.camera_alt, color: Color(0xFF2196F3)),
              ),
              title: const Text(
                'Use Camera',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Scan QR code with camera'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
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
                      isScanned ? _getTypeIcon() : Icons.qr_code_scanner,
                      size: 60,
                      color: isScanned
                          ? _getTypeColor()
                          : const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 16),
                    // ✅ Type label দেখাবে
                    if (isScanned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            color: _getTypeColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      isScanned ? 'Scan Result' : 'Ready to Scan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isScanned ? qrResult : 'Tap the button below to scan',
                      style: TextStyle(
                        fontSize: 14,
                        color: isScanned ? Colors.black87 : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isScanned) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _showActionDialog(qrResult, qrType),
                            icon: Icon(
                              _getTypeIcon(),
                              size: 16,
                              color: _getTypeColor(),
                            ),
                            label: Text(
                              'Action',
                              style: TextStyle(color: _getTypeColor()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                  onPressed: _showScanOptions,
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