import 'package:flutter/material.dart';
import 'package:motoapp_frontend/widgets/app_bars/custom_app_bar.dart';
import 'package:motoapp_frontend/widgets/navigations/custom_bottom_navbar.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  final String? email;
  final List<Widget> pages;
  final List<BottomNavItem> navItems;

  const MainWrapper({
    super.key,
    this.initialIndex = 0,
    this.email,
    required this.pages,
    required this.navItems,
  }) : assert(pages.length == navItems.length,
            'Pages and nav items must have the same length');

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.email ?? 'Moto App',
        onLeadingPressed: widget.email != null
            ? () => Scaffold.of(context).openDrawer()
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: widget.pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemSelected,
        items: widget.navItems,
      ),
    );
  }
}
