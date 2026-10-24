import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';

class StylrBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const StylrBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.checkroom_rounded,
    Icons.event_available_rounded,
    Icons.calendar_month_rounded,
    Icons.grid_view_rounded,
  ];

  static const List<String> _labels = [
    'Home',
    'Wardrobe',
    'Occasions',
    'Calendar',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepRose.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_labels.length, (index) {
            final selected = currentIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icons[index],
                        size: 23,
                        color: selected
                            ? AppColors.deepRose
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        duration: const Duration(milliseconds: 180),
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
      ),
    );
  }
}
