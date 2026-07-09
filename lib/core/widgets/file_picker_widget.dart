import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logger/index.dart';
import '../services/file_upload_service.dart';
import '../theme/app_colors.dart';

typedef OnFilePicked = void Function(XFile file);
typedef OnFileRemoved = void Function();

class FilePickerWidget extends StatefulWidget {
  final String label;
  final String? hint;
  final OnFilePicked onFilePicked;
  final OnFileRemoved? onFileRemoved;
  final double maxFileSizeMB;
  final bool allowCamera;
  final bool allowGallery;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedFileName;

  const FilePickerWidget({
    Key? key,
    required this.label,
    this.hint,
    required this.onFilePicked,
    this.onFileRemoved,
    this.maxFileSizeMB = 10,
    this.allowCamera = true,
    this.allowGallery = true,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFileName,
  }) : super(key: key);

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  XFile? _selectedFile;
  // Cached because XFile.length() is async (web has no sync file IO)
  double? _selectedFileSizeMB;
  final _fileUploadService = FileUploadService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _fileUploadService.pickImage(source: source);
      if (file != null) {
        final sizeMB = await _fileUploadService.getFileSizeInMB(file);

        // Validate file size
        if (sizeMB > widget.maxFileSizeMB) {
          log.w('File too large: ${sizeMB}MB');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File too large. Max: ${widget.maxFileSizeMB}MB',
                ),
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _selectedFileSizeMB = sizeMB;
        });
        widget.onFilePicked(file);
        log.d('File picked: ${file.name} (${sizeMB}MB)');
      }
    } catch (e) {
      log.e('Error picking file', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileSizeMB = null;
    });
    widget.onFileRemoved?.call();
    log.d('File removed');
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select File',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (widget.allowCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            if (widget.allowGallery)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            if (_selectedFile != null || widget.selectedFileName != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove File', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeFile();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getFileName() {
    if (_selectedFile != null) {
      return _fileUploadService.getFileName(_selectedFile!);
    }
    return widget.selectedFileName ?? 'No file selected';
  }

  String _getFileSizeText() {
    if (_selectedFileSizeMB == null) return '';
    return '(${_selectedFileSizeMB!.toStringAsFixed(2)}MB)';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = _selectedFile != null || widget.selectedFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.isLoading ? null : _showPickerMenu,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorMessage != null ? colors.error : colors.divider,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? colors.primary.withOpacity(0.05) : colors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected ? colors.textPrimary : colors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_getFileSizeText().isNotEmpty)
                        Text(
                          _getFileSizeText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  )
                else
                  Icon(
                    isSelected ? Icons.check_circle : Icons.cloud_upload,
                    color: isSelected ? colors.success : colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorMessage!,
            style: TextStyle(color: colors.error, fontSize: 12),
          ),
        ] else if (widget.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
