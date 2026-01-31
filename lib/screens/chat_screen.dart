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
  bool _isUploading = false;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('messages')
        .add({
      'text': _messageController.text.trim(),
      'senderId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        File file = File(image.path);
        String fileName = 'chats/${widget.appointmentId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref().child(fileName).putFile(file);
        String url = await snapshot.ref.getDownloadURL();

        final user = Provider.of<AuthProvider>(context, listen: false).user;
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .collection('messages')
            .add({
          'text': 'صورة/تقرير طبي',
          'imageUrl': url,
          'senderId': user?.uid,
          'type': 'image',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error uploading image: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName), centerTitle: true),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(widget.appointmentId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد رسائل بعد.. ابدأ المحادثة"));
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: data['type'] == 'image'
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['imageUrl'],
                  width: 200,
                  // تم استبدال placeholder بـ loadingBuilder لحل مشكلة الخطأ
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              )
            : Text(
                data['text'] ?? '',
                style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
              ),
      ),
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.attach_file, color: Colors.blue), onPressed: _sendImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: "اكتب رسالتك هنا...", border: InputBorder.none),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
