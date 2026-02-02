// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      content: json['content'] as String,
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.sending,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      readAt: const TimestampConverter().fromJson(json['readAt']),
      readBy: (json['readBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      replyToId: json['replyToId'] as String?,
      replyToContent: json['replyToContent'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'imageUrl': instance.imageUrl,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'readAt': const TimestampConverter().toJson(instance.readAt),
      'readBy': instance.readBy,
      'replyToId': instance.replyToId,
      'replyToContent': instance.replyToContent,
      'isDeleted': instance.isDeleted,
      'metadata': instance.metadata,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.file: 'file',
  MessageType.voice: 'voice',
  MessageType.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      participantNames:
          Map<String, String>.from(json['participantNames'] as Map),
      participantPhotos: (json['participantPhotos'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, e as String?)),
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageType:
          $enumDecodeNullable(_$MessageTypeEnumMap, json['lastMessageType']) ??
              MessageType.text,
      lastMessageAt:
          const TimestampConverter().fromJson(json['lastMessageAt']),
      unreadCounts: (json['unreadCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as int),
          ) ??
          const {},
      typing: (json['typing'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String?,
      groupPhotoUrl: json['groupPhotoUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantIds': instance.participantIds,
      'participantNames': instance.participantNames,
      'participantPhotos': instance.participantPhotos,
      'lastMessage': instance.lastMessage,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessageType': _$MessageTypeEnumMap[instance.lastMessageType]!,
      'lastMessageAt':
          const TimestampConverter().toJson(instance.lastMessageAt),
      'unreadCounts': instance.unreadCounts,
      'typing': instance.typing,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'isGroup': instance.isGroup,
      'groupName': instance.groupName,
      'groupPhotoUrl': instance.groupPhotoUrl,
      'metadata': instance.metadata,
    };
