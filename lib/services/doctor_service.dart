import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DoctorModel>> getDoctors({String? specialty}) async {
    Query query = _firestore.collection('doctors').where('isActive', isEqualTo: true);
    
    if (specialty != null && specialty.isNotEmpty) {
      query = query.where('specialty', isEqualTo: specialty);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => DoctorModel.fromFirestore(doc)).toList();
  }

  Future<DoctorModel?> getDoctorById(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();
    if (doc.exists) {
      return DoctorModel.fromFirestore(doc);
    }
    return null;
  }

  Future<DoctorModel?> getDoctorByNumber(String doctorNumber) async {
    final snapshot = await _firestore
        .collection('doctors')
        .where('doctorNumber', isEqualTo: doctorNumber)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return DoctorModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots(String doctorId, String date) async {
    final doc = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .doc(date)
        .get();
    
    if (!doc.exists) return [];
    
    final data = doc.data() as Map<String, dynamic>;
    if (data['isOpen'] != true) return [];
    
    final slots = data['slots'] as List<dynamic>? ?? [];
    return slots.where((slot) => slot['booked'] != true).toList().cast<Map<String, dynamic>>();
  }

  Future<void> updateSchedule(String doctorId, String date, List<Map<String, dynamic>> slots, bool isOpen) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .doc(date)
        .set({
      'isOpen': isOpen,
      'slots': slots,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getSpecialties() async {
    final snapshot = await _firestore.collection('doctors').get();
    final specialties = snapshot.docs
        .map((doc) => doc['specialty'] as String)
        .toSet()
        .toList();
    return specialties;
  }
}
