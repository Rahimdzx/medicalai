import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientRecord {
  final String id;
  final String patientId;
  final String patientEmail;
  final String doctorId;
  final String diagnosis;
  final String prescription;
  final String notes;
  final DateTime createdAt;

  PatientRecord({
    required this.id,
    required this.patientId,
    required this.patientEmail,
    required this.doctorId,
    required this.diagnosis,
    required this.prescription,
    required this.notes,
    required this.createdAt,
  });

  String get date => DateFormat('yyyy-MM-dd').format(createdAt);

  factory PatientRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientRecord(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientEmail: data['patientEmail'] ?? '',
      doctorId: data['doctorId'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      prescription: data['prescription'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
