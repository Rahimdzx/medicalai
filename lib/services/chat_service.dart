import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadFile(String chatId, File file, String fileName) async {
    final ref = _storage.ref().child('chats/$chatId/$fileName');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': 'Attachment',
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'type': 'file',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '📎 File',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    
    for (var msg in messages.docs) {
      await msg.reference.update({'read': true});
    }
  }
}
