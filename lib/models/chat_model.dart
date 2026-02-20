import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final String status;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    this.status = 'active',
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.fileUrl,
    this.fileName,
    this.fileType,
    required this.timestamp,
    this.read = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderRole: data['senderRole'] ?? 'patient',
      text: data['text'] ?? '',
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileType: data['fileType'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }
}
