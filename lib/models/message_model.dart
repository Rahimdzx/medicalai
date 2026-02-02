import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

/// Message types enum
enum MessageType {
  text,
  image,
  file,
  voice,
  system,
}

/// Message status enum for read receipts
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Timestamp converter for Firestore
class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}

/// Message model with freezed
@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    @Default(MessageType.text) MessageType type,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    @Default(MessageStatus.sending) MessageStatus status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? readAt,
    @Default([]) List<String> readBy,
    String? replyToId,
    String? replyToContent,
    @Default(false) bool isDeleted,
    Map<String, dynamic>? metadata,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  /// Create message from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      readBy: List<String>.from(data['readBy'] ?? []),
      replyToId: data['replyToId'],
      replyToContent: data['replyToContent'],
      isDeleted: data['isDeleted'] ?? false,
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'readBy': readBy,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'isDeleted': isDeleted,
      'metadata': metadata,
    };
  }

  /// Check if message is from current user
  bool isFromUser(String userId) => senderId == userId;

  /// Check if message has been read by user
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Get formatted time
  String get formattedTime {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt!);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      return '${createdAt!.hour.toString().padLeft(2, '0')}:${createdAt!.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}

/// Conversation model
@freezed
class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    @Default(MessageType.text) MessageType lastMessageType,
    @TimestampConverter() DateTime? lastMessageAt,
    @Default({}) Map<String, int> unreadCounts,
    @Default({}) Map<String, bool> typing,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    @Default(false) bool isGroup,
    String? groupName,
    String? groupPhotoUrl,
    Map<String, dynamic>? metadata,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  /// Create conversation from Firestore document
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: data['participantPhotos'] != null
          ? Map<String, String?>.from(data['participantPhotos'])
          : null,
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageType: MessageType.values.firstWhere(
        (e) => e.name == (data['lastMessageType'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupPhotoUrl: data['groupPhotoUrl'],
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageType': lastMessageType.name,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
      'typing': typing,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'metadata': metadata,
    };
  }

  /// Get the other participant's name (for 1-1 chats)
  String getOtherParticipantName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group';
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Get the other participant's photo (for 1-1 chats)
  String? getOtherParticipantPhoto(String currentUserId) {
    if (isGroup) return groupPhotoUrl;
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
    return participantPhotos?[otherId];
  }

  /// Get unread count for user
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  /// Check if someone is typing
  bool isTyping(String exceptUserId) {
    return typing.entries.any((e) => e.key != exceptUserId && e.value);
  }

  /// Get formatted last message time
  String get formattedLastMessageTime {
    if (lastMessageAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${lastMessageAt!.hour.toString().padLeft(2, '0')}:${lastMessageAt!.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${lastMessageAt!.day}/${lastMessageAt!.month}';
  }
}
