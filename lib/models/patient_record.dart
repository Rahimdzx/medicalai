import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRecord {
  final String id;
  final String patientEmail;
  final String doctorId;
  final String doctorName;     // التأكد من وجود هذا السطر
  final String doctorPhotoUrl; // التأكد من وجود هذا السطر
  final String diagnosis;
  final String prescription;
  final String date;
  final DateTime createdAt;

  PatientRecord({
    required this.id,
    required this.patientEmail,
    required this.doctorId,
    required this.doctorName,
    required this.doctorPhotoUrl,
    required this.diagnosis,
    required this.prescription,
    required this.date,
    required this.createdAt,
  });

  factory PatientRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PatientRecord(
      id: doc.id,
      patientEmail: data['patientEmail'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? 'Doctor',
      doctorPhotoUrl: data['doctorPhotoUrl'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      prescription: data['prescription'] ?? '',
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
