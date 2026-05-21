import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/main/main_shell.dart';

/// Bottom navigation bar shared by all main-app screens.
/// 5 tabs: Home / Pantry / [+Add FAB center] / Recipe / Profile.
/// Active indicator is a CIRCLE (was an oval in v1).
class ShelfBottomNav extends StatelessWidget {
  final int currentIndex; // 0=Home, 1=Pantry, 2=Add, 3=Recipe, 4=Profile

  const ShelfBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainShell(initialIndex: index),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64, // tightened to prevent overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(context, 1, Icons.kitchen_outlined, Icons.kitchen, 'Pantry'),
              _addButton(context),
              _navItem(context, 3, Icons.receipt_long_outlined, Icons.receipt_long, 'Recipe'),
              _navItem(context, 4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon,
      IconData iconActive, String label) {
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle, // CIRCLE not oval
                  ),
                  child: Icon(iconActive, color: Colors.white, size: 20),
                )
              else
                Icon(icon, color: AppColors.textPri(context), size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPri(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    final selected = currentIndex == 2;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeeper, // DARKER green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeeper.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 2),
              Text(
                'Add',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPri(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
