import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppointmentModel> createBooking({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String date,
    required String timeSlot,
    required String format,
    required double price,
    required String currency,
  }) async {
    final appointmentId = _firestore.collection('appointments').doc().id;
    final chatId = _firestore.collection('chats').doc().id;

    final appointment = AppointmentModel(
      id: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      doctorName: doctorName,
      date: date,
      timeSlot: timeSlot,
      format: format,
      price: price,
      currency: currency,
      chatId: chatId,
      createdAt: DateTime.now(),
    );

    // Create appointment
    await _firestore.collection('appointments').doc(appointmentId).set(appointment.toMap());

    // Create chat
    await _firestore.collection('chats').doc(chatId).set({
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // Add system message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': 'system',
      'senderRole': 'system',
      'text': 'Welcome! Please prepare your questions and medical reports.',
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Mark slot as booked
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('schedule')
        .doc(date)
        .update({
      'slots': FieldValue.arrayUnion([{
        'time': timeSlot,
        'booked': true,
        'patientId': patientId,
        'appointmentId': appointmentId,
      }])
    });

    return appointment;
  }

  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
  }

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
  }
}
