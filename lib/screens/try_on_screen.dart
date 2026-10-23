
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Try-On')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 76,
                color: AppColors.mutedRose,
              ),
              const SizedBox(height: 20),
              const Text(
                'Your virtual fitting room',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Preview outfits on your photo. '
                'Your virtual try-on experience is coming next.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Start try-on'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
