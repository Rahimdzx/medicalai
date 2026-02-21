import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/patient_record.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  // إنشاء PDF للوصفة الطبية
  Future<File> generatePrescriptionPdf({
    required PatientRecord record,
    String? doctorName,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
  }) async {
    final pdf = pw.Document();

    // تحميل خط يدعم العربية (اختياري)
    // final arabicFont = await _loadArabicFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(clinicName, clinicAddress, clinicPhone),
              pw.SizedBox(height: 30),
              
              // Title
              pw.Center(
                child: pw.Text(
                  'MEDICAL PRESCRIPTION',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Divider
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),

              // Patient Info
              _buildSection('Patient Information', [
                _buildInfoRow('Email:', record.patientEmail),
                _buildInfoRow('Date:', record.date),
              ]),
              pw.SizedBox(height: 20),

              // Diagnosis
              _buildSection('Diagnosis', [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    record.diagnosis,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ]),
              pw.SizedBox(height: 20),

              // Prescription
              _buildSection('Prescription', [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue800),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    record.prescription,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ]),
              
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildSection('Notes', [
                  pw.Text(
                    record.notes!,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ]),
              ],

              pw.Spacer(),

              // Footer
              _buildFooter(doctorName),
            ],
          );
        },
      ),
    );

    // حفظ الملف
    final outputDir = await getTemporaryDirectory();
    final outputFile = File(
      '${outputDir.path}/prescription_${record.id}_${DateTime.now().millisecondsSinceEpoch}.pdf'
    );
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  pw.Widget _buildHeader(String? clinicName, String? clinicAddress, String? clinicPhone) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          // Logo placeholder
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(30),
            ),
            child: pw.Center(
              child: pw.Text(
                '+',
                style: pw.TextStyle(
                  fontSize: 40,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clinicName ?? 'Medical Clinic',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                if (clinicAddress != null)
                  pw.Text(
                    clinicAddress,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                if (clinicPhone != null)
                  pw.Text(
                    'Tel: $clinicPhone',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(String? doctorName) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Doctor Signature:',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 1)),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  doctorName ?? 'Dr.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated by Medical App',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // مشاركة PDF
  Future<void> sharePdf(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Medical Prescription',
    );
  }

  // طباعة PDF
  Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfFile.readAsBytesSync(),
    );
  }

  // معاينة PDF
  Future<void> previewPdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  // إنشاء تقرير طبي شامل
  Future<File> generateMedicalReport({
    required List<PatientRecord> records,
    required String patientEmail,
    String? patientName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Medical History Report',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title
            pw.Center(
              child: pw.Text(
                'MEDICAL HISTORY REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                patientName ?? patientEmail,
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Divider(thickness: 2, color: PdfColors.blue800),
            pw.SizedBox(height: 20),

            // Records
            ...records.map((record) => _buildRecordEntry(record)).toList(),
          ];
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final outputFile = File(
      '${outputDir.path}/medical_report_${DateTime.now().millisecondsSinceEpoch}.pdf'
    );
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  pw.Widget _buildRecordEntry(PatientRecord record) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Date: ${record.date}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'ID: ${record.id.substring(0, 8)}...',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Diagnosis:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(record.diagnosis, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Prescription:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(record.prescription, style: const pw.TextStyle(fontSize: 10)),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Notes:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              record.notes!,
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
