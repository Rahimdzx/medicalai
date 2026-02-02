import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference get _conversationsRef =>
      _firestore.collection('conversations');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== CONVERSATION METHODS ====================

  /// Get or create a conversation between two users
  Future<Conversation> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? currentUserName,
    String? currentUserPhotoUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Check for existing conversation
    final existingQuery = await _conversationsRef
        .where('participantIds', arrayContains: currentUser.uid)
        .get();

    for (var doc in existingQuery.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participantIds'] ?? []);
      if (participants.contains(otherUserId) && !data['isGroup']) {
        return Conversation.fromFirestore(doc);
      }
    }

    // Create new conversation
    final conversationId = _uuid.v4();
    final participantIds = [currentUser.uid, otherUserId];
    final participantNames = {
      currentUser.uid: currentUserName ?? currentUser.displayName ?? 'User',
      otherUserId: otherUserName,
    };
    final participantPhotos = {
      currentUser.uid: currentUserPhotoUrl ?? currentUser.photoURL,
      otherUserId: otherUserPhotoUrl,
    };

    final conversation = Conversation(
      id: conversationId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      createdAt: DateTime.now(),
      unreadCounts: {currentUser.uid: 0, otherUserId: 0},
      typing: {currentUser.uid: false, otherUserId: false},
    );

    await _conversationsRef.doc(conversationId).set(conversation.toFirestore());
    return conversation;
  }

  /// Stream conversations for current user
  Stream<List<Conversation>> streamConversations() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  /// Get conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _conversationsRef.doc(conversationId).get();
    if (!doc.exists) return null;
    return Conversation.fromFirestore(doc);
  }

  /// Stream single conversation
  Stream<Conversation?> streamConversation(String conversationId) {
    return _conversationsRef.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Conversation.fromFirestore(doc);
    });
  }

  // ==================== MESSAGE METHODS ====================

  /// Stream messages for a conversation
  Stream<List<Message>> streamMessages(String conversationId, {int limit = 50}) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// Load more messages (pagination)
  Future<List<Message>> loadMoreMessages(
    String conversationId, {
    required DateTime beforeTimestamp,
    int limit = 20,
  }) async {
    final snapshot = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .where('createdAt', isLessThan: Timestamp.fromDate(beforeTimestamp))
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
  }

  /// Send a text message
  Future<Message> sendTextMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    String? replyToContent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final messageId = _uuid.v4();
    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      senderPhotoUrl: user.photoURL,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      replyToId: replyToId,
      replyToContent: replyToContent,
    );

    // Save message
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toFirestore());

    // Update conversation
    await _updateConversationLastMessage(
      conversationId: conversationId,
      message: content,
      senderId: user.uid,
      type: MessageType.text,
    );

    // Update message status to sent
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.sent.name});

    // Send push notification
    await _sendMessageNotification(conversationId, content, user.displayName);

    return message.copyWith(status: MessageStatus.sent);
  }

  /// Send an image message with compression
  Future<Message> sendImageMessage({
    required String conversationId,
    required File imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final messageId = _uuid.v4();

    // Compress image
    final compressedFile = await _compressImage(imageFile);

    // Upload to Firebase Storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('chats/$conversationId/$fileName');
    final uploadTask = await storageRef.putFile(compressedFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      senderPhotoUrl: user.photoURL,
      content: 'Image',
      type: MessageType.image,
      imageUrl: imageUrl,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    // Save message
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toFirestore());

    // Update conversation
    await _updateConversationLastMessage(
      conversationId: conversationId,
      message: '📷 Image',
      senderId: user.uid,
      type: MessageType.image,
    );

    // Send push notification
    await _sendMessageNotification(
        conversationId, '📷 Sent an image', user.displayName);

    return message;
  }

  /// Send a file message
  Future<Message> sendFileMessage({
    required String conversationId,
    required File file,
    required String fileName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final messageId = _uuid.v4();
    final fileSize = await file.length();

    // Upload to Firebase Storage
    final storageFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storageRef =
        _storage.ref().child('chats/$conversationId/files/$storageFileName');
    final uploadTask = await storageRef.putFile(file);
    final fileUrl = await uploadTask.ref.getDownloadURL();

    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      senderPhotoUrl: user.photoURL,
      content: fileName,
      type: MessageType.file,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    // Save message
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toFirestore());

    // Update conversation
    await _updateConversationLastMessage(
      conversationId: conversationId,
      message: '📎 $fileName',
      senderId: user.uid,
      type: MessageType.file,
    );

    return message;
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true, 'content': 'Message deleted'});
  }

  // ==================== READ RECEIPTS ====================

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    final batch = _firestore.batch();

    // Get unread messages from other users
    final unreadMessages = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('status', isNotEqualTo: MessageStatus.read.name)
        .get();

    for (var doc in unreadMessages.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        batch.update(doc.reference, {
          'readBy': readBy,
          'status': MessageStatus.read.name,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Reset unread count for current user
    batch.update(_conversationsRef.doc(conversationId), {
      'unreadCounts.$userId': 0,
    });

    await batch.commit();
  }

  /// Mark single message as delivered
  Future<void> markMessageAsDelivered(
      String conversationId, String messageId) async {
    await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.delivered.name});
  }

  // ==================== TYPING INDICATOR ====================

  /// Set typing status
  Future<void> setTypingStatus(String conversationId, bool isTyping) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _conversationsRef.doc(conversationId).update({
      'typing.$userId': isTyping,
    });
  }

  /// Stream typing status
  Stream<Map<String, bool>> streamTypingStatus(String conversationId) {
    return _conversationsRef.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      return Map<String, bool>.from(data['typing'] ?? {});
    });
  }

  // ==================== HELPER METHODS ====================

  /// Update conversation's last message
  Future<void> _updateConversationLastMessage({
    required String conversationId,
    required String message,
    required String senderId,
    required MessageType type,
  }) async {
    // Get conversation to update unread counts
    final convDoc = await _conversationsRef.doc(conversationId).get();
    if (!convDoc.exists) return;

    final convData = convDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(convData['participantIds'] ?? []);
    final unreadCounts =
        Map<String, int>.from(convData['unreadCounts'] ?? {});

    // Increment unread count for all participants except sender
    for (var participantId in participants) {
      if (participantId != senderId) {
        unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
      }
    }

    await _conversationsRef.doc(conversationId).update({
      'lastMessage': message,
      'lastMessageSenderId': senderId,
      'lastMessageType': type.name,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    });
  }

  /// Compress image before upload
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return file;
    }
  }

  /// Send push notification for new message
  Future<void> _sendMessageNotification(
    String conversationId,
    String message,
    String? senderName,
  ) async {
    try {
      // Get conversation to find recipients
      final convDoc = await _conversationsRef.doc(conversationId).get();
      if (!convDoc.exists) return;

      final convData = convDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(convData['participantIds'] ?? []);
      final senderId = currentUserId;

      // Get FCM tokens for other participants
      for (var participantId in participants) {
        if (participantId != senderId) {
          final userDoc = await _usersRef.doc(participantId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final fcmToken = userData['fcmToken'];

            if (fcmToken != null) {
              // Add notification to queue for Cloud Functions to process
              await _firestore.collection('notifications').add({
                'token': fcmToken,
                'title': senderName ?? 'New Message',
                'body': message,
                'data': {
                  'type': 'chat',
                  'conversationId': conversationId,
                  'senderId': senderId,
                },
                'createdAt': FieldValue.serverTimestamp(),
                'sent': false,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  /// Get total unread count across all conversations
  Stream<int> streamTotalUnreadCount() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
        total += unreadCounts[userId] ?? 0;
      }
      return total;
    });
  }

  /// Search messages in conversation
  Future<List<Message>> searchMessages(
    String conversationId,
    String query,
  ) async {
    // Note: Full-text search requires Algolia or similar
    // This is a basic implementation
    final snapshot = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .where((msg) => msg.content.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Clear conversation (delete all messages)
  Future<void> clearConversation(String conversationId) async {
    final batch = _firestore.batch();
    final messages = await _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    batch.update(_conversationsRef.doc(conversationId), {
      'lastMessage': null,
      'lastMessageAt': null,
    });

    await batch.commit();
  }

  /// Leave/Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    // For 1-1 chats, we might just hide it for the user
    // For groups, we'd remove them from participants
    await _conversationsRef.doc(conversationId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
    });
  }
}
