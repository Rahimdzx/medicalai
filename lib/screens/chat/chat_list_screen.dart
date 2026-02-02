import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chat),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _chatService.streamTotalUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(l10n),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: _chatService.streamConversations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                var conversations = snapshot.data!;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  conversations = conversations.where((conv) {
                    final name = conv.getOtherParticipantName(currentUserId ?? '');
                    return name.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (conversations.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoSearchResults(l10n);
                }

                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 80,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      currentUserId: currentUserId ?? '',
                      onTap: () => _openChat(context, conversation, currentUserId ?? ''),
                      onLongPress: () => _showConversationOptions(context, conversation),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: l10n.search,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            l10n.noMessages,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a doctor',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewChatDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.startChat),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No conversations found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Conversation conversation, String currentUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          receiverName: conversation.getOtherParticipantName(currentUserId),
          receiverPhotoUrl: conversation.getOtherParticipantPhoto(currentUserId),
        ),
      ),
    );
  }

  void _showConversationOptions(BuildContext context, Conversation conversation) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark as read'),
              onTap: () {
                _chatService.markMessagesAsRead(conversation.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute notifications'),
              onTap: () {
                Navigator.pop(context);
                // Implement mute
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[400]),
              title: Text(l10n.delete, style: TextStyle(color: Colors.red[400])),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation(context, conversation);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(BuildContext context, Conversation conversation) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              _chatService.deleteConversation(conversation.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    // This would show a list of contacts/doctors to start a new chat
    // For now, show a placeholder
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    l10n.startChat,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Select a doctor to chat with',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CONVERSATION TILE ====================

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final name = conversation.getOtherParticipantName(currentUserId);
    final photoUrl = conversation.getOtherParticipantPhoto(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final isTyping = conversation.isTyping(currentUserId);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.formattedLastMessageTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? Colors.blue[700] : Colors.grey[500],
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: isTyping
                            ? Text(
                                'typing...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Row(
                                children: [
                                  if (conversation.lastMessageSenderId == currentUserId)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.done_all,
                                        size: 16,
                                        color: Colors.blue[400],
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _getLastMessagePreview(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: unreadCount > 0
                                            ? Colors.black87
                                            : Colors.grey[600],
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessage == null) return '';

    switch (conversation.lastMessageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 File';
      case MessageType.voice:
        return '🎤 Voice message';
      default:
        return conversation.lastMessage!;
    }
  }
}
