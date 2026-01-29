import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // اختيار صورة من الكاميرا أو المعرض
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // اختيار ملف (PDF, صورة، إلخ)
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  // اختيار عدة ملفات
  Future<List<File>> pickMultipleFiles({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  // رفع ملف إلى Firebase Storage
  Future<UploadResult> uploadFile({
    required File file,
    required String recordId,
    required String userId,
    String? customPath,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = path.basename(file.path);
      final String extension = path.extension(file.path);
      final String uniqueId = _uuid.v4();
      
      // تحديد المسار في Storage
      final String storagePath = customPath ?? 
          'records/$userId/$recordId/${uniqueId}$extension';

      final Reference ref = _storage.ref().child(storagePath);
      
      // تحديد نوع الملف
      final String contentType = _getContentType(extension);
      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // رفع الملف مع تتبع التقدم
      final UploadTask uploadTask = ref.putFile(file, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // انتظار انتهاء الرفع
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult(
        success: true,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileName: fileName,
        fileSize: snapshot.totalBytes,
      );
    } catch (e) {
      print('Error uploading file: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // رفع عدة ملفات
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<File> files,
    required String recordId,
    required String userId,
    Function(int current, int total, double fileProgress)? onProgress,
  }) async {
    List<UploadResult> results = [];

    for (int i = 0; i < files.length; i++) {
      final result = await uploadFile(
        file: files[i],
        recordId: recordId,
        userId: userId,
        onProgress: (progress) {
          onProgress?.call(i + 1, files.length, progress);
        },
      );
      results.add(result);
    }

    return results;
  }

  // حذف ملف من Storage
  Future<bool> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // الحصول على نوع المحتوى
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

// نتيجة الرفع
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? storagePath;
  final String? fileName;
  final int? fileSize;
  final String? error;

  UploadResult({
    required this.success,
    this.downloadUrl,
    this.storagePath,
    this.fileName,
    this.fileSize,
    this.error,
  });
}

// نموذج المرفق
class Attachment {
  final String id;
  final String name;
  final String url;
  final String storagePath;
  final String type;
  final int size;
  final DateTime uploadedAt;

  Attachment({
    required this.id,
    required this.name,
    required this.url,
    required this.storagePath,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'storagePath': storagePath,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      storagePath: map['storagePath'] ?? '',
      type: map['type'] ?? '',
      size: map['size'] ?? 0,
      uploadedAt: DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
