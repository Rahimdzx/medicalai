import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/patient_record.dart';
import '../services/pdf_export_service.dart';
import 'add_record_screen.dart';
import 'qr_generator_screen.dart';
import 'language_settings_screen.dart';
import 'search_records_screen.dart';
import 'medical_history_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorDashboard),
        actions: [
          // زر البحث
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchRecordsScreen()),
              );
            },
            tooltip: l10n.search ?? 'Search',
          ),
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
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language ?? 'Language'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export_all',
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(l10n.exportAll ?? 'Export All'),
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
            .where('doctorId', isEqualTo: authProvider.user?.uid)
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
                        'Fields: doctorId (Ascending), createdAt (Descending)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRecords,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first record',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data!.docs
              .map((doc) => PatientRecord.fromFirestore(doc))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _RecordCard(record: record);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecordScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecord),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (action) {
      case 'language':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
        );
        break;
      case 'export_all':
        _exportAllRecords(context);
        break;
      case 'logout':
        authProvider.signOut();
        break;
    }
  }

  Future<void> _exportAllRecords(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('doctorId', isEqualTo: authProvider.user?.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final records = snapshot.docs
          .map((doc) => PatientRecord.fromFirestore(doc))
          .toList();

      Navigator.pop(context); // إغلاق مؤشر التحميل

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noRecords)),
        );
        return;
      }

      final pdfService = PdfExportService();
      final pdfFile = await pdfService.generateMedicalReport(
        records: records,
        patientEmail: 'All Patients',
        patientName: 'Dr. ${authProvider.user?.email ?? ""}\'s Records',
      );

      await pdfService.sharePdf(pdfFile);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RecordCard extends StatelessWidget {
  final PatientRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecordOptions(context),
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
                        Text(
                          record.patientEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          record.date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRGeneratorScreen(record: record),
                        ),
                      );
                    },
                    tooltip: 'Generate QR Code',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // التشخيص
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services, size: 18, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.diagnosis,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // الوصفة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medication, size: 18, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.prescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(l10n.generateQR ?? 'Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRGeneratorScreen(record: record),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n.exportPdf ?? 'Export as PDF'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdfService = PdfExportService();
                  final pdfFile = await pdfService.generatePrescriptionPdf(
                    record: record,
                  );
                  await pdfService.sharePdf(pdfFile);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.patientHistory ?? 'Patient History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalHistoryScreen(
                      patientEmail: record.patientEmail,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: Text(l10n.print ?? 'Print'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdfService = PdfExportService();
                  final pdfFile = await pdfService.generatePrescriptionPdf(
                    record: record,
                  );
                  await pdfService.printPdf(pdfFile);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
