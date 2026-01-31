import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UploadRecordsScreen extends StatefulWidget {
  const UploadRecordsScreen({super.key});

  @override
  State<UploadRecordsScreen> createState() => _UploadRecordsScreenState();
}

class _UploadRecordsScreenState extends State<UploadRecordsScreen> {
  bool _isUploading = false;
  double _progress = 0;

  Future<void> _uploadFile() async {
    // 1. اختيار ملف (PDF أو صور)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      final auth = Provider.of<AuthProvider>(context, listen: false);

      setState(() {
        _isUploading = true;
        _progress = 0;
      });

      try {
        // 2. الرفع إلى Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('medical_records/${auth.user!.uid}/$fileName');

        UploadTask uploadTask = storageRef.putFile(file);

        // مراقبة التقدم
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _progress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        await uploadTask;
        String downloadUrl = await storageRef.getDownloadURL();

        // 3. حفظ الرابط في Firestore تحت سجلات المريض
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .collection('records')
            .add({
          'fileName': fileName,
          'fileUrl': downloadUrl,
          'uploadDate': FieldValue.serverTimestamp(),
          'type': fileName.split('.').last,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم رفع الملف بنجاح")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء الرفع")),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text("سجلاتي الطبية والتحاليل")),
      body: Column(
        children: [
          if (_isUploading)
            LinearProgressIndicator(value: _progress, minHeight: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(auth.user!.uid)
                  .collection('records')
                  .orderBy('uploadDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final records = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final data = records[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          data['type'] == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                          color: Colors.redAccent,
                        ),
                        title: Text(data['fileName']),
                        subtitle: Text("تاريخ الرفع: ${data['uploadDate']?.toDate().toString().split(' ')[0] ?? 'جاري الحفظ...'}"),
                        trailing: const Icon(Icons.download),
                        onTap: () {
                          // كود لفتح الملف أو تحميله
                        },
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
        label: const Text("رفع تحليل/إشاعة"),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}
