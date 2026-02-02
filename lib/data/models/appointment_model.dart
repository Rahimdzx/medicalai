import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment model for scheduling consultations
class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhotoUrl;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String? doctorPhotoUrl;
  final String? doctorSpecialization;
  final DateTime appointmentDate;
  final String appointmentTime; // e.g., "14:30"
  final int durationMinutes;
  final String type; // 'in_person', 'video', 'audio'
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled', 'no_show'
  final String? reason; // Reason for visit
  final String? notes; // Doctor's notes
  final String? diagnosis;
  final String? prescription;
  final double? price;
  final bool isPaid;
  final String? paymentId;
  final String? chatId; // Associated chat ID
  final String? callChannelId; // For video calls
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final Map<String, dynamic>? metadata;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhotoUrl,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhotoUrl,
    this.doctorSpecialization,
    required this.appointmentDate,
    required this.appointmentTime,
    this.durationMinutes = 30,
    this.type = 'video',
    this.status = 'pending',
    this.reason,
    this.notes,
    this.diagnosis,
    this.prescription,
    this.price,
    this.isPaid = false,
    this.paymentId,
    this.chatId,
    this.callChannelId,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.metadata,
  });

  /// Create AppointmentModel from Firestore document
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientPhotoUrl: data['patientPhotoUrl'],
      patientPhone: data['patientPhone'],
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorPhotoUrl: data['doctorPhotoUrl'],
      doctorSpecialization: data['doctorSpecialization'],
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: data['appointmentTime'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 30,
      type: data['type'] ?? 'video',
      status: data['status'] ?? 'pending',
      reason: data['reason'],
      notes: data['notes'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      price: (data['price'] as num?)?.toDouble(),
      isPaid: data['isPaid'] ?? false,
      paymentId: data['paymentId'],
      chatId: data['chatId'],
      callChannelId: data['callChannelId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellationReason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create AppointmentModel from Map
  factory AppointmentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AppointmentModel(
      id: id ?? map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhotoUrl: map['patientPhotoUrl'],
      patientPhone: map['patientPhone'],
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorPhotoUrl: map['doctorPhotoUrl'],
      doctorSpecialization: map['doctorSpecialization'],
      appointmentDate: map['appointmentDate'] is Timestamp
          ? (map['appointmentDate'] as Timestamp).toDate()
          : map['appointmentDate'] as DateTime? ?? DateTime.now(),
      appointmentTime: map['appointmentTime'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 30,
      type: map['type'] ?? 'video',
      status: map['status'] ?? 'pending',
      reason: map['reason'],
      notes: map['notes'],
      diagnosis: map['diagnosis'],
      prescription: map['prescription'],
      price: (map['price'] as num?)?.toDouble(),
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      chatId: map['chatId'],
      callChannelId: map['callChannelId'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime? ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] as DateTime?,
      cancelledAt: map['cancelledAt'] is Timestamp
          ? (map['cancelledAt'] as Timestamp).toDate()
          : map['cancelledAt'] as DateTime?,
      cancellationReason: map['cancellationReason'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert AppointmentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhotoUrl': patientPhotoUrl,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhotoUrl': doctorPhotoUrl,
      'doctorSpecialization': doctorSpecialization,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'durationMinutes': durationMinutes,
      'type': type,
      'status': status,
      'reason': reason,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'price': price,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'chatId': chatId,
      'callChannelId': callChannelId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhotoUrl,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    String? doctorPhotoUrl,
    String? doctorSpecialization,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? durationMinutes,
    String? type,
    String? status,
    String? reason,
    String? notes,
    String? diagnosis,
    String? prescription,
    double? price,
    bool? isPaid,
    String? paymentId,
    String? chatId,
    String? callChannelId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      price: price ?? this.price,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      chatId: chatId ?? this.chatId,
      callChannelId: callChannelId ?? this.callChannelId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Status checks
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  /// Type checks
  bool get isInPerson => type == 'in_person';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  /// Check if appointment is in the past
  bool get isPast {
    return appointmentDate.isBefore(DateTime.now());
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    return appointmentDate.isAfter(DateTime.now()) && !isCancelled;
  }

  /// Get full appointment datetime
  DateTime get fullDateTime {
    final timeParts = appointmentTime.split(':');
    if (timeParts.length >= 2) {
      return DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
      );
    }
    return appointmentDate;
  }

  /// Get end time
  DateTime get endDateTime {
    return fullDateTime.add(Duration(minutes: durationMinutes));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppointmentModel(id: $id, date: $appointmentDate, status: $status)';
}
