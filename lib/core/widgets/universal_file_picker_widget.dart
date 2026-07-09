import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logger/index.dart';
import '../services/file_upload_service.dart';
import '../theme/app_colors.dart';

enum FilePickerType {
  image,      // Camera + Gallery (images only)
  video,      // Camera + Gallery (videos only)
  document,   // File picker (PDF, DOC, XLS, etc)
  all,        // File picker (all file types)
  mixed,      // Camera/Gallery + File picker
}

typedef OnFilePicked = void Function(XFile file);
typedef OnFileRemoved = void Function();

class UniversalFilePickerWidget extends StatefulWidget {
  final String label;
  final String? hint;
  final OnFilePicked onFilePicked;
  final OnFileRemoved? onFileRemoved;
  final FilePickerType pickerType;
  final double maxFileSizeMB;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedFileName;
  final List<String>? customAllowedExtensions;

  const UniversalFilePickerWidget({
    Key? key,
    required this.label,
    this.hint,
    required this.onFilePicked,
    this.onFileRemoved,
    this.pickerType = FilePickerType.mixed,
    this.maxFileSizeMB = 100,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFileName,
    this.customAllowedExtensions,
  }) : super(key: key);

  @override
  State<UniversalFilePickerWidget> createState() => _UniversalFilePickerWidgetState();
}

class _UniversalFilePickerWidgetState extends State<UniversalFilePickerWidget> {
  XFile? _selectedFile;
  // Cached because XFile.length() is async (web has no sync file IO)
  double? _selectedFileSizeMB;
  final _fileUploadService = FileUploadService();

  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _fileUploadService.takePhoto();
      if (file != null) _handleFilePicked(file);
    } catch (e) {
      _handleError('Error taking photo', e);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _fileUploadService.pickImageFromGallery();
      if (file != null) _handleFilePicked(file);
    } catch (e) {
      _handleError('Error picking image', e);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) await _handleFilePicked(video);
    } catch (e) {
      _handleError('Error picking video', e);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.camera);
      if (video != null) await _handleFilePicked(video);
    } catch (e) {
      _handleError('Error recording video', e);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.customAllowedExtensions ??
            _getDefaultExtensions(widget.pickerType),
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        await _handleFilePicked(_toXFile(result.files.single));
      }
    } catch (e) {
      _handleError('Error picking file', e);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
      if (result != null && result.files.isNotEmpty) {
        await _handleFilePicked(_toXFile(result.files.single));
      }
    } catch (e) {
      _handleError('Error picking file', e);
    }
  }

  /// file_picker gives no path on web, only bytes — wrap either into XFile
  XFile _toXFile(PlatformFile file) {
    if (file.path != null) {
      return XFile(file.path!, name: file.name);
    }
    return XFile.fromData(file.bytes!, name: file.name);
  }

  Future<void> _handleFilePicked(XFile file) async {
    final sizeMB = await _fileUploadService.getFileSizeInMB(file);

    // Validate file size
    if (sizeMB > widget.maxFileSizeMB) {
      log.w('File too large: ${sizeMB}MB');
      _showError('File too large. Max: ${widget.maxFileSizeMB}MB');
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

  void _handleError(String message, Object error) {
    log.e(message, error);
    _showError('$message: $error');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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

  List<String> _getDefaultExtensions(FilePickerType type) {
    switch (type) {
      case FilePickerType.image:
        return ['png', 'jpg', 'jpeg', 'gif', 'webp'];
      case FilePickerType.video:
        return ['mp4', 'avi', 'mov', 'mkv', 'webm'];
      case FilePickerType.document:
        return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
      case FilePickerType.all:
        return [];
      case FilePickerType.mixed:
        return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'mp4', 'avi', 'mov', 'mkv', 'pdf', 'doc', 'docx', 'xls', 'xlsx'];
    }
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
            if (widget.pickerType == FilePickerType.image ||
                widget.pickerType == FilePickerType.mixed)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            if (widget.pickerType == FilePickerType.image ||
                widget.pickerType == FilePickerType.mixed)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            if (widget.pickerType == FilePickerType.video ||
                widget.pickerType == FilePickerType.mixed)
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideoFromCamera();
                },
              ),
            if (widget.pickerType == FilePickerType.video ||
                widget.pickerType == FilePickerType.mixed)
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideoFromGallery();
                },
              ),
            if (widget.pickerType == FilePickerType.document ||
                widget.pickerType == FilePickerType.all ||
                widget.pickerType == FilePickerType.mixed)
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Choose Document'),
                onTap: () {
                  Navigator.pop(context);
                  widget.pickerType == FilePickerType.all
                      ? _pickFile()
                      : _pickDocument();
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

  IconData _getIconForFile() {
    if (_selectedFile == null) return Icons.cloud_upload;

    final extension = _selectedFile!.name.split('.').last.toLowerCase();

    if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension)) {
      return Icons.image;
    } else if (['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(extension)) {
      return Icons.videocam;
    } else if (extension == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(extension)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(extension)) {
      return Icons.table_chart;
    }

    return Icons.insert_drive_file;
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
                  _getIconForFile(),
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
                    isSelected ? Icons.check_circle : Icons.add_circle,
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
