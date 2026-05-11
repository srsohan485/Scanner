import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saver_gallery/saver_gallery.dart';

class DocumentScannerPage extends StatefulWidget {
  const DocumentScannerPage({Key? key}) : super(key: key);

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  List<String> scannedImages = [];
  bool isProcessing = false;
  String? savedPdfPath;

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

  Future<void> _convertToPdf() async {
    if (scannedImages.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      final pdf = pw.Document();

      for (final imagePath in scannedImages) {
        final imageFile = File(imagePath);
        final imageBytes = await imageFile.readAsBytes();
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
      final fileName =
          'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      setState(() {
        savedPdfPath = file.path;
        isProcessing = false;
      });

      _showSnackBar('PDF created successfully!', Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar('Failed to create PDF', Colors.red);
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
      _showSnackBar('Failed to share PDF', Colors.red);
    }
  }

  Future<void> _saveToGallery(String imagePath) async {
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
        _showSnackBar('Image saved to Gallery!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to save image', Colors.red);
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
          if (scannedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Top Stats Bar
            if (scannedImages.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    Text(
                      '${scannedImages.length} page${scannedImages.length > 1 ? 's' : ''} scanned',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (savedPdfPath != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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

            // ✅ Scanned Pages Grid
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
                  childAspectRatio: 0.75,
                ),
                itemCount: scannedImages.length,
                itemBuilder: (context, index) {
                  return _buildImageCard(index);
                },
              ),
            ),

            // ✅ Bottom Action Buttons
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
                children: [
                  // Scan Button
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

                  // PDF Actions
                  if (scannedImages.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Convert to PDF
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: isProcessing ? null : _convertToPdf,
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
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

                          if (savedPdfPath != null) ...[
                            const SizedBox(width: 8),
                            // Open PDF
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _openPdf,
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Open'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Share PDF
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _sharePdf,
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Loading indicator
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
            'Tap "Start Scanning" to scan\nyour first document',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          // Page number badge
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
                // Delete button
                GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Image.file(
                File(scannedImages[index]),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          // Save to gallery button
          TextButton.icon(
            onPressed: () => _saveToGallery(scannedImages[index]),
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
}