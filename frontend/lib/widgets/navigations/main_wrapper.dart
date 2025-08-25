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

    // Hata ayıklama için uzunlukları kontrol et
    debugPrint('MainWrapper: NAV ITEMS COUNT: ${widget.navItems.length}');
    debugPrint('MainWrapper: PAGES COUNT: ${widget.pages.length}');

    // Uzunluklar eşit değilse uyarı ver
    if (widget.navItems.length != widget.pages.length) {
      debugPrint('UYARI: NavItems ve Pages listeleri aynı uzunlukta değil!');
    }
  }

  void _onTabSelected(int index) {
    // Geçersiz indeks kontrolü ekleyin
    if (index < 0 || index >= widget.pages.length) {
      debugPrint("HATA: Geçersiz indeks: $index");
      return;
    }

    // Hangi sayfaya gidildiğini debug konsolunda göster
    debugPrint("TIKLANAN BUTON: ${widget.navItems[index].label}");
    debugPrint("AÇILACAK SAYFA: ${widget.pages[index].runtimeType}");

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
