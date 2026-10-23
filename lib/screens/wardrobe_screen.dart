
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wardrobe')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.checkroom_rounded,
              size: 72,
              color: AppColors.mutedRose,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your wardrobe starts here',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Organise your clothes in one place.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add clothing'),
            ),
          ],
        ),
      ),
    );
  }
}
