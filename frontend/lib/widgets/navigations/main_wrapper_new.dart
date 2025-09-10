import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';
import 'package:motoapp_frontend/services/chat/chat_service.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class MainWrapperNew extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavItem> navItems;
  final VoidCallback? onUnreadCountChanged;

  const MainWrapperNew({
    super.key,
    required this.pages,
    required this.navItems,
    this.onUnreadCountChanged,
  });

  @override
  State<MainWrapperNew> createState() => MainWrapperNewState();
}

class MainWrapperNewState extends State<MainWrapperNew> {
  int _currentIndex = 0;
  int _unreadMessageCount = 0;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ServiceLocator.chat;
    _loadUnreadMessageCount();
    
    // Debug için navigation yapısını göster (sadece debug modda)
    if (kDebugMode) {
      print("=== YENİ NAVIGATION INIT ===");
      print("NavItems sayısı: ${widget.navItems.length}");
      print("Pages sayısı: ${widget.pages.length}");
      
      for (int i = 0; i < widget.navItems.length; i++) {
        print("NavItem $i: ${widget.navItems[i].label}");
      }
      
      for (int i = 0; i < widget.pages.length; i++) {
        print("Page $i: ${widget.pages[i].runtimeType}");
      }
      print("===========================");
    }
  }

  @override
  void didUpdateWidget(MainWrapperNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent widget'tan callback değişikliği geldiğinde unread count'u yenile
    if (widget.onUnreadCountChanged != oldWidget.onUnreadCountChanged) {
      _loadUnreadMessageCount();
    }
  }

  // Public metod - dışarıdan çağrılabilir
  void refreshUnreadCount() {
    _loadUnreadMessageCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final conversations = await _chatService.getConversations();
      final totalUnread = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      
      if (mounted) {
        setState(() {
          _unreadMessageCount = totalUnread;
        });
      }
      
      // Parent widget'a bildir
      widget.onUnreadCountChanged?.call();
    } catch (e) {
      print('❌ MainWrapper - Error loading unread message count: $e');
    }
  }

  void _onTabSelected(int index) {
    if (kDebugMode) {
      print("=== YENİ NAVIGATION DEBUG ===");
      print("Tıklanan buton index: $index");
      print("Tıklanan buton: ${widget.navItems[index].label}");
      print("Açılacak sayfa: ${widget.pages[index].runtimeType}");
      print("=============================");
    }

    setState(() {
      _currentIndex = index;
    });
    
    // Her tab değişikliğinde unread count'u yenile
    // Bu sayede mesajlar okunduğunda anında güncellenir
    _loadUnreadMessageCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        items: widget.navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          // Messages tab için badge ekle
          Widget icon = Icon(item.icon);
          if (index == 4 && _unreadMessageCount > 0) { // Messages index
            icon = Stack(
              children: [
                Icon(item.icon),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadMessageCount > 99 ? '99+' : _unreadMessageCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
          
          return BottomNavigationBarItem(
            icon: icon,
            label: item.label,
          );
        }).toList(),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        showUnselectedLabels: true,
      ),
    );
  }
}
