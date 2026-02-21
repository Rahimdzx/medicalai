import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRecord {
  final String id;
  final String patientEmail;
  final String doctorId;
  final String doctorName;
  final String doctorPhotoUrl;
  final String diagnosis;
  final String prescription;
  final String? notes;
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
    this.notes,
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
      notes: data['notes'],
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientEmail': patientEmail,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhotoUrl': doctorPhotoUrl,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PatientRecord copyWith({
    String? id,
    String? patientEmail,
    String? doctorId,
    String? doctorName,
    String? doctorPhotoUrl,
    String? diagnosis,
    String? prescription,
    String? notes,
    String? date,
    DateTime? createdAt,
  }) {
    return PatientRecord(
      id: id ?? this.id,
      patientEmail: patientEmail ?? this.patientEmail,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
