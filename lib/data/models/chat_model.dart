import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

/// Chat model representing a conversation between users
class ChatModel {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatParticipant> participants;
  final String? lastMessageText;
  final String? lastMessageType;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // userId -> count
  final Map<String, bool> typing; // userId -> isTyping
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;
  final String? appointmentId; // Link to appointment if exists
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessageText,
    this.lastMessageType,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.typing = const {},
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    this.appointmentId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create ChatModel from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse participants
    final participantsData = data['participants'] as Map<String, dynamic>? ?? {};
    final participants = participantsData.map(
      (key, value) => MapEntry(key, ChatParticipant.fromMap(value as Map<String, dynamic>)),
    );

    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: participants,
      lastMessageText: data['lastMessageText'],
      lastMessageType: data['lastMessageType'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupPhotoUrl: data['groupPhotoUrl'],
      appointmentId: data['appointmentId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create ChatModel from Map
  factory ChatModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final participantsData = map['participants'] as Map<String, dynamic>? ?? {};
    final participants = participantsData.map(
      (key, value) => MapEntry(key, ChatParticipant.fromMap(value as Map<String, dynamic>)),
    );

    return ChatModel(
      id: id ?? map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participants: participants,
      lastMessageText: map['lastMessageText'],
      lastMessageType: map['lastMessageType'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : map['lastMessageTime'] as DateTime?,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      typing: Map<String, bool>.from(map['typing'] ?? {}),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupPhotoUrl: map['groupPhotoUrl'],
      appointmentId: map['appointmentId'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime? ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] as DateTime?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert ChatModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'lastMessageText': lastMessageText,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'typing': typing,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'appointmentId': appointmentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Copy with updated fields
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, ChatParticipant>? participants,
    String? lastMessageText,
    String? lastMessageType,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, bool>? typing,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
    String? appointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      typing: typing ?? this.typing,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get other participant for 1-to-1 chat
  ChatParticipant? getOtherParticipant(String currentUserId) {
    if (isGroup) return null;
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participants[otherId];
  }

  /// Get unread count for a user
  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  /// Check if user is typing
  bool isUserTyping(String userId) => typing[userId] ?? false;

  /// Get display name for chat
  String getDisplayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group Chat';
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.name ?? 'Unknown';
  }

  /// Get display photo for chat
  String? getDisplayPhoto(String currentUserId) {
    if (isGroup) return groupPhotoUrl;
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.photoUrl;
  }

  /// Update last message from MessageModel
  ChatModel updateLastMessage(MessageModel message) {
    return copyWith(
      lastMessageText: message.displayText,
      lastMessageType: message.type,
      lastMessageSenderId: message.senderId,
      lastMessageTime: message.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatModel(id: $id, participants: ${participantIds.length})';
}

/// Model for chat participant
class ChatParticipant {
  final String id;
  final String name;
  final String? photoUrl;
  final String? role;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.photoUrl,
    this.role,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] is Timestamp
          ? (map['lastSeen'] as Timestamp).toDate()
          : map['lastSeen'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  /// Get initials from name
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
