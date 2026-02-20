import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String date;
  final String timeSlot;
  final String format;
  final double price;
  final String currency;
  final String status;
  final String paymentStatus;
  final String chatId;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.timeSlot,
    required this.format,
    required this.price,
    required this.currency,
    this.status = 'confirmed',
    this.paymentStatus = 'paid',
    required this.chatId,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      date: data['date'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      format: data['format'] ?? 'video',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      status: data['status'] ?? 'confirmed',
      paymentStatus: data['paymentStatus'] ?? 'paid',
      chatId: data['chatId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date,
      'timeSlot': timeSlot,
      'format': format,
      'price': price,
      'currency': currency,
      'status': status,
      'paymentStatus': paymentStatus,
      'chatId': chatId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
