import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Ana Sayfa
          IconButton(
            icon: Icon(Icons.home),
            color: currentIndex == 0
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => onTap(0),
          ),

          // Sıralama
          IconButton(
            icon: Icon(Icons.leaderboard),
            color: currentIndex == 1
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => onTap(1),
          ),
        ],
      ),
    );
  }
}
