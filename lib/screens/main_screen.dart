
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'try_on_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(
      onOpenWardrobe: () => _openTab(1),
      onOpenTryOn: () => _openTab(2),
    ),
    const WardrobeScreen(),
    const TryOnScreen(),
    const ProfileScreen(),
  ];

  void _openTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: StylrBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _openTab,
      ),
    );
  }
}
