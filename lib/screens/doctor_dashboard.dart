import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
// import '../providers/theme_provider.dart'; // تم تعطيله مؤقتاً لمنع الخطأ
import '../models/patient_record.dart';
// import '../services/pdf_export_service.dart'; // تأكد أن هذا الملف موجود أو عطله
import 'add_record_screen.dart';
import 'qr_generator_screen.dart';
import 'language_settings_screen.dart';
import 'search_records_screen.dart';
import 'medical_history_screen.dart';
// import 'video_call_screen.dart'; // تأكد أن هذا الملف موجود أو عطله

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    // final themeProvider = Provider.of<ThemeProvider>(context); // هذا السطر كان يسبب الانهيار

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchRecordsScreen()),
            ),
            tooltip: l10n.search,
          ),
          // تم إزالة زر تغيير الثيم مؤقتاً لأنه يسبب الشاشة الرمادية
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('doctorId', isEqualTo: authProvider.user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             // معالجة خطأ الـ Index في Firebase
            final error = snapshot.error.toString();
            if (error.contains('index') || error.contains('failed-precondition')) {
              return _buildIndexErrorState();
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(l10n);
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                try {
                  final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
                  return _RecordCard(record: record);
                } catch (e) {
                  return const SizedBox.shrink();
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddRecordScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecord),
      ),
    );
  }

  Widget _buildIndexErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Firebase Index Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please check your Firebase Console to create the index automatically via the link in logs.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.noRecords, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    switch (action) {
      case 'language':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
        break;
      case 'logout':
        authProvider.signOut();
        break;
    }
  }
}

class _RecordCard extends StatelessWidget {
  final PatientRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
            // _showRecordOptions(context); // تم تعطيلها مؤقتاً إذا لم يكن PDF Service جاهزاً
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.patientEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        Text(record.date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QRGeneratorScreen(record: record)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.medical_services, record.diagnosis, Colors.red[400]!),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.medication, record.prescription, Colors.green[400]!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
