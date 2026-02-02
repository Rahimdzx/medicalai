import 'package:cloud_firestore/cloud_firestore.dart';

/// Medical record model for patient health records
class MedicalRecordModel {
  final String id;
  final String patientId;
  final String patientEmail;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String? doctorPhotoUrl;
  final String? doctorSpecialization;
  final String type; // 'checkup', 'imaging', 'lab', 'prescription', 'followup', 'other'
  final String diagnosis;
  final String? prescription;
  final String? notes;
  final String? symptoms;
  final String? treatmentPlan;
  final List<Attachment> attachments;
  final List<Medication>? medications;
  final Map<String, dynamic>? vitals; // BP, heart rate, temperature, etc.
  final String? appointmentId;
  final bool isShared; // Shared with patient
  final DateTime recordDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.patientEmail,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhotoUrl,
    this.doctorSpecialization,
    this.type = 'checkup',
    required this.diagnosis,
    this.prescription,
    this.notes,
    this.symptoms,
    this.treatmentPlan,
    this.attachments = const [],
    this.medications,
    this.vitals,
    this.appointmentId,
    this.isShared = true,
    required this.recordDate,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create MedicalRecordModel from Firestore document
  factory MedicalRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse attachments
    final attachmentsData = data['attachments'] as List? ?? [];
    final attachments = attachmentsData
        .map((a) => Attachment.fromMap(a as Map<String, dynamic>))
        .toList();

    // Parse medications
    final medicationsData = data['medications'] as List?;
    final medications = medicationsData
        ?.map((m) => Medication.fromMap(m as Map<String, dynamic>))
        .toList();

    return MedicalRecordModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientEmail: data['patientEmail'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorPhotoUrl: data['doctorPhotoUrl'],
      doctorSpecialization: data['doctorSpecialization'],
      type: data['type'] ?? 'checkup',
      diagnosis: data['diagnosis'] ?? '',
      prescription: data['prescription'],
      notes: data['notes'],
      symptoms: data['symptoms'],
      treatmentPlan: data['treatmentPlan'],
      attachments: attachments,
      medications: medications,
      vitals: data['vitals'] as Map<String, dynamic>?,
      appointmentId: data['appointmentId'],
      isShared: data['isShared'] ?? true,
      recordDate: (data['recordDate'] as Timestamp?)?.toDate() ??
          (data['date'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create MedicalRecordModel from Map
  factory MedicalRecordModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final attachmentsData = map['attachments'] as List? ?? [];
    final attachments = attachmentsData
        .map((a) => Attachment.fromMap(a as Map<String, dynamic>))
        .toList();

    final medicationsData = map['medications'] as List?;
    final medications = medicationsData
        ?.map((m) => Medication.fromMap(m as Map<String, dynamic>))
        .toList();

    return MedicalRecordModel(
      id: id ?? map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientEmail: map['patientEmail'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorPhotoUrl: map['doctorPhotoUrl'],
      doctorSpecialization: map['doctorSpecialization'],
      type: map['type'] ?? 'checkup',
      diagnosis: map['diagnosis'] ?? '',
      prescription: map['prescription'],
      notes: map['notes'],
      symptoms: map['symptoms'],
      treatmentPlan: map['treatmentPlan'],
      attachments: attachments,
      medications: medications,
      vitals: map['vitals'] as Map<String, dynamic>?,
      appointmentId: map['appointmentId'],
      isShared: map['isShared'] ?? true,
      recordDate: map['recordDate'] is Timestamp
          ? (map['recordDate'] as Timestamp).toDate()
          : map['recordDate'] as DateTime? ?? DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime? ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] as DateTime?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert MedicalRecordModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientEmail': patientEmail,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhotoUrl': doctorPhotoUrl,
      'doctorSpecialization': doctorSpecialization,
      'type': type,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'symptoms': symptoms,
      'treatmentPlan': treatmentPlan,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'medications': medications?.map((m) => m.toMap()).toList(),
      'vitals': vitals,
      'appointmentId': appointmentId,
      'isShared': isShared,
      'recordDate': Timestamp.fromDate(recordDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  MedicalRecordModel copyWith({
    String? id,
    String? patientId,
    String? patientEmail,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorPhotoUrl,
    String? doctorSpecialization,
    String? type,
    String? diagnosis,
    String? prescription,
    String? notes,
    String? symptoms,
    String? treatmentPlan,
    List<Attachment>? attachments,
    List<Medication>? medications,
    Map<String, dynamic>? vitals,
    String? appointmentId,
    bool? isShared,
    DateTime? recordDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return MedicalRecordModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientEmail: patientEmail ?? this.patientEmail,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      type: type ?? this.type,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      attachments: attachments ?? this.attachments,
      medications: medications ?? this.medications,
      vitals: vitals ?? this.vitals,
      appointmentId: appointmentId ?? this.appointmentId,
      isShared: isShared ?? this.isShared,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Type checks
  bool get isCheckup => type == 'checkup';
  bool get isImaging => type == 'imaging';
  bool get isLab => type == 'lab';
  bool get isPrescription => type == 'prescription';
  bool get isFollowup => type == 'followup';

  /// Check if record has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if record has medications
  bool get hasMedications => medications != null && medications!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalRecordModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MedicalRecordModel(id: $id, type: $type, diagnosis: $diagnosis)';
}

/// Attachment model for medical records
class Attachment {
  final String id;
  final String name;
  final String url;
  final String type; // 'image', 'pdf', 'document', 'other'
  final int? size;
  final DateTime? uploadedAt;

  const Attachment({
    required this.id,
    required this.name,
    required this.url,
    this.type = 'other',
    this.size,
    this.uploadedAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'other',
      size: map['size'] as int?,
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : map['uploadedAt'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
    };
  }

  bool get isImage => type == 'image';
  bool get isPdf => type == 'pdf';
}

/// Medication model for prescriptions
class Medication {
  final String name;
  final String dosage;
  final String frequency; // 'daily', 'twice_daily', 'weekly', etc.
  final String? instructions;
  final int? durationDays;
  final DateTime? startDate;
  final DateTime? endDate;

  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.instructions,
    this.durationDays,
    this.startDate,
    this.endDate,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'daily',
      instructions: map['instructions'],
      durationDays: map['durationDays'] as int?,
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : map['startDate'] as DateTime?,
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : map['endDate'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'durationDays': durationDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}
