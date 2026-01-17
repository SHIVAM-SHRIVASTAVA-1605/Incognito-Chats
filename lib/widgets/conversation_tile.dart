import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';
import '../../config/theme.dart';
import '../../config/config.dart';
import '../screens/chat/chat_screen.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  Future<void> _deleteConversation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? All messages will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteConversation(conversation.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.otherUser;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.accentColor.withOpacity(0.2),
        backgroundImage: otherUser.profilePicture != null
            ? NetworkImage('${Config.baseUrl}${otherUser.profilePicture}')
            : null,
        child: otherUser.profilePicture == null
            ? Text(
                otherUser.displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              )
            : null,
      ),
      title: Text(
        otherUser.displayName,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: conversation.lastMessagePreview != null
          ? Text(
              conversation.lastMessagePreview!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Text(
        _formatTimestamp(conversation.lastMessageAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        );
      },
      onLongPress: () => _deleteConversation(context),
    );
  }
}
