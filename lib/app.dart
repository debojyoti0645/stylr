import 'package:flutter/material.dart';
import 'package:stylr/constants/app_theme.dart';
import 'package:stylr/screens/splash_screen.dart';

class StylrApp extends StatelessWidget {
  const StylrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stylr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
