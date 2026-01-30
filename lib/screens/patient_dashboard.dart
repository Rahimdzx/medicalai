import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'video_call_screen.dart';
import 'language_settings_screen.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.patientDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: authProvider.user?.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(l10n);

          final records = snapshot.data!.docs.map((doc) => PatientRecord.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) => _PatientRecordCard(record: records[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(l10n) => Center(child: Text(l10n.noRecords));
}

class _PatientRecordCard extends StatelessWidget {
  final PatientRecord record;
  const _PatientRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                // زر الانضمام للمكالمة
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoCallScreen(channelName: record.doctorId, token: "")),
                  ),
                  icon: const Icon(Icons.video_call),
                  label: const Text("Join Call"),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("Diagnosis", record.diagnosis, Icons.healing, Colors.red),
                const Divider(),
                _buildSection("Prescription", record.prescription, Icons.medication, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
