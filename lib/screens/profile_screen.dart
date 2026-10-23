
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.blush,
              child: Icon(
                Icons.person_outline_rounded,
                size: 44,
                color: AppColors.deepRose,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Style Profile',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Personalise your Stylr experience.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _ProfileTile(
              icon: Icons.person_outline,
              title: 'Personal details',
            ),
            _ProfileTile(
              icon: Icons.palette_outlined,
              title: 'Style preferences',
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.deepRose),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onTap: () {},
    );
  }
}
