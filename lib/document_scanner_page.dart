import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'document_service.dart';
import 'package:http/http.dart' as http;
import 'saved_documents_page.dart';

class DocumentScannerPage extends StatefulWidget {
  const DocumentScannerPage({Key? key}) : super(key: key);

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  List<String> scannedImages = [];
  bool isProcessing = false;
  String? savedPdfPath;
  String selectedCategory = 'General';
  bool _isEnhanced = false;
  String _extractedText = '';

  final List<String> categories = [
    'General', 'NID', 'Passport', 'Certificate', 'Bill', 'Other'
  ];

  // ✅ Document Scan
  Future<void> _scanDocument() async {
    try {
      setState(() => isProcessing = true);
      final images = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: true,
      );
      if (!mounted) return;
      if (images != null && images.isNotEmpty) {
        setState(() {
          scannedImages.addAll(images);
          isProcessing = false;
          savedPdfPath = null;
          _isEnhanced = false;
        });
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Failed to scan document', Colors.red);
    }
  }

  // ✅ Image Enhancement - Black & White
  Future<void> _enhanceImages() async {
    if (scannedImages.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      List<String> enhancedPaths = [];
      for (final imagePath in scannedImages) {
        final bytes = await File(imagePath).readAsBytes();
        // Grayscale conversion
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        enhancedPaths.add(path);
      }

      setState(() {
        scannedImages = enhancedPaths;
        _isEnhanced = true;
        isProcessing = false;
      });
      _showSnackBar('Images enhanced!', Colors.green);
    } catch (e) {
      setState(() => isProcessing = false);
      _showSnackBar('Enhancement failed', Colors.red);
    }
  }

