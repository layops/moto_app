// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\widgets\group_card.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
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
            const SnackBar(
              content: Text('Katılım isteği gönderildi. Onay bekleniyor.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gruba başarıyla katıldınız!'),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
      child: Card(
        // ... (Kalan Card widget içeriği aynı kalacak)
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Fotoğrafı
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: AppColorSchemes.lightBackground,
                    ),
                    child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              profilePictureUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.group,
                                  size: 30,
                                  color: AppColorSchemes.primaryColor,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.group,
                            size: 30,
                            color: AppColorSchemes.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(groupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(description,
                            style: TextStyle(
                                color: AppColorSchemes.textSecondary,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!widget.isMyGroup)
                    ElevatedButton(
                      onPressed: _isJoining ? null : _joinGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorSchemes.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ThemeConstants.borderRadiusMedium),
                        ),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_getButtonText()),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('$memberCount üye',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const Spacer(),
                  if (createdDate.isNotEmpty)
                    Text('Oluşturuldu: ${_formatDate(createdDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    final requiresApproval = widget.group['requires_approval'] as bool? ?? false;
    
    if (requiresApproval && _requestSent) {
      return 'İsteğiniz Gönderildi';
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
          title: const Text('Katılım İsteği'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bu gruba katılmak için grup sahibinden onay gerekiyor.'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
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
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(message),
              child: const Text('Gönder'),
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
