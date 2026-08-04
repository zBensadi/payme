import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/storage/app_paths.dart';
import 'package:path/path.dart' as p;

class LogoPicker extends StatefulWidget {
  final String? initialLogoPath;
  final ValueChanged<String?> onLogoSelected;

  const LogoPicker({
    super.key,
    this.initialLogoPath,
    required this.onLogoSelected,
  });

  @override
  State<LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends State<LogoPicker> {
  String? _currentLogoPath;
  String? _newSourcePath;
  
  @override
  void initState() {
    super.initState();
    _currentLogoPath = widget.initialLogoPath;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _newSourcePath = path;
        });
        widget.onLogoSelected(path);
      }
    }
  }

  Future<File?> _resolveStoredLogo() async {
    if (_currentLogoPath == null) return null;
    final logosDir = await AppPaths.getLogosPath();
    final file = File(p.join(logosDir, _currentLogoPath));
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Logo', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildImagePreview(),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Logo'),
              onPressed: _pickImage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_newSourcePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(_newSourcePath!), fit: BoxFit.cover),
      );
    }
    
    if (_currentLogoPath != null) {
      return FutureBuilder<File?>(
        future: _resolveStoredLogo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(snapshot.data!, fit: BoxFit.cover),
            );
          }
          return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    }
    
    return const Center(child: Icon(Icons.image, color: Colors.grey));
  }
}
