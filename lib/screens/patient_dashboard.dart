import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'video_call_screen.dart';
import 'scan_qr_screen.dart'; 
import 'upload_records_screen.dart';
import 'chat_screen.dart'; // تأكد من وجود الملف

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
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQRScreen()));
        },
        label: const Text("مسح كود الطبيب"),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[400]),
          const Text("لا توجد سجلات طبية حتى الآن", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadRecordsScreen())),
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundImage: record.doctorPhotoUrl.isNotEmpty ? NetworkImage(record.doctorPhotoUrl) : null,
              child: record.doctorPhotoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text("د. ${record.doctorName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(record.date),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر المحادثة الجديد للمريض
                IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(appointmentId: record.doctorId, receiverName: record.doctorName),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.green),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoCallScreen(channelName: record.doctorId, token: "")),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("التشخيص", record.diagnosis, Colors.red),
                const Divider(),
                _infoRow("الروشتة", record.prescription, Colors.green),
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
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(text, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
