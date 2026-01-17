import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/app_provider.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
    this.onReply,
  });

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  String _getExpiryText() {
    final now = DateTime.now();
    final difference = message.expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return 'Expires in ${hours}h ${minutes}m';
    } else {
      return 'Expires in ${minutes}m';
    }
  }

  void _showReactionPicker(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final currentUserId = context.read<AppProvider>().currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'React to message',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                '👍',
                '❤️',
                '😂',
                '😮',
                '😢',
                '🙏',
                '🔥',
                '👏',
                '🎉',
                '💯'
              ].map((emoji) {
                final hasReacted =
                    message.reactions[emoji]?.contains(currentUserId) ?? false;
                return InkWell(
                  onTap: () {
                    if (hasReacted) {
                      chatProvider.removeReaction(message.id, emoji);
                    } else {
                      chatProvider.addReaction(message.id, emoji);
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: hasReacted
                          ? AppTheme.accentColor.withOpacity(0.2)
                          : AppTheme.tertiaryDark,
                      borderRadius: BorderRadius.circular(12),
                      border: hasReacted
                          ? Border.all(color: AppTheme.accentColor, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();

    final currentUserId = context.read<AppProvider>().currentUser?.id ?? '';
    final chatProvider = context.read<ChatProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted = users.contains(currentUserId);

          return InkWell(
            onTap: () {
              if (hasReacted) {
                chatProvider.removeReaction(message.id, emoji);
              } else {
                chatProvider.addReaction(message.id, emoji);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasReacted
                    ? AppTheme.accentColor.withOpacity(0.3)
                    : (isMe
                        ? Colors.white.withOpacity(0.2)
                        : AppTheme.tertiaryDark),
                borderRadius: BorderRadius.circular(12),
                border: hasReacted
                    ? Border.all(color: AppTheme.accentColor, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${users.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white : AppTheme.textSecondary,
                        fontWeight:
                            hasReacted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.secondaryDark,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions,
                        color: AppTheme.accentColor),
                    title: const Text('React'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReactionPicker(context);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.reply, color: AppTheme.accentColor),
                    title: const Text('Reply'),
                    onTap: () {
                      Navigator.pop(context);
                      if (onReply != null) onReply!();
                    },
                  ),
                  if (onDelete != null)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete message'),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                    ),
                ],
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.accentColor : AppTheme.secondaryDark,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show replied-to message if exists
                    if (message.replyToMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.2)
                              : AppTheme.tertiaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : AppTheme.accentColor,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToMessage!.sender?.displayName ??
                                  'Unknown',
                              style: TextStyle(
                                color:
                                    isMe ? Colors.white : AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyToMessage!.content.length > 50
                                  ? '${message.replyToMessage!.content.substring(0, 50)}...'
                                  : message.replyToMessage!.content,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status == 'pending'
                                ? Icons.access_time
                                : Icons.done_all,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildReactions(context),
            ],
          ),
        ),
      ),
    );
  }
}
