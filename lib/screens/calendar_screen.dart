
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Outfit Calendar'),
        backgroundColor: AppColors.cream,
      ),
      body: const Center(
        child: Text('Your planned outfits will appear here.'),
      ),
    );
  }
}
