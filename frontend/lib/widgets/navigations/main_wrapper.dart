// main_wrapper.dart
import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class MainWrapper extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavItem> navItems;

  const MainWrapper({
    super.key,
    required this.pages,
    required this.navItems,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;

    // Debug için navigation yapısını göster
    print("=== NAVIGATION INIT ===");
    print("NavItems sayısı: ${widget.navItems.length}");
    print("Pages sayısı: ${widget.pages.length}");
    
    for (int i = 0; i < widget.navItems.length; i++) {
      print("NavItem $i: ${widget.navItems[i].label}");
    }
    
    for (int i = 0; i < widget.pages.length; i++) {
      print("Page $i: ${widget.pages[i].runtimeType}");
    }
    print("======================");

    // Uzunluklar eşit değilse uyarı ver ve güvenli indeks ayarla
    if (widget.navItems.length != widget.pages.length) {
      debugPrint('UYARI: NavItems ve Pages listeleri aynı uzunlukta değil!');
      debugPrint('NavItems: ${widget.navItems.length}, Pages: ${widget.pages.length}');
      
      // Güvenli indeks ayarla
      if (_currentIndex >= widget.pages.length) {
        _currentIndex = widget.pages.length - 1;
        debugPrint('Güvenli indeks ayarlandı: $_currentIndex');
      }
    }
  }

  void _onTabSelected(int index) {
    // Geçersiz indeks kontrolü ekleyin
    if (index < 0 || index >= widget.pages.length) {
      debugPrint("HATA: Geçersiz indeks: $index");
      debugPrint("Geçerli indeks aralığı: 0-${widget.pages.length - 1}");
      return;
    }

    // NavItems ve Pages listelerinin uzunluklarını kontrol et
    if (index >= widget.navItems.length) {
      debugPrint("HATA: NavItems listesinde geçersiz indeks: $index");
      debugPrint("NavItems uzunluğu: ${widget.navItems.length}");
      return;
    }

    // Debug için hangi butona tıklandığını ve hangi sayfanın açılacağını göster
    print("=== NAVIGATION DEBUG ===");
    print("Tıklanan buton index: $index");
    print("Tıklanan buton: ${widget.navItems[index].label}");
    print("Açılacak sayfa: ${widget.pages[index].runtimeType}");
    print("========================");

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Geçersiz indeks durumunda güvenli hale getirin
    final safeIndex = _currentIndex.clamp(0, widget.pages.length - 1);

    return Scaffold(
      // IndexedStack sayfa statelerini korur
      body: IndexedStack(
        index: safeIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          items: widget.navItems.asMap().entries.map((entry) {
            final item = entry.value;
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
