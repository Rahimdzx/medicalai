import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverName;
  final String? receiverPhotoUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
    this.receiverPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;
  bool _isTyping = false;
  Timer? _typingTimer;
  Message? _replyingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markMessagesAsRead();
    _messageController.addListener(_handleTyping);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _chatService.setTypingStatus(widget.conversationId, false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.conversationId);
  }

  void _handleTyping() {
    if (!_isTyping && _messageController.text.isNotEmpty) {
      _isTyping = true;
      _chatService.setTypingStatus(widget.conversationId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.setTypingStatus(widget.conversationId, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _chatService.setTypingStatus(widget.conversationId, false);
    _isTyping = false;

    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        content: text,
        replyToId: _replyingTo?.id,
        replyToContent: _replyingTo?.content,
      );
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      await _chatService.sendImageMessage(
        conversationId: widget.conversationId,
        imageFile: File(image.path),
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

  void _showAttachmentOptions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: Text(l10n.gallery),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setReplyingTo(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          if (_isUploading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(
                          message.createdAt,
                          messages[index + 1].createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.createdAt),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                          onReply: () => _setReplyingTo(message),
                          onDelete: () => _chatService.deleteMessage(
                            widget.conversationId,
                            message.id,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildTypingIndicator(),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.receiverPhotoUrl != null
                ? CachedNetworkImageProvider(widget.receiverPhotoUrl!)
                : null,
            child: widget.receiverPhotoUrl == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                StreamBuilder<Conversation?>(
                  stream: _chatService.streamConversation(widget.conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final conv = snapshot.data!;
                      final currentUserId = _chatService.currentUserId;
                      if (currentUserId != null && conv.isTyping(currentUserId)) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                    }
                    return Text(
                      l10n.online,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {
            // Navigate to video call
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'clear') {
              _showClearConfirmation();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Text(l10n.clearAll),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noMessages,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Conversation?>(
      stream: _chatService.streamConversation(widget.conversationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final conv = snapshot.data!;
        final currentUserId = _chatService.currentUserId;
        if (currentUserId == null || !conv.isTyping(currentUserId)) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _TypingDots(),
              const SizedBox(width: 8),
              Text(
                '${widget.receiverName} is typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.blue[700]),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirm),
        content: const Text('Clear all messages in this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _chatService.clearConversation(widget.conversationId);
              Navigator.pop(context);
            },
            child: Text(l10n.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ==================== MESSAGE BUBBLE ====================

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyToContent != null) _buildReplyBubble(),
              Container(
                padding: message.type == MessageType.image
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[700] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: _buildMessageContent(),
              ),
              const SizedBox(height: 4),
              _buildMessageMeta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Message deleted',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: isMe ? Colors.white : Colors.blue[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.replyToContent!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        );

      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.3,
          ),
        );
    }
  }

  Widget _buildMessageMeta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.formattedTime,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: Colors.grey[400]);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: Colors.grey[500]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.grey[500]);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Colors.blue[400]);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: Colors.red[400]);
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                // Copy to clipboard
                Navigator.pop(context);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ==================== TYPING INDICATOR ====================

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[500]!.withOpacity(opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
