
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';
import 'package:stylr/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.cream, AppColors.blush],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon.png',
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'STYLR',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Color.fromARGB(255, 134, 65, 94),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CHOOSE YOUR STYLE',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                  color: AppColors.deepRose,
                ),
              ),
              const SizedBox(height: 72),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mutedRose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
