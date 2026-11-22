import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const JpegCompressorApp());
}

class JpegCompressorApp extends StatelessWidget {
  const JpegCompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JPEG Compressor',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const CompressorHome(),
    );
  }
}

class CompressorHome extends StatefulWidget {
  const CompressorHome({super.key});

  @override
  State<CompressorHome> createState() => _CompressorHomeState();
}

class _CompressorHomeState extends State<CompressorHome> {
  Uint8List? originalBytes;
  Uint8List? compressedBytes;
  String? savedPath;

  int quality = 70;
  bool isCompressing = false;

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        originalBytes = bytes;
        compressedBytes = null;
        savedPath = null;
      });
    } catch (e) {
      showMessage('Could not select image: $e');
    }
  }

  Future<void> compressImage() async {
    if (originalBytes == null) return;

    setState(() {
      isCompressing = true;
      savedPath = null;
    });

    try {
      final decoded = img.decodeImage(originalBytes!);

      if (decoded == null) {
        throw Exception('Unsupported or invalid image.');
      }

      final encoded = img.encodeJpg(
        decoded,
        quality: quality,
      );

      setState(() {
        compressedBytes = Uint8List.fromList(encoded);
        isCompressing = false;
      });
    } catch (e) {
      setState(() => isCompressing = false);
      showMessage('Compression failed: $e');
    }
  }

  Future<void> saveImage() async {
    if (compressedBytes == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(compressedBytes!);

      setState(() {
        savedPath = file.path;
      });

      showMessage('Image saved successfully!');
    } catch (e) {
      showMessage('Could not save image: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget imagePreview(Uint8List bytes, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            bytes,
            height: 190,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text('File size: ${formatSize(bytes.length)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduction = originalBytes != null && compressedBytes != null
        ? ((1 - compressedBytes!.length / originalBytes!.length) * 100)
            .toStringAsFixed(1)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JPEG Compressor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 65,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            const Text(
              'Compress Images Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Reduce image size while keeping good quality.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),

            FilledButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Image'),
            ),

            const SizedBox(height: 22),

            if (originalBytes != null) ...[
              imagePreview(originalBytes!, 'Original Image'),
              const SizedBox(height: 20),

              const Text(
                'Compression Quality',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              Slider(
                value: quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                label: '$quality%',
                onChanged: (value) {
                  setState(() {
                    quality = value.round();
                  });
                },
              ),

              Text(
                'Quality: $quality%',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: isCompressing ? null : compressImage,
                icon: const Icon(Icons.compress),
                label: Text(
                  isCompressing ? 'Compressing...' : 'Compress Image',
                ),
              ),

              if (compressedBytes != null) ...[
                const SizedBox(height: 25),
                imagePreview(compressedBytes!, 'Compressed Image'),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Size Reduction',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$reduction%',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                FilledButton.icon(
                  onPressed: saveImage,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Compressed Image'),
                ),

                if (savedPath != null)
                  SelectableText(
                    'Saved at: $savedPath',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}