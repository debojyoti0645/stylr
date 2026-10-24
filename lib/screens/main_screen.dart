
import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'occasions_screen.dart';
import 'calendar_screen.dart';
import 'more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _openTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenWardrobe: () => _openTab(1),
        onOpenTryOn: () => _openTab(2),
      ),
      const WardrobeScreen(),
      const OccasionsScreen(),
      const CalendarScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: StylrBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _openTab,
      ),
    );
  }
}
