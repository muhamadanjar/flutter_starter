import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logger/index.dart';
import '../services/file_upload_service.dart';
import '../theme/app_colors.dart';

typedef OnImagePicked = void Function(XFile file);
typedef OnImageRemoved = void Function();

class AvatarUploadWidget extends StatefulWidget {
  final String? currentAvatarUrl;
  final OnImagePicked onImagePicked;
  final OnImageRemoved? onImageRemoved;
  final double size;
  final bool showRemoveButton;
  final EdgeInsets padding;
  final bool isLoading;
  final String? errorMessage;

  const AvatarUploadWidget({
    Key? key,
    this.currentAvatarUrl,
    required this.onImagePicked,
    this.onImageRemoved,
    this.size = 120,
    this.showRemoveButton = true,
    this.padding = const EdgeInsets.all(16),
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  XFile? _selectedFile;
  // Preview bytes: Image.file is unsupported on Flutter web, so we
  // read the picked file into memory and render with Image.memory.
  Uint8List? _selectedBytes;
  final _fileUploadService = FileUploadService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _fileUploadService.pickImage(source: source);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _selectedBytes = bytes;
        });
        widget.onImagePicked(file);
        log.d('Image picked: ${file.name}');
      }
    } catch (e) {
      log.e('Error picking image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFile = null;
      _selectedBytes = null;
    });
    widget.onImageRemoved?.call();
    log.d('Image removed');
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
              'Select Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if ((_selectedFile != null || widget.currentAvatarUrl != null) &&
                widget.showRemoveButton)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.isLoading ? null : _showPickerMenu,
            child: Stack(
              children: [
                // Avatar circle
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.divider,
                      width: 2,
                    ),
                    color: colors.surface,
                  ),
                  child: ClipOval(
                    child: _selectedBytes != null
                        ? Image.memory(
                            _selectedBytes!,
                            fit: BoxFit.cover,
                          )
                        : widget.currentAvatarUrl != null
                            ? Image.network(
                                widget.currentAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(colors),
                              )
                            : _buildPlaceholder(colors),
                  ),
                ),

                // Loading indicator
                if (widget.isLoading)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Edit button
                if (!widget.isLoading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Error message
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: TextStyle(color: colors.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(AppColorScheme colors) {
    return Container(
      color: colors.surface,
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: colors.textSecondary,
      ),
    );
  }
}
