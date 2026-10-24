
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('Mix & Match', Icons.auto_awesome_rounded),
      ('What to Buy', Icons.shopping_bag_outlined),
      ('Style Inspiration', Icons.photo_library_outlined),
      ('Style Profile & Settings', Icons.person_outline_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: AppColors.cream,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: Icon(
                options[index].$2,
                color: AppColors.deepRose,
              ),
              title: Text(options[index].$1),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${options[index].$1} will be implemented next.',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
