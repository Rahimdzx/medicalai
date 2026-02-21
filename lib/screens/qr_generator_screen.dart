import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/patient_record.dart';

class QRGeneratorScreen extends StatelessWidget {
  final PatientRecord record;

  const QRGeneratorScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final qrData = '''
Medical Record
Patient: ${record.patientEmail}
Date: ${record.date}
Diagnosis: ${record.diagnosis}
Prescription: ${record.prescription}
Notes: ${record.notes}
''';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrForRecord)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.patientCanScan,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(l10n.patientEmail, record.patientEmail),
                      _buildInfoRow(l10n.date, record.date),
                      _buildInfoRow(l10n.diagnosis, record.diagnosis),
                      _buildInfoRow(l10n.prescription, record.prescription),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildInfoRow(l10n.notes, record.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareFeatureComingSoon)),
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(l10n.shareQR),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
