import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String appointmentId;
  final bool isRadiology;
  final String? receiverId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.appointmentId,
    this.isRadiology = false,
    this.receiverId,
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
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Initialize chat by ensuring the chat document exists
  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isInitializing = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.uid;

      if (currentUserId == null) {
        setState(() {
          _error = 'Not authenticated';
          _isInitializing = false;
        });
        return;
      }

      // Check if chat document exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) {
        // Create the chat document
        final receiverId = widget.receiverId ?? widget.appointmentId;
        final participants = [currentUserId, receiverId]..sort();

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'patientId': authProvider.userRole == 'patient' ? currentUserId : receiverId,
          'doctorId': authProvider.userRole == 'doctor' ? currentUserId : receiverId,
        });
      }

      // Mark messages as read
      _markMessagesAsRead();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize chat: $e';
        _isInitializing = false;
      });
    }
  }

  void _markMessagesAsRead() async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId == null) return;

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
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final userRole = authProvider.userRole ?? 'patient';
    
    _messageController.clear();

    try {
      // Ensure chat document exists before sending
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) {
        // Create chat document
        final receiverId = widget.receiverId ?? widget.appointmentId;
        final participants = [user?.uid, receiverId]..sort();

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      // Send the message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user?.uid,
        'senderRole': userRole,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat metadata
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String ext = result.files.single.extension ?? 'file';

      // Validate file size (50MB max)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 50MB')),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        final userRole = authProvider.userRole ?? 'patient';

        // Create storage reference with metadata
        final ref = FirebaseStorage.instance
            .ref('chats/${widget.chatId}/$fileName');
        
        final metadata = SettableMetadata(
          contentType: _getContentType(ext),
          customMetadata: {
            'uploadedBy': user?.uid ?? 'unknown',
            'uploadedAt': DateTime.now().toIso8601String(),
            'chatId': widget.chatId,
          },
        );

        UploadTask task = ref.putFile(file, metadata);

        task.snapshotEvents.listen((snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        TaskSnapshot snapshot = await task;
        String url = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'text': 'Attachment',
          'fileUrl': url,
          'fileName': fileName,
          'fileType': ext,
          'fileSize': fileSize,
          'senderId': user?.uid,
          'senderRole': userRole,
          'type': 'file',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '📎 File: $fileName',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          String errorMessage = 'Upload failed';
          if (e.code == 'permission-denied') {
            errorMessage = 'Permission denied. Please check storage permissions.';
          } else if (e.code == 'unauthenticated') {
            errorMessage = 'Please sign in again to upload files.';
          } else if (e.code == 'object-not-found') {
            errorMessage = 'Storage path not found.';
          } else {
            errorMessage = 'Upload failed: ${e.message}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    // Show initialization loading
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.receiverName)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing chat...'),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.receiverName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeChat,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            const Text('Online',
                style: TextStyle(fontSize: 12, color: Colors.green)),
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
                      l10n.radiologyInstructions ?? 'Share your medical images and reports with the doctor',
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
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),

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
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Handle errors
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load messages',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Handle empty state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final isSystem = data['senderRole'] == 'system';
                    final timestamp = data['timestamp'] as Timestamp?;

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
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            data['type'] == 'file'
                                ? _buildFileWidget(data, isMe)
                                : _buildTextWithLinks(data['text'] ?? '', isMe),
                            if (timestamp != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
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
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
              ],
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
                        hintText: l10n.typeMessage ?? 'Type a message...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
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
      onTap: () async {
        final url = data['fileUrl'];
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file,
              color: isMe ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              data['fileName'] ?? 'File',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextWithLinks(String text, bool isMe) {
    final urlRegExp = RegExp(r'https?://[^\s]+');
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black));
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
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
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

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
