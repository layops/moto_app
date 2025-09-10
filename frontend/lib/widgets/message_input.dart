import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final bool isSending;
  final String? replyTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onAttachFile;
  final VoidCallback? onAttachImage;

  const MessageInput({
    super.key,
    required this.controller,
    this.onSend,
    this.isSending = false,
    this.replyTo,
    this.onCancelReply,
    this.onAttachFile,
    this.onAttachImage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Reply indicator
        if (widget.replyTo != null) _buildReplyIndicator(),
        
        // Main input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Attachment options (when expanded)
              if (_isExpanded) _buildAttachmentOptions(),
              
              // Input row
              Row(
                children: [
                  // Attachment button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.add_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  
                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: widget.replyTo != null 
                              ? 'Yanıtla...'
                              : 'Mesajınızı yazın...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => widget.onSend?.call(),
                        onChanged: (value) {
                          // Auto-expand if text is long
                          if (value.length > 50 && !_isExpanded) {
                            setState(() {
                              _isExpanded = true;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: widget.isSending ? null : widget.onSend,
                      icon: widget.isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.replyTo!,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.image_rounded,
            label: 'Resim',
            color: Colors.green,
            onTap: widget.onAttachImage,
          ),
          _buildAttachmentOption(
            icon: Icons.attach_file_rounded,
            label: 'Dosya',
            color: Colors.blue,
            onTap: widget.onAttachFile,
          ),
          _buildAttachmentOption(
            icon: Icons.location_on_rounded,
            label: 'Konum',
            color: Colors.red,
            onTap: () {
              // TODO: Implement location sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Konum paylaşımı yakında eklenecek')),
              );
            },
          ),
          _buildAttachmentOption(
            icon: Icons.emoji_emotions_rounded,
            label: 'Emoji',
            color: Colors.orange,
            onTap: () {
              // TODO: Implement emoji picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emoji seçici yakında eklenecek')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
