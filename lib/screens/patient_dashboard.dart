import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'video_call_screen.dart';
import 'scan_qr_screen.dart'; 
import 'upload_records_screen.dart'; // إضافة شاشة رفع التحاليل

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("سجلاتي الطبية"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, tooltip: "رفع تحاليل/أشعة"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => auth.signOut(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب السجلات المرتبطة بإيميل المريض الحالي
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: auth.user?.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // تأكد من أن موديل PatientRecord مهيأ لاستقبال بيانات Firestore
              final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
              return _PatientRecordCard(record: record);
            },
          );
        },
      ),
      
      // زر المسح الضوئي للمريض ليقوم بمسح كود الطبيب في العيادة
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () async {
          final scannedId = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanQRScreen()),
          );
          if (scannedId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("تم الربط مع الطبيب بنجاح: $scannedId"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        label: const Text("مسح كود الطبيب"),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  // واجهة تظهر عندما لا توجد سجلات
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "لا توجد سجلات طبية حتى الآن",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordsScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text("رفع أول تحليل طبي لك"),
          )
        ],
      ),
    );
  }
}

class _PatientRecordCard extends StatelessWidget {
  final PatientRecord record;
  const _PatientRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: Colors.blue.shade800, width: 6)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: record.doctorPhotoUrl.isNotEmpty 
                    ? NetworkImage(record.doctorPhotoUrl) 
                    : null,
                child: record.doctorPhotoUrl.isEmpty 
                    ? const Icon(Icons.person, color: Colors.blue) 
                    : null,
              ),
              title: Text(
                "د. ${record.doctorName}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                record.date,
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.videocam, color: Colors.green, size: 30),
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      channelName: record.doctorId, 
                      token: "", // التوكن يتم توليده في النظام الحقيقي
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("التشخيص (Diagnosis)", record.diagnosis, Colors.red.shade700),
                  const SizedBox(height: 12),
                  _infoRow("الوصفة الطبية (Prescription)", record.prescription, Colors.green.shade700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }
}
