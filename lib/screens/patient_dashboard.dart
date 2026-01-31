import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'video_call_screen.dart';
import 'scan_qr_screen.dart'; 
import 'upload_records_screen.dart';
import 'chat_screen.dart'; 

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("سجلاتي الطبية", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blue),
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
              final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
              return _PatientRecordCard(record: record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const ScanQRScreen())
          );
        },
        label: const Text("مسح كود الطبيب", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "لا توجد سجلات طبية حتى الآن",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const UploadRecordsScreen())
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              backgroundImage: record.doctorPhotoUrl.isNotEmpty 
                  ? NetworkImage(record.doctorPhotoUrl) 
                  : null,
              child: record.doctorPhotoUrl.isEmpty 
                  ? const Icon(Icons.person, color: Colors.blue) 
                  : null,
            ),
            title: Text(
              "د. ${record.doctorName}", 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Text(record.date, style: TextStyle(color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر المحادثة
                IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        appointmentId: record.doctorId, 
                        receiverName: record.doctorName
                      ),
                    ),
                  ),
                ),
                // زر مكالمة الفيديو
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: Colors.green),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoCallScreen(
                        channelName: record.doctorId, 
                        token: "" // تأكد من التعامل مع التوكن لاحقاً
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("التشخيص", record.diagnosis, Colors.red[700]!),
                const SizedBox(height: 12),
                _infoRow("الروشتة والعلاج", record.prescription, Colors.green[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            text, 
            style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)
          ),
        ),
      ],
    );
  }
}
