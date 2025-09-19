// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\widgets\group_card.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';
import '../group_detail_page.dart';

class GroupCard extends StatefulWidget {
  final dynamic group;
  final bool isMyGroup;
  final AuthService authService;
  final VoidCallback? onJoinSuccess;
  final Function(dynamic group)? onGroupJoined;

  const GroupCard({
    super.key,
    required this.group,
    required this.isMyGroup,
    required this.authService,
    this.onJoinSuccess,
    this.onGroupJoined,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _isJoining = false;
  bool _requestSent = false;

  Future<void> _joinGroup() async {
    if (_isJoining) return;
    
    final requiresApproval = widget.group['requires_approval'] as bool? ?? false;
    
    if (requiresApproval) {
      // Onay gerektiren grup için mesaj dialog'u göster
      final message = await _showJoinRequestDialog();
      if (message == null) return; // Kullanıcı iptal etti
    }
    
    setState(() {
      _isJoining = true;
    });

    try {
      final groupService = GroupService(authService: widget.authService);
      final groupId = (widget.group['id'] is int)
          ? widget.group['id'] as int
          : int.tryParse(widget.group['id'].toString()) ?? 0;
      
      final message = requiresApproval ? await _showJoinRequestDialog() : null;
      final response = await groupService.joinGroup(groupId, message: message);
      
      if (mounted) {
        if (requiresApproval) {
          setState(() {
            _requestSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Katılım isteği gönderildi. Onay bekleniyor.'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gruba başarıyla katıldınız!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          
          // Backend'den gelen güncel grup bilgisini kullan
          final updatedGroup = response['group'];
          if (updatedGroup != null) {
            widget.onGroupJoined?.call(updatedGroup);
          } else {
            // Fallback: eski grup bilgisini kullan
            widget.onGroupJoined?.call(widget.group);
          }
          
          // Callback'i çağır (backend'den güncel veriyi çek)
          widget.onJoinSuccess?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gruba katılırken hata oluştu: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group is! Map<String, dynamic>) {
      return const Card(
        child: ListTile(title: Text('Geçersiz grup verisi')),
      );
    }

    final groupId = (widget.group['id'] is int)
        ? widget.group['id'] as int
        : int.tryParse(widget.group['id'].toString()) ?? 0;
    final groupName = widget.group['name']?.toString() ?? 'Grup';
    final description = widget.group['description']?.toString() ?? 'Açıklama yok';
    final profilePictureUrl = widget.group['profile_picture_url']?.toString();
    final memberCount = widget.group['member_count']?.toString() ?? 
                       widget.group['members']?.length?.toString() ?? '0';
    final createdDate = widget.group['created_at']?.toString() ?? '';
    

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailPage(
              groupId: groupId, 
              groupData: widget.group,
              authService: widget.authService,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Grup bilgileri ve buton
              Row(
                children: [
                  // Minimal profil ikonu
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              profilePictureUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.group,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.group,
                            size: 24,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Grup bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Katıl butonu
                  if (!widget.isMyGroup)
                    _buildJoinButton(),
                ],
              ),
              const SizedBox(height: 12),
              // Alt kısım - Üye sayısı ve tarih
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$memberCount üye',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (createdDate.isNotEmpty)
                    Text(
                      _formatDate(createdDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    final requiresApproval = widget.group['requires_approval'] as bool? ?? false;
    
    return Container(
      height: 32,
      child: ElevatedButton(
        onPressed: _isJoining ? null : _joinGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isJoining
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                _getButtonText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  String _getButtonText() {
    final requiresApproval = widget.group['requires_approval'] as bool? ?? false;
    
    if (requiresApproval && _requestSent) {
      return 'Gönderildi';
    } else {
      return 'Katıl';
    }
  }

  Future<String?> _showJoinRequestDialog() async {
    String message = '';
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Katılım İsteği', 
            style: Theme.of(context).textTheme.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bu gruba katılmak için grup sahibinden onay gerekiyor.',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Mesaj (isteğe bağlı)',
                  hintText: 'Katılmak istediğinizi belirten bir mesaj yazabilirsiniz...',
                ),
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal',
                style: Theme.of(context).textTheme.labelLarge),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(message),
              child: Text('Gönder',
                style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }
}
