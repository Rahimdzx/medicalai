import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

/// Service for managing chat functionality
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference get _chatsRef => _firestore.collection(AppConstants.chatsCollection);
  CollectionReference _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection(AppConstants.messagesCollection);

  // ==================== Chat Management ====================

  /// Create or get existing chat between two users
  Future<ChatModel> getOrCreateChat({
    required UserModel currentUser,
    required UserModel otherUser,
    String? appointmentId,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _findExistingChat(currentUser.uid, otherUser.uid);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat
      final chatId = _uuid.v4();
      final now = DateTime.now();

      final chat = ChatModel(
        id: chatId,
        participantIds: [currentUser.uid, otherUser.uid],
        participants: {
          currentUser.uid: ChatParticipant(
            id: currentUser.uid,
            name: currentUser.name,
            photoUrl: currentUser.photoUrl,
            role: currentUser.role,
            isOnline: currentUser.isOnline,
            lastSeen: currentUser.lastSeen,
          ),
          otherUser.uid: ChatParticipant(
            id: otherUser.uid,
            name: otherUser.name,
            photoUrl: otherUser.photoUrl,
            role: otherUser.role,
            isOnline: otherUser.isOnline,
            lastSeen: otherUser.lastSeen,
          ),
        },
        unreadCount: {currentUser.uid: 0, otherUser.uid: 0},
        typing: {currentUser.uid: false, otherUser.uid: false},
        appointmentId: appointmentId,
        createdAt: now,
      );

      await _chatsRef.doc(chatId).set(chat.toMap());
      return chat;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    }
  }

  /// Find existing chat between two users
  Future<ChatModel?> _findExistingChat(String userId1, String userId2) async {
    final querySnapshot = await _chatsRef
        .where('participantIds', arrayContains: userId1)
        .get();

    for (var doc in querySnapshot.docs) {
      final chat = ChatModel.fromFirestore(doc);
      if (chat.participantIds.contains(userId2) && !chat.isGroup) {
        return chat;
      }
    }
    return null;
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _chatsRef.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  /// Stream user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsRef
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messages = await _messagesRef(chatId).get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
      // Delete chat document
      await _chatsRef.doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // ==================== Message Management ====================

  /// Send text message
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
    String? replyToMessageId,
    String? replyToText,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: AppConstants.messageTypeText,
        text: text,
        status: AppConstants.messageStatusSent,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        createdAt: now,
      );

      await _messagesRef(chatId).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      rethrow;
    }
  }

  /// Send image message
  Future<MessageModel> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? senderName,
    String? senderPhotoUrl,
    String? caption,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Upload image
      final fileName = 'chats/$chatId/${now.millisecondsSinceEpoch}_$messageId.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: AppConstants.messageTypeImage,
        text: caption,
        mediaUrl: imageUrl,
        status: AppConstants.messageStatusSent,
        createdAt: now,
      );

      await _messagesRef(chatId).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending image message: $e');
      rethrow;
    }
  }

  /// Send file message
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String senderId,
    required File file,
    required String fileName,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Upload file
      final storagePath = 'chats/$chatId/files/${now.millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();
      final fileSize = await file.length();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: AppConstants.messageTypeFile,
        text: fileName,
        mediaUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        status: AppConstants.messageStatusSent,
        createdAt: now,
      );

      await _messagesRef(chatId).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending file message: $e');
      rethrow;
    }
  }

  /// Send voice message
  Future<MessageModel> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required File audioFile,
    required int durationSeconds,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Upload audio
      final fileName = 'chats/$chatId/audio/${now.millisecondsSinceEpoch}_$messageId.m4a';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(audioFile);
      final audioUrl = await ref.getDownloadURL();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: AppConstants.messageTypeAudio,
        mediaUrl: audioUrl,
        audioDuration: durationSeconds,
        status: AppConstants.messageStatusSent,
        createdAt: now,
      );

      await _messagesRef(chatId).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending voice message: $e');
      rethrow;
    }
  }

  /// Send location message
  Future<MessageModel> sendLocationMessage({
    required String chatId,
    required String senderId,
    required double latitude,
    required double longitude,
    String? address,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: AppConstants.messageTypeLocation,
        latitude: latitude,
        longitude: longitude,
        locationAddress: address,
        status: AppConstants.messageStatusSent,
        createdAt: now,
      );

      await _messagesRef(chatId).doc(messageId).set(message.toMap());
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      debugPrint('Error sending location message: $e');
      rethrow;
    }
  }

  /// Stream messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc, chatId: chatId))
          .toList();
    });
  }

  /// Get paginated messages
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    DocumentSnapshot? lastDocument,
    int limit = 50,
  }) async {
    Query query = _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc, chatId: chatId))
        .toList();
  }

  /// Delete message (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesRef(chatId).doc(messageId).update({
        'isDeleted': true,
        'text': null,
        'mediaUrl': null,
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    try {
      final Map<String, dynamic> updateData = {'status': status};
      if (status == AppConstants.messageStatusRead) {
        updateData['readAt'] = Timestamp.now();
      }
      await _messagesRef(chatId).doc(messageId).update(updateData);
    } catch (e) {
      debugPrint('Error updating message status: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Update unread messages
      final unreadMessages = await _messagesRef(chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('status', isNotEqualTo: AppConstants.messageStatusRead)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': AppConstants.messageStatusRead,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();

      // Reset unread count
      await _chatsRef.doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // ==================== Typing Indicators ====================

  /// Set typing status
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    try {
      await _chatsRef.doc(chatId).update({
        'typing.$userId': isTyping,
      });
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  /// Stream typing status
  Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _chatsRef.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>?;
      return Map<String, bool>.from(data?['typing'] ?? {});
    });
  }

  // ==================== Private Helpers ====================

  /// Update chat with last message info
  Future<void> _updateChatLastMessage(String chatId, MessageModel message) async {
    try {
      // Get current chat to update unread counts
      final chatDoc = await _chatsRef.doc(chatId).get();
      final chatData = chatDoc.data() as Map<String, dynamic>?;
      final currentUnreadCount = Map<String, int>.from(chatData?['unreadCount'] ?? {});

      // Increment unread count for other participants
      final participantIds = List<String>.from(chatData?['participantIds'] ?? []);
      for (var participantId in participantIds) {
        if (participantId != message.senderId) {
          currentUnreadCount[participantId] = (currentUnreadCount[participantId] ?? 0) + 1;
        }
      }

      await _chatsRef.doc(chatId).update({
        'lastMessageText': message.displayText,
        'lastMessageType': message.type,
        'lastMessageSenderId': message.senderId,
        'lastMessageTime': Timestamp.fromDate(message.createdAt),
        'unreadCount': currentUnreadCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
    }
  }

  /// Get total unread count for user
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final chats = await _chatsRef
          .where('participantIds', arrayContains: userId)
          .get();

      int total = 0;
      for (var doc in chats.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        total += (unreadCount?[userId] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }

  /// Stream total unread count
  Stream<int> streamTotalUnreadCount(String userId) {
    return _chatsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        total += (unreadCount?[userId] as int?) ?? 0;
      }
      return total;
    });
  }
}
