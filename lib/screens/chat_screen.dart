import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _messageController.clear(); // مسح الحقل فوراً لتحسين الاستجابة

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });
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
          'text': 'Attachment',
          'imageUrl': url,
          'senderId': user?.uid,
          'type': 'image',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Upload error: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(l10n.noMessages)); // تأكد من إضافة noMessages في ملف الترجمة
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildBubble(data, data['senderId'] == currentUserId);
                  },
                );
              },
            ),
          ),
          _inputArea(l10n),
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
          borderRadius: BorderRadius.circular(15),
        ),
        child: data['type'] == 'image'
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(data['imageUrl'], width: 200),
              )
            : Text(data['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _inputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.attach_file, color: Colors.blue), onPressed: _sendImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(hintText: l10n.searchHint, border: InputBorder.none), // يمكنك استبداله بـ typeMessage
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }
}
