
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class OccasionsScreen extends StatelessWidget {
  const OccasionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Occasion Stylist'),
        backgroundColor: AppColors.cream,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tell Stylr where you are going.\n'
            'Get outfit suggestions from your wardrobe.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
