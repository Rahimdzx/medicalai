import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Message model for chat functionality
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String type; // 'text', 'image', 'file', 'audio', 'location'
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? audioDuration; // Duration in seconds for audio messages
  final double? latitude; // For location messages
  final double? longitude;
  final String? locationAddress;
  final String status; // 'sent', 'delivered', 'read'
  final bool isDeleted;
  final String? replyToMessageId;
  final String? replyToText;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.audioDuration,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.status = AppConstants.messageStatusSent,
    this.isDeleted = false,
    this.replyToMessageId,
    this.replyToText,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc, {String? chatId}) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: chatId ?? data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'],
      senderPhotoUrl: data['senderPhotoUrl'],
      type: data['type'] ?? AppConstants.messageTypeText,
      text: data['text'],
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'] as int?,
      audioDuration: data['audioDuration'] as int?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationAddress: data['locationAddress'],
      status: data['status'] ?? AppConstants.messageStatusSent,
      isDeleted: data['isDeleted'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      replyToText: data['replyToText'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create MessageModel from Map
  factory MessageModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MessageModel(
      id: id ?? map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderPhotoUrl: map['senderPhotoUrl'],
      type: map['type'] ?? AppConstants.messageTypeText,
      text: map['text'],
      mediaUrl: map['mediaUrl'] ?? map['imageUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'] as int?,
      audioDuration: map['audioDuration'] as int?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['locationAddress'],
      status: map['status'] ?? AppConstants.messageStatusSent,
      isDeleted: map['isDeleted'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime? ?? DateTime.now(),
      readAt: map['readAt'] is Timestamp
          ? (map['readAt'] as Timestamp).toDate()
          : map['readAt'] as DateTime?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'audioDuration': audioDuration,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'status': status,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? audioDuration,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? status,
    bool? isDeleted,
    String? replyToMessageId,
    String? replyToText,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      audioDuration: audioDuration ?? this.audioDuration,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check message type
  bool get isTextMessage => type == AppConstants.messageTypeText;
  bool get isImageMessage => type == AppConstants.messageTypeImage;
  bool get isFileMessage => type == AppConstants.messageTypeFile;
  bool get isAudioMessage => type == AppConstants.messageTypeAudio;
  bool get isLocationMessage => type == AppConstants.messageTypeLocation;

  /// Check message status
  bool get isSent => status == AppConstants.messageStatusSent;
  bool get isDelivered => status == AppConstants.messageStatusDelivered;
  bool get isRead => status == AppConstants.messageStatusRead;

  /// Check if message is a reply
  bool get isReply => replyToMessageId != null;

  /// Get display text for deleted message
  String get displayText {
    if (isDeleted) return 'Message deleted';
    if (isTextMessage) return text ?? '';
    if (isImageMessage) return '📷 Photo';
    if (isFileMessage) return '📎 ${fileName ?? "File"}';
    if (isAudioMessage) return '🎵 Voice message';
    if (isLocationMessage) return '📍 Location';
    return text ?? '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MessageModel(id: $id, type: $type, senderId: $senderId)';
}
