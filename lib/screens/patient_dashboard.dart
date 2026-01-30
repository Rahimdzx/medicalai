import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'video_call_screen.dart';
import 'scan_qr_screen.dart'; // ستحتاج لإنشاء هذا الملف

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medical Records"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            return const Center(child: Text("No records found"));
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
      // زر المسح الضوئي للمريض ليقوم بمسح كود الطبيب
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final scannedId = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanQRScreen()),
          );
          if (scannedId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Connected to Doctor ID: $scannedId")),
            );
          }
        },
        label: const Text("Scan Doctor QR"),
        icon: const Icon(Icons.qr_code_scanner),
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
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: record.doctorPhotoUrl.isNotEmpty 
                  ? NetworkImage(record.doctorPhotoUrl) 
                  : null,
              child: record.doctorPhotoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(record.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(record.date),
            trailing: IconButton(
              icon: const Icon(Icons.videocam, color: Colors.green),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => VideoCallScreen(channelName: record.doctorId, token: ""))
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Diagnosis", record.diagnosis, Colors.red),
                const Divider(),
                _infoRow("Prescription", record.prescription, Colors.green),
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
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
