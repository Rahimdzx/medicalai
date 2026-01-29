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

  // عرض التاريخ بشكل آمن
  String get date {
    try {
      return DateFormat('yyyy-MM-dd').format(createdAt);
    } catch (e) {
      return "0000-00-00";
    }
  }

  factory PatientRecord.fromFirestore(DocumentSnapshot doc) {
    // 1. حماية ضد المستندات الفارغة تماماً
    if (!doc.exists || doc.data() == null) {
       return PatientRecord.empty(doc.id);
    }

    final data = doc.data() as Map<String, dynamic>;

    return PatientRecord(
      id: doc.id,
      // 2. استخدام .toString() يحمي من خطأ (Type Null is not subtype of String)
      // ويسمح بقراءة البيانات القديمة حتى لو كانت مخزنة كأرقام
      patientId: (data['patientId'] ?? '').toString(),
      patientEmail: (data['patientEmail'] ?? '').toString(),
      doctorId: (data['doctorId'] ?? '').toString(),
      diagnosis: (data['diagnosis'] ?? '').toString(),
      prescription: (data['prescription'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      
      // 3. الحل الجذري لمشكلة التاريخ (أكثر سبب للشاشة الرمادية)
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  // دالة ذكية لمعالجة التاريخ المسجل مسبقاً بأي صيغة
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now(); // إذا كان الحقل مفقوداً في البيانات القديمة
    }
  }

  // كائن احتياطي في حال وجود خطأ كارثي في مستند معين
  factory PatientRecord.empty(String id) {
    return PatientRecord(
      id: id,
      patientId: '',
      patientEmail: 'Unknown',
      doctorId: '',
      diagnosis: '',
      prescription: '',
      notes: '',
      createdAt: DateTime.now(),
    );
  }
}
