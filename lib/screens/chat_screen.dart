import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String appointmentId;
  final bool isRadiology;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.appointmentId,
    this.isRadiology = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    
    for (var msg in messages.docs) {
      await msg.reference.update({'read': true});
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': user?.uid,
      'senderRole': 'patient',
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String ext = result.files.single.extension ?? 'file';

      setState(() => _isUploading = true);

      try {
        UploadTask task = FirebaseStorage.instance
            .ref('chats/${widget.chatId}/$fileName')
            .putFile(file);

        task.snapshotEvents.listen((snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        TaskSnapshot snapshot = await task;
        String url = await snapshot.ref.getDownloadURL();

        final user = Provider.of<AuthProvider>(context, listen: false).user;
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': 'Attachment',
          'fileUrl': url,
          'fileName': fileName,
          'fileType': ext,
          'senderId': user?.uid,
          'type': 'file',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
          'lastMessage': '📎 File',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Radiology Instructions
          if (widget.isRadiology && _showInstructions)
            Container(
              color: Colors.blue.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.radiologyInstructions,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _showInstructions = false),
                  ),
                ],
              ),
            ),
          
          // Upload Progress
          if (_isUploading)
            LinearProgressIndicator(value: _uploadProgress),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final isSystem = data['senderRole'] == 'system';

                    if (isSystem) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['text'] ?? '',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: data['type'] == 'file'
                            ? _buildFileWidget(data, isMe)
                            : _buildTextWithLinks(data['text'] ?? '', isMe),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _uploadFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileWidget(Map<String, dynamic> data, bool isMe) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(data['fileUrl'])),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          Text(
            data['fileName'] ?? 'File',
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTextWithLinks(String text, bool isMe) {
    final urlRegExp = RegExp(r'https?://[^\s]+');
    final matches = urlRegExp.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black));
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ));
      }
      
      final url = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: isMe ? Colors.lightBlueAccent : Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url)),
      ));
      
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
