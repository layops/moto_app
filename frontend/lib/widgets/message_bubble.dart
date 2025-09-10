import 'package:flutter/material.dart';
import '../services/chat/chat_service.dart';

class MessageBubble extends StatelessWidget {
  final PrivateMessage message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isRead;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isRead,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (isFirstInGroup) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                backgroundImage: message.sender.profilePicture != null
                    ? NetworkImage(message.sender.profilePicture!)
                    : null,
                child: message.sender.profilePicture == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 40),
            ],
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe 
                      ? colorScheme.primary 
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    topLeft: isMe 
                        ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    topRight: isMe 
                        ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    bottomLeft: isMe 
                        ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    bottomRight: isMe 
                        ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content with better typography
                    SelectableText(
                      message.message,
                      style: TextStyle(
                        color: isMe 
                            ? colorScheme.onPrimary 
                            : colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: isRead 
                                ? Colors.blue 
                                : (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}

class GroupMessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (isFirstInGroup) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                backgroundImage: message.sender.profilePicture != null
                    ? NetworkImage(message.sender.profilePicture!)
                    : null,
                child: message.sender.profilePicture == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 40),
            ],
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe 
                      ? colorScheme.primary 
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    topLeft: isMe 
                        ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    topRight: isMe 
                        ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    bottomLeft: isMe 
                        ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                    bottomRight: isMe 
                        ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                        : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply indicator
                    if (message.replyTo != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${message.replyTo!.sender.displayName}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyToContent ?? message.replyTo!.content,
                              style: TextStyle(
                                color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Message content
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: isMe 
                            ? colorScheme.onPrimary 
                            : colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    
                    // File attachment
                    if (message.fileUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              message.messageType == 'image' ? Icons.image : Icons.attach_file,
                              size: 16,
                              color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.messageType == 'image' ? 'Resim' : 'Dosya',
                              style: TextStyle(
                                color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMe && isFirstInGroup) ...[
                          Text(
                            message.sender.displayName,
                            style: TextStyle(
                              color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}
