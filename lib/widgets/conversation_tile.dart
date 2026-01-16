import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/conversation_model.dart';
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
    );
  }
}
