
import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class StylrBottomNavBar extends StatelessWidget {
  const StylrBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.checkroom_rounded,
    Icons.auto_awesome_rounded,
    Icons.person_rounded,
  ];

  static const List<String> _labels = [
    'Home',
    'Wardrobe',
    'Try-On',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepRose.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_icons.length, (index) {
          final selected = currentIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[index],
                      color: selected
                          ? AppColors.deepRose
                          : AppColors.textSecondary,
                      size: 23,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.deepRose
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: selected ? 18 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.mutedRose,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
