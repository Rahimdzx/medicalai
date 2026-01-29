import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/patient_record.dart';
import 'qr_scanner_screen.dart';
import 'language_settings_screen.dart';
import 'medical_history_screen.dart';
import 'medication_reminders_screen.dart';
import 'search_records_screen.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.patientDashboard),
        actions: [
          // زر الوضع الليلي
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          // قائمة الإعدادات
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, authProvider),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.medicalHistory ?? 'Medical History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'reminders',
                child: ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(l10n.medicationReminders ?? 'Reminders'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(l10n.search ?? 'Search'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language ?? 'Language'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.logout ?? 'Logout',
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
            .where('patientEmail', isEqualTo: authProvider.user?.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // معالجة خطأ الفهرس
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('index')) {
              return _buildIndexErrorWidget(context);
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          final records = snapshot.data!.docs
              .map((doc) => PatientRecord.fromFirestore(doc))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {},
            child: CustomScrollView(
              slivers: [
                // إحصائيات سريعة
                SliverToBoxAdapter(
                  child: _buildQuickStats(context, records),
                ),
                // قائمة السجلات
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PatientRecordCard(record: records[index]),
                      childCount: records.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.scanQR),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, List<PatientRecord> records) {
    final theme = Theme.of(context);
    final thisMonth = records.where((r) => 
      r.createdAt.month == DateTime.now().month &&
      r.createdAt.year == DateTime.now().year
    ).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.folder,
              value: records.length.toString(),
              label: 'Total Records',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white30,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_today,
              value: thisMonth.toString(),
              label: 'This Month',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              l10n.noMedicalRecords ?? 'No medical records yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan a QR code from your doctor to add your first record',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.scanQR),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexErrorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Firebase Index Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please create the required index in Firebase Console:\n\n'
              'Collection: records\n'
              'Fields: patientEmail (Ascending), createdAt (Descending)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, AuthProvider authProvider) {
    switch (action) {
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicalHistoryScreen()),
        );
        break;
      case 'reminders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicationRemindersScreen()),
        );
        break;
      case 'search':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchRecordsScreen()),
        );
        break;
      case 'language':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
        );
        break;
      case 'logout':
        authProvider.signOut();
        break;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PatientRecordCard extends StatelessWidget {
  final PatientRecord record;

  const _PatientRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.date,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.local_hospital, size: 20, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 16),

            // التشخيص
            _buildSection(
              context,
              icon: Icons.medical_services,
              title: 'Diagnosis',
              content: record.diagnosis,
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // الوصفة
            _buildSection(
              context,
              icon: Icons.medication,
              title: 'Prescription',
              content: record.prescription,
              color: Colors.green,
            ),

            // الملاحظات
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSection(
                context,
                icon: Icons.notes,
                title: 'Notes',
                content: record.notes,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
