// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get senderName => throw _privateConstructorUsedError;
  String? get senderPhotoUrl => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  MessageType get type => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get fileUrl => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  MessageStatus get status => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get readAt => throw _privateConstructorUsedError;
  List<String> get readBy => throw _privateConstructorUsedError;
  String? get replyToId => throw _privateConstructorUsedError;
  String? get replyToContent => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    String id,
    String conversationId,
    String senderId,
    String senderName,
    String? senderPhotoUrl,
    String content,
    MessageType type,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    MessageStatus status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? readAt,
    List<String> readBy,
    String? replyToId,
    String? replyToContent,
    bool isDeleted,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? senderPhotoUrl = freezed,
    Object? content = null,
    Object? type = null,
    Object? imageUrl = freezed,
    Object? fileUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? readAt = freezed,
    Object? readBy = null,
    Object? replyToId = freezed,
    Object? replyToContent = freezed,
    Object? isDeleted = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName as String,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl as String?,
      content: null == content
          ? _value.content
          : content as String,
      type: null == type
          ? _value.type
          : type as MessageType,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl as String?,
      fileUrl: freezed == fileUrl
          ? _value.fileUrl
          : fileUrl as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize as int?,
      status: null == status
          ? _value.status
          : status as MessageStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt as DateTime?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt as DateTime?,
      readBy: null == readBy
          ? _value.readBy
          : readBy as List<String>,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId as String?,
      replyToContent: freezed == replyToContent
          ? _value.replyToContent
          : replyToContent as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted as bool,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String conversationId,
    String senderId,
    String senderName,
    String? senderPhotoUrl,
    String content,
    MessageType type,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    MessageStatus status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? readAt,
    List<String> readBy,
    String? replyToId,
    String? replyToContent,
    bool isDeleted,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? senderPhotoUrl = freezed,
    Object? content = null,
    Object? type = null,
    Object? imageUrl = freezed,
    Object? fileUrl = freezed,
    Object? fileName = freezed,
    Object? fileSize = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? readAt = freezed,
    Object? readBy = null,
    Object? replyToId = freezed,
    Object? replyToContent = freezed,
    Object? isDeleted = null,
    Object? metadata = freezed,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName as String,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl as String?,
      content: null == content
          ? _value.content
          : content as String,
      type: null == type
          ? _value.type
          : type as MessageType,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl as String?,
      fileUrl: freezed == fileUrl
          ? _value.fileUrl
          : fileUrl as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize as int?,
      status: null == status
          ? _value.status
          : status as MessageStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt as DateTime?,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt as DateTime?,
      readBy: null == readBy
          ? _value._readBy
          : readBy as List<String>,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId as String?,
      replyToContent: freezed == replyToContent
          ? _value.replyToContent
          : replyToContent as String?,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted as bool,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl extends _Message {
  const _$MessageImpl({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.status = MessageStatus.sending,
    @TimestampConverter() this.createdAt,
    @TimestampConverter() this.readAt,
    final List<String> readBy = const [],
    this.replyToId,
    this.replyToContent,
    this.isDeleted = false,
    final Map<String, dynamic>? metadata,
  })  : _readBy = readBy,
        _metadata = metadata,
        super._();

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String senderId;
  @override
  final String senderName;
  @override
  final String? senderPhotoUrl;
  @override
  final String content;
  @override
  @JsonKey()
  final MessageType type;
  @override
  final String? imageUrl;
  @override
  final String? fileUrl;
  @override
  final String? fileName;
  @override
  final int? fileSize;
  @override
  @JsonKey()
  final MessageStatus status;
  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @TimestampConverter()
  final DateTime? readAt;
  final List<String> _readBy;
  @override
  @JsonKey()
  List<String> get readBy {
    if (_readBy is EqualUnmodifiableListView) return _readBy;
    return EqualUnmodifiableListView(_readBy);
  }

  @override
  final String? replyToId;
  @override
  final String? replyToContent;
  @override
  @JsonKey()
  final bool isDeleted;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, content: $content, type: $type, imageUrl: $imageUrl, fileUrl: $fileUrl, fileName: $fileName, fileSize: $fileSize, status: $status, createdAt: $createdAt, readAt: $readAt, readBy: $readBy, replyToId: $replyToId, replyToContent: $replyToContent, isDeleted: $isDeleted, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderPhotoUrl, senderPhotoUrl) ||
                other.senderPhotoUrl == senderPhotoUrl) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            const DeepCollectionEquality().equals(other._readBy, _readBy) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.replyToContent, replyToContent) ||
                other.replyToContent == replyToContent) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        conversationId,
        senderId,
        senderName,
        senderPhotoUrl,
        content,
        type,
        imageUrl,
        fileUrl,
        fileName,
        fileSize,
        status,
        createdAt,
        readAt,
        const DeepCollectionEquality().hash(_readBy),
        replyToId,
        replyToContent,
        isDeleted,
        const DeepCollectionEquality().hash(_metadata),
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(this);
  }
}

