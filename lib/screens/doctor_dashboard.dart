import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import '../l10n/app_localizations.dart';
import 'chat_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorDashboard),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 15,
              backgroundImage: (auth.photoUrl != null) ? NetworkImage(auth.photoUrl!) : null,
              child: (auth.photoUrl == null) ? const Icon(Icons.person) : null,
            ),
            onPressed: () => _showDoctorInfo(context, auth, l10n),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.signOut()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('doctorId', isEqualTo: auth.user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
              return Card(
                child: ListTile(
                  title: Text(record.patientEmail),
                  subtitle: Text(record.date),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat, color: Colors.blue),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(appointmentId: record.doctorId, receiverName: record.patientEmail))),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDoctorInfo(BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30, // منع التداخل مع الكيبورد
          top: 25, left: 20, right: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // حل مشكلة قطع النص
          children: [
            CircleAvatar(radius: 50, backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null),
            const SizedBox(height: 15),
            Text(auth.userName ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text("Price: ${auth.price} \$", style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
