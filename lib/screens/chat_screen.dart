import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String appointmentId;
  final String receiverName;

  const ChatScreen({super.key, required this.appointmentId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // دالة إرسال النص
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('messages') // سيتم إنشاؤها تلقائياً هنا
        .add({
      'text': _messageController.text.trim(),
      'senderId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });
    _messageController.clear();
  }

  // دالة إرسال صورة (تقرير طبي)
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      File file = File(image.path);
      String fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // رفع الصورة لـ Storage
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();

      final user = Provider.of<AuthProvider>(context, listen: false).user;
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .collection('messages')
          .add({
        'text': 'Sent a report / أرسل تقريراً',
        'imageUrl': url,
        'senderId': user?.uid,
        'type': 'image',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(widget.appointmentId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    bool isMe = docs[index]['senderId'] == currentUserId;
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: data['type'] == 'image' 
          ? Image.network(data['imageUrl'], width: 200) // عرض الصورة إذا كانت رسالة صورة
          : Text(data['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image), onPressed: _sendImage),
          Expanded(child: TextField(controller: _messageController)),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
