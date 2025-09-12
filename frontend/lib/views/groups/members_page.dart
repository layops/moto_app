import 'package:flutter/material.dart';
import '../../core/theme/color_schemes.dart';
import '../../services/group/group_service.dart';
import '../../services/auth/auth_service.dart';

class MembersPage extends StatefulWidget {
  final Map<String, dynamic> groupData;
  final bool isOwner;
  final bool isModerator;
  final AuthService authService;

  const MembersPage({
    Key? key,
    required this.groupData,
    required this.isOwner,
    required this.isModerator,
    required this.authService,
  }) : super(key: key);

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final groupService = GroupService(authService: widget.authService);
      final members = await groupService.getGroupMembers(widget.groupData['id']);
      
      setState(() {
        _members = List<Map<String, dynamic>>.from(members);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group Members',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (widget.isOwner || widget.isModerator)
            IconButton(
              icon: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface),
              onPressed: _inviteMembers,
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hata: $_error', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Grup bilgileri
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: widget.groupData['profile_picture_url'] != null
                                ? NetworkImage(widget.groupData['profile_picture_url'])
                                : null,
                            backgroundColor: AppColorSchemes.primaryColor,
                            child: widget.groupData['profile_picture_url'] == null
                                ? Icon(Icons.motorcycle, color: Theme.of(context).colorScheme.onPrimary, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.groupData['name'] ?? 'Grup Adı',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_members.length} members',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Üyeler listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return _buildMemberItem(member);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final isOwner = member['id'] == widget.groupData['owner'];
    final role = isOwner ? 'Admin' : 'Member';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: member['profile_picture'] != null
                ? NetworkImage(member['profile_picture'])
                : null,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: member['profile_picture'] == null
                ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['username']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isOwner && !isOwner)
            IconButton(
              icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => _showMemberOptions(member),
            ),
        ],
      ),
    );
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Member Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary),
              title: Text('Make Moderator', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _makeModerator(member);
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.error),
              title: Text('Remove Member', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _removeMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _makeModerator(Map<String, dynamic> member) async {
    try {
      final groupService = GroupService(authService: widget.authService);
      await groupService.makeModerator(widget.groupData['id'], member['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member['username']?.toString() ?? 'User'} is now a moderator')),
      );
      
      // Üyeleri yeniden yükle
      _loadMembers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _removeMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Remove Member',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to remove ${member['username']?.toString() ?? 'User'} from the group?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final groupService = GroupService(authService: widget.authService);
                await groupService.removeGroupMember(widget.groupData['id'], member['id']);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member['username']?.toString() ?? 'User'} removed from group')),
                );
                
                // Üyeleri yeniden yükle
                _loadMembers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _inviteMembers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite members feature coming soon!')),
    );
  }
}
