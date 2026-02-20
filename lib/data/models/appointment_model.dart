import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final Map<String, dynamic> timeSlot;
  final String? serviceId;
  final String status; // confirmed, completed, cancelled
  final String paymentStatus; // pending, paid, refunded
  final double paymentAmount;
  final double platformCommission;
  final String chatId;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.timeSlot,
    this.serviceId,
    required this.status,
    required this.paymentStatus,
    required this.paymentAmount,
    required this.platformCommission,
    required this.chatId,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      date: data['date'] ?? '',
      timeSlot: data['timeSlot'] ?? {},
      serviceId: data['serviceId'],
      status: data['status'] ?? 'confirmed',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentAmount: (data['paymentAmount'] ?? 0).toDouble(),
      platformCommission: (data['platformCommission'] ?? 0).toDouble(),
      chatId: data['chatId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'timeSlot': timeSlot,
      'serviceId': serviceId,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentAmount': paymentAmount,
      'platformCommission': platformCommission,
      'chatId': chatId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
