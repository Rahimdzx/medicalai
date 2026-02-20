import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class ChatScreen extends StatefulWidget {
  final String appointmentId;
  final String receiverName;
  final String chatId;
  final bool isRadiology; // Flag for radiology instructions

  const ChatScreen({
    super.key, 
    required this.appointmentId, 
    required this.receiverName,
    required this.chatId,
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
  Map<String, dynamic>? _radiologyInstructions;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _loadRadiologyInstructions();
    _markMessagesAsRead();
  }

  Future<void> _loadRadiologyInstructions() async {
    if (!widget.isRadiology) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('specialInstructions')
        .where('doctorSpecialty', isEqualTo: 'Radiology')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
        
    if (doc.docs.isNotEmpty) {
      setState(() {
        _radiologyInstructions = doc.docs.first.data();
      });
    }
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
    final userRole = Provider.of<AuthProvider>(context, listen: false).userRole;
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': user?.uid,
      'senderRole': userRole ?? 'patient',
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Update last message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    
    if (image != null) {
      await _uploadFile(File(image.path), 'image', 'jpg');
    }
  }

  Future<void> _sendDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'dcm', 'jpg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String ext = result.files.single.extension ?? 'file';
      await _uploadFile(file, 'document', ext);
    }
  }

  Future<void> _uploadFile(File file, String fileType, String extension) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      String path = 'chats/${widget.chatId}/$fileName';
      
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(path).putFile(
        file,
        SettableMetadata(
          contentType: fileType == 'image' ? 'image/jpeg' : 'application/$extension',
        ),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      int fileSize = await file.length();

      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final userRole = Provider.of<AuthProvider>(context, listen: false).userRole;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': 'Attachment',
        'fileUrl': url,
        'fileType': fileType,
        'fileName': fileName,
        'fileSize': fileSize,
        'senderId': user?.uid,
        'senderRole': userRole ?? 'patient',
        'type': 'file',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': '📎 File',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploaded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.uploadFailed}: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: () => _uploadFile(file, fileType, extension),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isRTL = localeProvider.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.receiverName),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.chatId.split('_').last) // Assuming doctor ID is in chatId
                  .snapshots(),
              builder: (context, snapshot) {
                bool isOnline = snapshot.data?['isOnline'] ?? false;
                return Text(
                  isOnline ? l10n.online : l10n.offline,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Radiology Instructions Banner
          if (widget.isRadiology && _radiologyInstructions != null && _showInstructions)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            _getLocalizedText(_radiologyInstructions!, 'title', localeProvider.locale.languageCode),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _showInstructions = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLocalizedText(_radiologyInstructions!, 'content', localeProvider.locale.languageCode),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),

          // Upload Progress
          if (_isUploading)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(l10n.noMessages));
                }

                var docs = snapshot.data!.docs;
                
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    bool isSystem = data['senderRole'] == 'system';
                    
                    if (isSystem) {
                      return _buildSystemMessage(data, l10n);
                    }
                    
                    return _buildMessageBubble(data, isMe, isRTL, l10n);
                  },
                );
              },
            ),
          ),

          _buildInputArea(l10n, isRTL),
        ],
      ),
    );
  }

  String _getLocalizedText(Map<String, dynamic> data, String key, String locale) {
    final localizedKey = '${key}_$locale';
    return data[localizedKey] ?? data['${key}_en'] ?? '';
  }

  Widget _buildSystemMessage(Map<String, dynamic> data, AppLocalizations l10n) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          data['text'] ?? '',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe, bool isRTL, AppLocalizations l10n) {
    final bool isFile = data['type'] == 'file';
    final bool read = data['read'] ?? false;

    return Align(
      alignment: isMe 
          ? (isRTL ? Alignment.centerLeft : Alignment.centerRight)
          : (isRTL ? Alignment.centerRight : Alignment.centerLeft),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: isFile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFile)
              _buildFileWidget(data, isMe)
            else
              _buildTextWithLinks(data['text'] ?? '', isMe),
            
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(data['timestamp']),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    read ? Icons.done_all : Icons.done,
                    size: 12,
                    color: read ? Colors.lightBlueAccent : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileWidget(Map<String, dynamic> data, bool isMe) {
    String fileName = data['fileName'] ?? 'File';
    String? fileUrl = data['fileUrl'];
    int fileSize = data['fileSize'] ?? 0;
    
    String sizeText = fileSize < 1024 
        ? '$fileSize B' 
        : fileSize < 1024 * 1024 
            ? '${(fileSize / 1024).toStringAsFixed(1)} KB'
            : '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';

    return InkWell(
      onTap: fileUrl != null ? () => _launchURL(fileUrl) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(data['fileType']),
              color: isMe ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sizeText,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: isMe ? Colors.white70 : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildTextWithLinks(String text, bool isMe) {
    final urlRegExp = RegExp(r'https?://[^\s]+');
    final matches = urlRegExp.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      );
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
        recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
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

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea(AppLocalizations l10n, bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.attach_file, color: Colors.blue),
              onSelected: (value) {
                if (value == 'image') _sendImage();
                if (value == 'document') _sendDocument();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      const Icon(Icons.image),
                      const SizedBox(width: 8),
                      Text(l10n.uploadPhoto),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'document',
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file),
                      const SizedBox(width: 8),
                      Text(l10n.uploadDocument),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: l10n.typeMessage,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white), 
                onPressed: _sendMessage
              ),
            ),
          ],
        ),
      ),
    );
  }
}
