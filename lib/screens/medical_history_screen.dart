import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import '../services/pdf_export_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String? patientEmail;
  
  const MedicalHistoryScreen({super.key, this.patientEmail});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    // تحديد الإيميل بناءً على نوع المستخدم
    final email = widget.patientEmail ?? authProvider.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicalHistory ?? 'Medical History'),
        actions: [
          IconButton(
            icon: _isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : () => _exportToPdf(email),
            tooltip: l10n.exportPdf ?? 'Export PDF',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('patientEmail', isEqualTo: email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMedicalHistory ?? 'No medical history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data!.docs
              .map((doc) => PatientRecord.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final isFirst = index == 0;
              final isLast = index == records.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline line and dot
                    SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          // Top line
                          if (!isFirst)
                            Container(
                              width: 2,
                              height: 20,
                              color: theme.primaryColor.withOpacity(0.3),
                            ),
                          // Dot
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // Bottom line
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Card content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TimelineCard(record: record),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _exportToPdf(String email) async {
    setState(() => _isExporting = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('patientEmail', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .get();

      final records = snapshot.docs
          .map((doc) => PatientRecord.fromFirestore(doc))
          .toList();

      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No records to export')),
          );
        }
        return;
      }

      final pdfService = PdfExportService();
      final pdfFile = await pdfService.generateMedicalReport(
        records: records,
        patientEmail: email,
      );

      // عرض خيارات المشاركة
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    pdfService.sharePdf(pdfFile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Print'),
                  onTap: () {
                    Navigator.pop(context);
                    pdfService.printPdf(pdfFile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.preview),
                  title: const Text('Preview'),
                  onTap: () {
                    Navigator.pop(context);
                    pdfService.previewPdf(pdfFile);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}

class _TimelineCard extends StatelessWidget {
  final PatientRecord record;

  const _TimelineCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  onPressed: () => _exportSingleRecord(context),
                  tooltip: 'Export this record',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Diagnosis
            _buildSection(
              context,
              icon: Icons.medical_services,
              title: 'Diagnosis',
              content: record.diagnosis,
              color: Colors.red,
            ),
            const SizedBox(height: 12),

            // Prescription
            _buildSection(
              context,
              icon: Icons.medication,
              title: 'Prescription',
              content: record.prescription,
              color: Colors.green,
            ),

            // Notes
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
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
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

  Future<void> _exportSingleRecord(BuildContext context) async {
    try {
      final pdfService = PdfExportService();
      final pdfFile = await pdfService.generatePrescriptionPdf(record: record);
      await pdfService.sharePdf(pdfFile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