abstract class _Message extends Message {
  const factory _Message({
    required final String id,
    required final String conversationId,
    required final String senderId,
    required final String senderName,
    final String? senderPhotoUrl,
    required final String content,
    final MessageType type,
    final String? imageUrl,
    final String? fileUrl,
    final String? fileName,
    final int? fileSize,
    final MessageStatus status,
    @TimestampConverter() final DateTime? createdAt,
    @TimestampConverter() final DateTime? readAt,
    final List<String> readBy,
    final String? replyToId,
    final String? replyToContent,
    final bool isDeleted,
    final Map<String, dynamic>? metadata,
  }) = _$MessageImpl;
  const _Message._() : super._();

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  String get id;
  @override
  String get conversationId;
  @override
  String get senderId;
  @override
  String get senderName;
  @override
  String? get senderPhotoUrl;
  @override
  String get content;
  @override
  MessageType get type;
  @override
  String? get imageUrl;
  @override
  String? get fileUrl;
  @override
  String? get fileName;
  @override
  int? get fileSize;
  @override
  MessageStatus get status;
  @override
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @TimestampConverter()
  DateTime? get readAt;
  @override
  List<String> get readBy;
  @override
  String? get replyToId;
  @override
  String? get replyToContent;
  @override
  bool get isDeleted;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  String get id => throw _privateConstructorUsedError;
  List<String> get participantIds => throw _privateConstructorUsedError;
  Map<String, String> get participantNames => throw _privateConstructorUsedError;
  Map<String, String?>? get participantPhotos =>
      throw _privateConstructorUsedError;
  String? get lastMessage => throw _privateConstructorUsedError;
  String? get lastMessageSenderId => throw _privateConstructorUsedError;
  MessageType get lastMessageType => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  Map<String, int> get unreadCounts => throw _privateConstructorUsedError;
  Map<String, bool> get typing => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  bool get isGroup => throw _privateConstructorUsedError;
  String? get groupName => throw _privateConstructorUsedError;
  String? get groupPhotoUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call({
    String id,
    List<String> participantIds,
    Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    MessageType lastMessageType,
    @TimestampConverter() DateTime? lastMessageAt,
    Map<String, int> unreadCounts,
    Map<String, bool> typing,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    bool isGroup,
    String? groupName,
    String? groupPhotoUrl,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? participantNames = null,
    Object? participantPhotos = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageType = null,
    Object? lastMessageAt = freezed,
    Object? unreadCounts = null,
    Object? typing = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isGroup = null,
    Object? groupName = freezed,
    Object? groupPhotoUrl = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id ? _value.id : id as String,
      participantIds: null == participantIds
          ? _value.participantIds
          : participantIds as List<String>,
      participantNames: null == participantNames
          ? _value.participantNames
          : participantNames as Map<String, String>,
      participantPhotos: freezed == participantPhotos
          ? _value.participantPhotos
          : participantPhotos as Map<String, String?>?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage as String?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId as String?,
      lastMessageType: null == lastMessageType
          ? _value.lastMessageType
          : lastMessageType as MessageType,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt as DateTime?,
      unreadCounts: null == unreadCounts
          ? _value.unreadCounts
          : unreadCounts as Map<String, int>,
      typing: null == typing ? _value.typing : typing as Map<String, bool>,
      createdAt: freezed == createdAt ? _value.createdAt : createdAt as DateTime?,
      updatedAt: freezed == updatedAt ? _value.updatedAt : updatedAt as DateTime?,
      isGroup: null == isGroup ? _value.isGroup : isGroup as bool,
      groupName: freezed == groupName ? _value.groupName : groupName as String?,
      groupPhotoUrl: freezed == groupPhotoUrl
          ? _value.groupPhotoUrl
          : groupPhotoUrl as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    List<String> participantIds,
    Map<String, String> participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    MessageType lastMessageType,
    @TimestampConverter() DateTime? lastMessageAt,
    Map<String, int> unreadCounts,
    Map<String, bool> typing,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    bool isGroup,
    String? groupName,
    String? groupPhotoUrl,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? participantNames = null,
    Object? participantPhotos = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageType = null,
    Object? lastMessageAt = freezed,
    Object? unreadCounts = null,
    Object? typing = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? isGroup = null,
    Object? groupName = freezed,
    Object? groupPhotoUrl = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$ConversationImpl(
      id: null == id ? _value.id : id as String,
      participantIds: null == participantIds
          ? _value._participantIds
          : participantIds as List<String>,
      participantNames: null == participantNames
          ? _value._participantNames
          : participantNames as Map<String, String>,
      participantPhotos: freezed == participantPhotos
          ? _value._participantPhotos
          : participantPhotos as Map<String, String?>?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage as String?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId as String?,
      lastMessageType: null == lastMessageType
          ? _value.lastMessageType
          : lastMessageType as MessageType,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt as DateTime?,
      unreadCounts: null == unreadCounts
          ? _value._unreadCounts
          : unreadCounts as Map<String, int>,
      typing: null == typing ? _value._typing : typing as Map<String, bool>,
      createdAt: freezed == createdAt ? _value.createdAt : createdAt as DateTime?,
      updatedAt: freezed == updatedAt ? _value.updatedAt : updatedAt as DateTime?,
      isGroup: null == isGroup ? _value.isGroup : isGroup as bool,
      groupName: freezed == groupName ? _value.groupName : groupName as String?,
      groupPhotoUrl: freezed == groupPhotoUrl
          ? _value.groupPhotoUrl
          : groupPhotoUrl as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl extends _Conversation {
  const _$ConversationImpl({
    required this.id,
    required final List<String> participantIds,
    required final Map<String, String> participantNames,
    final Map<String, String?>? participantPhotos,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageType = MessageType.text,
    @TimestampConverter() this.lastMessageAt,
    final Map<String, int> unreadCounts = const {},
    final Map<String, bool> typing = const {},
    @TimestampConverter() this.createdAt,
    @TimestampConverter() this.updatedAt,
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    final Map<String, dynamic>? metadata,
  })  : _participantIds = participantIds,
        _participantNames = participantNames,
        _participantPhotos = participantPhotos,
        _unreadCounts = unreadCounts,
        _typing = typing,
        _metadata = metadata,
        super._();

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  @override
  final String id;
  final List<String> _participantIds;
  @override
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    return EqualUnmodifiableListView(_participantIds);
  }

  final Map<String, String> _participantNames;
  @override
  Map<String, String> get participantNames {
    if (_participantNames is EqualUnmodifiableMapView) return _participantNames;
    return EqualUnmodifiableMapView(_participantNames);
  }

  final Map<String, String?>? _participantPhotos;
  @override
  Map<String, String?>? get participantPhotos {
    final value = _participantPhotos;
    if (value == null) return null;
    if (_participantPhotos is EqualUnmodifiableMapView) return _participantPhotos;
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? lastMessage;
  @override
  final String? lastMessageSenderId;
  @override
  @JsonKey()
  final MessageType lastMessageType;
  @override
  @TimestampConverter()
  final DateTime? lastMessageAt;
  final Map<String, int> _unreadCounts;
  @override
  @JsonKey()
  Map<String, int> get unreadCounts {
    if (_unreadCounts is EqualUnmodifiableMapView) return _unreadCounts;
    return EqualUnmodifiableMapView(_unreadCounts);
  }

  final Map<String, bool> _typing;
  @override
  @JsonKey()
  Map<String, bool> get typing {
    if (_typing is EqualUnmodifiableMapView) return _typing;
    return EqualUnmodifiableMapView(_typing);
  }

  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final bool isGroup;
  @override
  final String? groupName;
  @override
  final String? groupPhotoUrl;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Conversation(id: $id, participantIds: $participantIds, participantNames: $participantNames, participantPhotos: $participantPhotos, lastMessage: $lastMessage, lastMessageSenderId: $lastMessageSenderId, lastMessageType: $lastMessageType, lastMessageAt: $lastMessageAt, unreadCounts: $unreadCounts, typing: $typing, createdAt: $createdAt, updatedAt: $updatedAt, isGroup: $isGroup, groupName: $groupName, groupPhotoUrl: $groupPhotoUrl, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds) &&
            const DeepCollectionEquality()
                .equals(other._participantNames, _participantNames) &&
            const DeepCollectionEquality()
                .equals(other._participantPhotos, _participantPhotos) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            (identical(other.lastMessageType, lastMessageType) ||
                other.lastMessageType == lastMessageType) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            const DeepCollectionEquality()
                .equals(other._unreadCounts, _unreadCounts) &&
            const DeepCollectionEquality().equals(other._typing, _typing) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isGroup, isGroup) || other.isGroup == isGroup) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.groupPhotoUrl, groupPhotoUrl) ||
                other.groupPhotoUrl == groupPhotoUrl) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        const DeepCollectionEquality().hash(_participantIds),
        const DeepCollectionEquality().hash(_participantNames),
        const DeepCollectionEquality().hash(_participantPhotos),
        lastMessage,
        lastMessageSenderId,
        lastMessageType,
        lastMessageAt,
        const DeepCollectionEquality().hash(_unreadCounts),
        const DeepCollectionEquality().hash(_typing),
        createdAt,
        updatedAt,
        isGroup,
        groupName,
        groupPhotoUrl,
        const DeepCollectionEquality().hash(_metadata),
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(this);
  }
}

