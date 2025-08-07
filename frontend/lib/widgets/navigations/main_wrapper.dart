import 'package:flutter/material.dart';
import 'package:motoapp_frontend/widgets/app_bars/custom_app_bar.dart';
import 'package:motoapp_frontend/widgets/navigations/custom_bottom_navbar.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';
import 'package:motoapp_frontend/views/home/home_page.dart';
import 'package:motoapp_frontend/views/search/search_page.dart';
import 'package:motoapp_frontend/views/map/map_page.dart';
import 'package:motoapp_frontend/views/messages/messages_page.dart';
import 'package:motoapp_frontend/views/profile/profile_page.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  final String? title;
  final List<Widget> pages;
  final List<BottomNavItem> navItems;
  final bool showAppBar;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const MainWrapper({
    super.key,
    this.initialIndex = 0,
    this.title,
    required this.pages,
    required this.navItems,
    this.showAppBar = true,
    this.appBarActions,
    this.floatingActionButton,
  }) : assert(pages.length == navItems.length,
            'Pages and navItems must have the same length');

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
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: widget.title ?? 'Moto App',
              actions: widget.appBarActions,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: widget.pages,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemSelected,
        items: widget.navItems,
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
