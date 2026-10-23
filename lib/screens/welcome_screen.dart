import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';
import 'package:stylr/screens/login_screen.dart';
import 'package:stylr/screens/main_screen.dart';
import 'package:stylr/screens/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'stylr',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.deepRose,
                ),
              ),
              const Spacer(),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    size: 110,
                    color: AppColors.mutedRose,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Discover your\\nstyle story.',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your wardrobe, your inspiration, your style. '
                'Everything you need to dress with confidence.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mutedRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepRose,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('I already have an account'),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  ),
                  child: const Text(
                    'Continue as guest',
                    style: TextStyle(color: AppColors.deepRose),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
