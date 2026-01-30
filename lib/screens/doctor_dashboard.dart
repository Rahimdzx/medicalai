import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'add_record_screen.dart';
import 'qr_generator_screen.dart';
import 'language_settings_screen.dart';
import 'search_records_screen.dart';
import 'video_call_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchRecordsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // الجزء الجديد: عرض بيانات الطبيب (الصورة والسعر)
          _buildDoctorHeader(authProvider, l10n),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('records')
                  .where('doctorId', isEqualTo: authProvider.user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(l10n);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
                    return _RecordCard(record: record);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen())),
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecord),
      ),
    );
  }

  Widget _buildDoctorHeader(AuthProvider auth, l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.person, size: 40, color: Colors.white),
            // هنا يمكنك استخدام backgroundImage: NetworkImage(auth.userPhotoUrl)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?.email ?? "Doctor", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(auth.userRole, style: const TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text("Consultation Fee: \$50", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(l10n) => Center(child: Text(l10n.noRecords));
}

// ... كلاس _RecordCard يظل كما هو مع إضافة زر المكالمة الذي وضعته أنت

// ... كلاس _RecordCard يظل كما هو مع إضافة زر المكالمة الذي وضعته أنت