abstract class _Conversation extends Conversation {
  const factory _Conversation({
    required final String id,
    required final List<String> participantIds,
    required final Map<String, String> participantNames,
    final Map<String, String?>? participantPhotos,
    final String? lastMessage,
    final String? lastMessageSenderId,
    final MessageType lastMessageType,
    @TimestampConverter() final DateTime? lastMessageAt,
    final Map<String, int> unreadCounts,
    final Map<String, bool> typing,
    @TimestampConverter() final DateTime? createdAt,
    @TimestampConverter() final DateTime? updatedAt,
    final bool isGroup,
    final String? groupName,
    final String? groupPhotoUrl,
    final Map<String, dynamic>? metadata,
  }) = _$ConversationImpl;
  const _Conversation._() : super._();

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override
  String get id;
  @override
  List<String> get participantIds;
  @override
  Map<String, String> get participantNames;
  @override
  Map<String, String?>? get participantPhotos;
  @override
  String? get lastMessage;
  @override
  String? get lastMessageSenderId;
  @override
  MessageType get lastMessageType;
  @override
  @TimestampConverter()
  DateTime? get lastMessageAt;
  @override
  Map<String, int> get unreadCounts;
  @override
  Map<String, bool> get typing;
  @override
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  bool get isGroup;
  @override
  String? get groupName;
  @override
  String? get groupPhotoUrl;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
