import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  final ImagePicker _picker = ImagePicker();

  factory FileUploadService() {
    return _instance;
  }

  FileUploadService._internal();

  /// Pick image from gallery or camera
  Future<File?> pickImage({
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw FilePickerException('Failed to pick image: $e');
    }
  }

  /// Pick image from gallery only
  Future<File?> pickImageFromGallery({
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
  Future<File?> takePhoto({
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
  int getFileSize(File file) {
    return file.lengthSync();
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  /// Validate file size (in MB)
  bool isFileSizeValid(File file, double maxSizeMB) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }

  /// Check if file is image
  bool isImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Get MIME type
  String getMimeType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
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
  String getFileName(File file) {
    return file.path.split('/').last;
  }
}

class FilePickerException implements Exception {
  final String message;

  FilePickerException(this.message);

  @override
  String toString() => message;
}
