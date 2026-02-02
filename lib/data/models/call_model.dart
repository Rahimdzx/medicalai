import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Call model for video/audio calls
class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final String channelName;
  final String? token; // Agora token
  final String type; // 'video', 'audio'
  final String status; // 'calling', 'active', 'ended', 'missed', 'rejected'
  final DateTime startTime;
  final DateTime? answerTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final String? appointmentId;
  final bool hasVideo;
  final bool callerMuted;
  final bool receiverMuted;
  final bool callerCameraOff;
  final bool receiverCameraOff;
  final String? endedBy; // userId who ended the call
  final String? endReason; // 'completed', 'declined', 'missed', 'error', 'network'
  final int? qualityRating; // 1-5 rating after call
  final String? qualityFeedback;
  final Map<String, dynamic>? metadata;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.channelName,
    this.token,
    this.type = AppConstants.callTypeVideo,
    this.status = AppConstants.callStatusCalling,
    required this.startTime,
    this.answerTime,
    this.endTime,
    this.durationSeconds,
    this.appointmentId,
    this.hasVideo = true,
    this.callerMuted = false,
    this.receiverMuted = false,
    this.callerCameraOff = false,
    this.receiverCameraOff = false,
    this.endedBy,
    this.endReason,
    this.qualityRating,
    this.qualityFeedback,
    this.metadata,
  });

  /// Create CallModel from Firestore document
  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallModel(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerPhotoUrl: data['callerPhotoUrl'],
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverPhotoUrl: data['receiverPhotoUrl'],
      channelName: data['channelName'] ?? '',
      token: data['token'],
      type: data['type'] ?? AppConstants.callTypeVideo,
      status: data['status'] ?? AppConstants.callStatusCalling,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answerTime: (data['answerTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationSeconds: data['durationSeconds'] as int?,
      appointmentId: data['appointmentId'],
      hasVideo: data['hasVideo'] ?? true,
      callerMuted: data['callerMuted'] ?? false,
      receiverMuted: data['receiverMuted'] ?? false,
      callerCameraOff: data['callerCameraOff'] ?? false,
      receiverCameraOff: data['receiverCameraOff'] ?? false,
      endedBy: data['endedBy'],
      endReason: data['endReason'],
      qualityRating: data['qualityRating'] as int?,
      qualityFeedback: data['qualityFeedback'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create CallModel from Map
  factory CallModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CallModel(
      id: id ?? map['id'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhotoUrl: map['callerPhotoUrl'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhotoUrl: map['receiverPhotoUrl'],
      channelName: map['channelName'] ?? '',
      token: map['token'],
      type: map['type'] ?? AppConstants.callTypeVideo,
      status: map['status'] ?? AppConstants.callStatusCalling,
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : map['startTime'] as DateTime? ?? DateTime.now(),
      answerTime: map['answerTime'] is Timestamp
          ? (map['answerTime'] as Timestamp).toDate()
          : map['answerTime'] as DateTime?,
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : map['endTime'] as DateTime?,
      durationSeconds: map['durationSeconds'] as int?,
      appointmentId: map['appointmentId'],
      hasVideo: map['hasVideo'] ?? true,
      callerMuted: map['callerMuted'] ?? false,
      receiverMuted: map['receiverMuted'] ?? false,
      callerCameraOff: map['callerCameraOff'] ?? false,
      receiverCameraOff: map['receiverCameraOff'] ?? false,
      endedBy: map['endedBy'],
      endReason: map['endReason'],
      qualityRating: map['qualityRating'] as int?,
      qualityFeedback: map['qualityFeedback'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert CallModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'channelName': channelName,
      'token': token,
      'type': type,
      'status': status,
      'startTime': Timestamp.fromDate(startTime),
      'answerTime': answerTime != null ? Timestamp.fromDate(answerTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': durationSeconds,
      'appointmentId': appointmentId,
      'hasVideo': hasVideo,
      'callerMuted': callerMuted,
      'receiverMuted': receiverMuted,
      'callerCameraOff': callerCameraOff,
      'receiverCameraOff': receiverCameraOff,
      'endedBy': endedBy,
      'endReason': endReason,
      'qualityRating': qualityRating,
      'qualityFeedback': qualityFeedback,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    String? channelName,
    String? token,
    String? type,
    String? status,
    DateTime? startTime,
    DateTime? answerTime,
    DateTime? endTime,
    int? durationSeconds,
    String? appointmentId,
    bool? hasVideo,
    bool? callerMuted,
    bool? receiverMuted,
    bool? callerCameraOff,
    bool? receiverCameraOff,
    String? endedBy,
    String? endReason,
    int? qualityRating,
    String? qualityFeedback,
    Map<String, dynamic>? metadata,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      channelName: channelName ?? this.channelName,
      token: token ?? this.token,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      answerTime: answerTime ?? this.answerTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      appointmentId: appointmentId ?? this.appointmentId,
      hasVideo: hasVideo ?? this.hasVideo,
      callerMuted: callerMuted ?? this.callerMuted,
      receiverMuted: receiverMuted ?? this.receiverMuted,
      callerCameraOff: callerCameraOff ?? this.callerCameraOff,
      receiverCameraOff: receiverCameraOff ?? this.receiverCameraOff,
      endedBy: endedBy ?? this.endedBy,
      endReason: endReason ?? this.endReason,
      qualityRating: qualityRating ?? this.qualityRating,
      qualityFeedback: qualityFeedback ?? this.qualityFeedback,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Status checks
  bool get isCalling => status == AppConstants.callStatusCalling;
  bool get isActive => status == AppConstants.callStatusActive;
  bool get isEnded => status == AppConstants.callStatusEnded;
  bool get isMissed => status == AppConstants.callStatusMissed;
  bool get isRejected => status == AppConstants.callStatusRejected;

  /// Type checks
  bool get isVideoCall => type == AppConstants.callTypeVideo;
  bool get isAudioCall => type == AppConstants.callTypeAudio;

  /// Get call duration
  Duration get duration {
    if (durationSeconds != null) {
      return Duration(seconds: durationSeconds!);
    }
    if (answerTime != null && endTime != null) {
      return endTime!.difference(answerTime!);
    }
    return Duration.zero;
  }

  /// Get formatted duration string
  String get durationFormatted {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if user is the caller
  bool isCaller(String userId) => callerId == userId;

  /// Check if user is the receiver
  bool isReceiver(String userId) => receiverId == userId;

  /// Get the other party's info based on current user
  String getOtherPartyName(String currentUserId) {
    return isCaller(currentUserId) ? receiverName : callerName;
  }

  String? getOtherPartyPhoto(String currentUserId) {
    return isCaller(currentUserId) ? receiverPhotoUrl : callerPhotoUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CallModel(id: $id, type: $type, status: $status)';
}