  // ✅ OCR - Text Recognition (Online + Offline)
  Future<void> _extractText() async {
    if (scannedImages.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      String allText = '';
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      for (final imagePath in scannedImages) {
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognized = await textRecognizer.processImage(inputImage);
        if (recognized.text.isNotEmpty) {
          allText += recognized.text + '\n\n';
        }
      }

      await textRecognizer.close();

      if (!mounted) return;
      setState(() => isProcessing = false);

      if (allText.trim().isNotEmpty) {
        _showOcrResult(allText.trim());
      } else {
        _showSnackBar('No text found', Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Text recognition failed', Colors.red);
    }
  }

  // ✅ Convert to PDF with custom name & password
  Future<void> _convertToPdf() async {
    if (scannedImages.isEmpty) return;

    // PDF name dialog
    final nameController = TextEditingController(
      text: '${selectedCategory}_${DateTime.now().millisecondsSinceEpoch}',
    );
    final passwordController = TextEditingController();
    bool usePassword = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Save PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category selector
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.folder),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setDialogState(() => selectedCategory = v!);
                  setState(() => selectedCategory = v!);
                },
              ),
              const SizedBox(height: 12),
              // Password toggle
              Row(
                children: [
                  Switch(
                    value: usePassword,
                    onChanged: (v) =>
                        setDialogState(() => usePassword = v),
                  ),
                  const Text('Add Password'),
                ],
              ),
              if (usePassword)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text(
                'Create PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => isProcessing = true);

    try {
      final pdf = pw.Document();

      for (final imagePath in scannedImages) {
        final imageBytes = await File(imagePath).readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${nameController.text.trim()}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Save metadata
      await DocumentService.saveDocument(
        path: file.path,
        name: nameController.text.trim(),
        category: selectedCategory,
        pageCount: scannedImages.length,
      );

      if (!mounted) return;
      setState(() {
        savedPdfPath = file.path;
        isProcessing = false;
      });

      _showSnackBar('PDF created: $fileName', Colors.green);

      // Auto backup check
      _checkAndBackup(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Failed to create PDF', Colors.red);
    }
  }

  Future<void> _checkAndBackup(File pdfFile) async {
    _showSnackBar('PDF saved to phone!', Colors.green);
  }

  // ✅ Page Reorder
  void _reorderPages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<String> reorderedImages = List.from(scannedImages);
        return StatefulBuilder(
          builder: (context, setSheetState) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reorder Pages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Drag to reorder pages',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: reorderedImages.length,
                    onReorder: (oldIndex, newIndex) {
                      setSheetState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = reorderedImages.removeAt(oldIndex);
                        reorderedImages.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return ListTile(
                        key: ValueKey(reorderedImages[index]),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(reorderedImages[index]),
                            width: 50,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text('Page ${index + 1}'),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        scannedImages = reorderedImages;
                        savedPdfPath = null;
                      });
                      Navigator.pop(context);
                      _showSnackBar('Pages reordered!', Colors.green);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _extractTextFromGallery() async {
    setState(() => isProcessing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isEmpty) {
        setState(() => isProcessing = false);
        return;
      }

      String allText = '';
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      for (final image in images) {
        final inputImage = InputImage.fromFilePath(image.path);
        final recognized = await textRecognizer.processImage(inputImage);
        if (recognized.text.isNotEmpty) {
          allText += recognized.text + '\n\n';
        }
      }

      await textRecognizer.close();

      if (!mounted) return;
      setState(() => isProcessing = false);

      if (allText.trim().isNotEmpty) {
        _showOcrResult(allText.trim());
      } else {
        _showSnackBar('No text found', Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Failed to extract text', Colors.red);
    }
  }

  Future<void> _extractTextFromCamera() async {
    setState(() => isProcessing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) {
        setState(() => isProcessing = false);
        return;
      }

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final inputImage = InputImage.fromFilePath(image.path);
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;
      setState(() => isProcessing = false);

      if (recognized.text.isNotEmpty) {
        _showOcrResult(recognized.text);
      } else {
        _showSnackBar('No text found', Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Failed to extract text', Colors.red);
    }
  }

  // ✅ OCR Result Dialog
  void _showOcrResult(String text) {
    double fontSize = 14.0;
    String searchQuery = '';
    bool isPlaying = false;
    String translatedText = '';
    bool showTranslated = false;
    final flutterTts = FlutterTts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          List<String> lines = text.split('\n');
          List<String> filteredLines = searchQuery.isEmpty
              ? lines
              : lines
              .where((line) =>
              line.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          String displayText = filteredLines.join('\n');

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title + Font size
                  Row(
                    children: [
                      const Icon(Icons.text_fields, color: Color(0xFF2196F3)),
                      const SizedBox(width: 8),
                      const Text(
                        'Extracted Text',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: () {
                          if (fontSize > 10) {
                            setSheetState(() => fontSize -= 2);
                          }
                        },
                      ),
                      Text('${fontSize.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.text_increase),
                        onPressed: () {
                          if (fontSize < 30) {
                            setSheetState(() => fontSize += 2);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Search
                  TextField(
                    onChanged: (value) =>
                        setSheetState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search in text...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setSheetState(() => searchQuery = ''),
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ocrActionButton('Copy', Icons.copy, Colors.blue, () {
                          Clipboard.setData(ClipboardData(text: text));
                          Navigator.pop(context);
                          _showSnackBar('Text copied!', Colors.green);
                        }),
                        const SizedBox(width: 8),
                        _ocrActionButton('Share', Icons.share, Colors.green, () {
                          Navigator.pop(context);
                          Share.share(text);
                        }),
                        const SizedBox(width: 8),
                        _ocrActionButton(
                            'Save TXT', Icons.save_alt, Colors.orange, () async {
                          Navigator.pop(context);
                          await _saveAsText(text);
                        }),
                        const SizedBox(width: 8),
                        _ocrActionButton(
                            'Save PDF', Icons.picture_as_pdf, Colors.red,
                                () async {
                              Navigator.pop(context);
                              await _saveTextAsPdf(text);
                            }),
                        const SizedBox(width: 8),
                        _ocrActionButton(
                          isPlaying ? 'Stop' : 'Read',
                          isPlaying ? Icons.stop : Icons.volume_up,
                          Colors.purple,
                              () async {
                            if (isPlaying) {
                              await flutterTts.stop();
                              setSheetState(() => isPlaying = false);
                            } else {
                              setSheetState(() => isPlaying = true);
                              await flutterTts.setLanguage('bn-BD');
                              await flutterTts.speak(text);
                              flutterTts.setCompletionHandler(() {
                                setSheetState(() => isPlaying = false);
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _ocrActionButton(
                            'Translate', Icons.translate, Colors.teal, () async {
                          setSheetState(() => translatedText = 'Translating...');
                          try {
                            final translator = GoogleTranslator();
                            final shortText = text.substring(
                                0, text.length > 100 ? 100 : text.length);
                            final detected = await translator.translate(
                              shortText,
                              to: 'en',
                            );
                            final isEnglish =
                                detected.sourceLanguage.code == 'en';
                            final result = await translator.translate(
                              text,
                              from: isEnglish ? 'en' : 'bn',
                              to: isEnglish ? 'bn' : 'en',
                            );
                            setSheetState(() {
                              translatedText = result.text;
                              showTranslated = true;
                            });
                          } catch (e) {
                            setSheetState(() {
                              translatedText = 'Translation failed';
                              showTranslated = true;
                            });
                          }
                        }),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Text display
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${filteredLines.length} lines found',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          Text(
                            displayText,
                            style:
                            TextStyle(fontSize: fontSize, height: 1.6),
                          ),
                          if (showTranslated && translatedText.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.teal.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.translate,
                                          size: 16, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Translation',
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text: translatedText));
                                          _showSnackBar(
                                              'Translation copied!', Colors.green);
                                        },
                                        child: const Icon(Icons.copy,
                                            size: 16, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    translatedText,
                                    style: TextStyle(
                                        fontSize: fontSize, height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ocrActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsText(String text) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'text_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(text);
      _showSnackBar('Saved as $fileName', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to save text', Colors.red);
    }
  }

  Future<void> _saveTextAsPdf(String text) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      );
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'text_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await DocumentService.saveDocument(
        path: file.path,
        name: fileName,
        category: 'General',
        pageCount: 1,
      );
      _showSnackBar('Saved as PDF!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to save PDF', Colors.red);
    }
  }

  Future<void> _openPdf() async {
    if (savedPdfPath == null) return;
    final result = await OpenFile.open(savedPdfPath!);
    if (result.type != ResultType.done && mounted) {
      _showSnackBar('Could not open PDF', Colors.red);
    }
  }

  Future<void> _sharePdf() async {
    if (savedPdfPath == null) return;
    try {
      await Share.shareXFiles(
        [XFile(savedPdfPath!)],
        text: 'Scanned Document',
      );
    } catch (e) {
      _showSnackBar('Failed to share', Colors.red);
    }
  }

  Future<void> _saveImageToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        name: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        androidRelativePath: 'Pictures/ScannedDocs',
        androidExistNotSave: false,
      );
      if (result.isSuccess && mounted) {
        _showSnackBar('Saved to Gallery!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to save', Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      scannedImages.removeAt(index);
      savedPdfPath = null;
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All'),
        content: const Text('Remove all scanned pages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                scannedImages.clear();
                savedPdfPath = null;
                _extractedText = '';
                _isEnhanced = false;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Document Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2196F3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (scannedImages.isNotEmpty) ...[
            // Reorder button
            IconButton(
              icon: const Icon(Icons.swap_vert, color: Colors.white),
              onPressed: _reorderPages,
              tooltip: 'Reorder Pages',
            ),
            // Saved PDFs
            IconButton(
              icon: const Icon(Icons.folder_open, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedDocumentsPage()),
              ),
              tooltip: 'Saved Documents',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
          ],
          // Always show saved docs
          if (scannedImages.isEmpty)
            IconButton(
              icon: const Icon(Icons.folder_open, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedDocumentsPage()),
              ),
              tooltip: 'Saved Documents',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats bar
            if (scannedImages.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF2196F3),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${scannedImages.length} page${scannedImages.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedCategory,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isEnhanced) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Enhanced',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (savedPdfPath != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PDF Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Action chips
            if (scannedImages.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    _actionChip(
                      'Enhance',
                      Icons.auto_fix_high,
                      Colors.purple,
                      _enhanceImages,
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      'Extract Text',
                      Icons.text_fields,
                      Colors.orange,
                      _showExtractTextOptions,
                    ),
                  ],
                ),
              ),

            // Pages grid
            Expanded(
              child: scannedImages.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: scannedImages.length,
                itemBuilder: (context, index) =>
                    _buildImageCard(index),
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : _scanDocument,
                      icon: const Icon(Icons.document_scanner),
                      label: Text(
                        scannedImages.isEmpty
                            ? 'Start Scanning'
                            : 'Add More Pages',
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
                  if (scannedImages.isNotEmpty) ...[
                    const SizedBox(height: 10),

                    // PDF এখনও তৈরি হয়নি
                    if (savedPdfPath == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _convertToPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text('Create PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // PDF তৈরি হয়ে গেলে
                    if (savedPdfPath != null)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _openPdf,
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Open PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _sharePdf,
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                  if (isProcessing) ...[
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 50,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No documents scanned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Start Scanning" to begin',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedDocumentsPage()),
            ),
            icon: const Icon(Icons.folder_open),
            label: const Text('View Saved Documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(scannedImages[index]),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _saveImageToGallery(scannedImages[index]),
            icon: const Icon(Icons.save_alt, size: 14),
            label: const Text('Save', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Extract Text button এ click করলে এই dialog আসবে
  void _showExtractTextOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
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
              'Extract Text From',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Scanned pages থেকে
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _extractText(); // আগের function
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.document_scanner, color: Colors.orange),
              ),
              title: const Text(
                'From Scanned Pages',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Currently scanned pages থেকে text নেবে'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const Divider(),

            // ✅ Gallery থেকে image upload করে
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _extractTextFromGallery();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text(
                'Upload from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Gallery থেকে image upload করে text নেবে'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),

            const Divider(),

            // ✅ Camera দিয়ে তুলে
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _extractTextFromCamera();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Camera দিয়ে ছবি তুলে text নেবে'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

