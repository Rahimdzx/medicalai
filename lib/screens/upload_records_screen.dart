import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class UploadRecordsScreen extends StatefulWidget {
  const UploadRecordsScreen({super.key});

  @override
  State<UploadRecordsScreen> createState() => _UploadRecordsScreenState();
}

class _UploadRecordsScreenState extends State<UploadRecordsScreen> {
  bool _isUploading = false;
  double _progress = 0;
  String? _uploadError;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB limit

  Future<void> _uploadFile() async {
    setState(() {
      _uploadError = null;
    });

    try {
      // 1. Pick file (PDF or images)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: false,
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      
      // Check file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        setState(() {
          _uploadError = 'File size exceeds 10MB limit';
        });
        _showErrorSnackBar('File is too large. Maximum size is 10MB.');
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user == null) {
        _showErrorSnackBar('Please login to upload files');
        return;
      }

      setState(() {
        _isUploading = true;
        _progress = 0;
      });

      // 2. Upload to Firebase Storage with timestamp to avoid duplicates
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('medical_records/${auth.user!.uid}/$uniqueFileName');

      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'originalName': fileName,
          'uploadedBy': auth.user!.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask = storageRef.putFile(file, metadata);

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _progress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      }, onError: (error) {
        debugPrint('Upload error: $error');
      });

      await uploadTask;
      String downloadUrl = await storageRef.getDownloadURL();

      // 3. Save record to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.user!.uid)
          .collection('records')
          .add({
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'storagePath': 'medical_records/${auth.user!.uid}/$uniqueFileName',
        'fileSize': fileSize,
        'uploadDate': FieldValue.serverTimestamp(),
        'type': fileName.split('.').last.toLowerCase(),
        'uploadedBy': auth.user!.uid,
      });

      if (mounted) {
        _showSuccessSnackBar('File uploaded successfully');
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      String errorMessage = 'Upload failed';
      
      switch (e.code) {
        case 'unauthorized':
          errorMessage = 'Permission denied. Please check your login status.';
          break;
        case 'canceled':
          errorMessage = 'Upload was cancelled';
          break;
        case 'object-not-found':
          errorMessage = 'Storage location not found';
          break;
        case 'quota-exceeded':
          errorMessage = 'Storage quota exceeded';
          break;
        case 'unauthenticated':
          errorMessage = 'Please login again to upload files';
          break;
        case 'retry-limit-exceeded':
          errorMessage = 'Network error. Please check your connection and try again.';
          break;
        default:
          errorMessage = 'Upload error: ${e.message ?? e.code}';
      }
      
      setState(() {
        _uploadError = errorMessage;
      });
      _showErrorSnackBar(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('Upload error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _uploadError = 'An unexpected error occurred: $e';
      });
      _showErrorSnackBar('An error occurred during upload. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteRecord(String recordId, String? storagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete from Firestore
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .collection('records')
            .doc(recordId)
            .delete();

        // Delete from Storage if path exists
        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref().child(storagePath).delete();
          } catch (e) {
            debugPrint('Error deleting from storage: $e');
            // Continue even if storage delete fails
          }
        }

        if (mounted) {
          _showSuccessSnackBar('Record deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting record: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myMedicalRecords),
        actions: [
          if (_isUploading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          if (_uploadError != null)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadError!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _uploadError = null),
                    color: Colors.red[700],
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(auth.user?.uid)
                  .collection('records')
                  .orderBy('uploadDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading records',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecords,
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to upload your first record',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final records = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final data = records[index].data() as Map<String, dynamic>;
                    final recordId = records[index].id;
                    final fileType = data['type']?.toString().toLowerCase() ?? '';
                    final isImage = ['jpg', 'jpeg', 'png'].contains(fileType);
                    final uploadDate = data['uploadDate']?.toDate();
                    final storagePath = data['storagePath'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isImage ? Colors.blue[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isImage ? Icons.image : Icons.picture_as_pdf,
                            color: isImage ? Colors.blue : Colors.red,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          data['fileName'] ?? 'Unknown file',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              uploadDate != null
                                  ? 'Uploaded on: ${uploadDate.toString().split(' ')[0]}'
                                  : 'Processing...',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (data['fileSize'] != null)
                              Text(
                                'Size: ${_formatFileSize(data['fileSize'] as int)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new, color: Colors.blue),
                              tooltip: 'View',
                              onPressed: () {
                                // TODO: Open file viewer
                                final url = data['fileUrl'] as String?;
                                if (url != null) {
                                  // Open URL
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _deleteRecord(recordId, storagePath),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadFile,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : l10n.uploadFile),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
