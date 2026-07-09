import 'package:image_picker/image_picker.dart';

/// Uses XFile (cross_file) instead of dart:io File so pickers and
/// previews work on Flutter web as well as mobile/desktop.
class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  final ImagePicker _picker = ImagePicker();

  factory FileUploadService() {
    return _instance;
  }

  FileUploadService._internal();

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
    } catch (e) {
      throw FilePickerException('Failed to pick image: $e');
    }
  }

  /// Pick image from gallery only
  Future<XFile?> pickImageFromGallery({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Take photo with camera
  Future<XFile?> takePhoto({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Get file size in bytes
  Future<int> getFileSize(XFile file) {
    return file.length();
  }

  /// Get file size in MB
  Future<double> getFileSizeInMB(XFile file) async {
    return await file.length() / (1024 * 1024);
  }

  /// Validate file size (in MB)
  Future<bool> isFileSizeValid(XFile file, double maxSizeMB) async {
    return await getFileSizeInMB(file) <= maxSizeMB;
  }

  /// Check if file is image
  bool isImage(XFile file) {
    final extension = file.name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Get MIME type
  String getMimeType(XFile file) {
    if (file.mimeType != null) return file.mimeType!;

    final extension = file.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file name
  String getFileName(XFile file) {
    return file.name;
  }
}

class FilePickerException implements Exception {
  final String message;

  FilePickerException(this.message);

  @override
  String toString() => message;
}
