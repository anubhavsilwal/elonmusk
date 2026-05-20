import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/misc/notifications_screen.dart';
import 'app_logo.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const AppLogoText(height: 30),
      leading: IconButton(
        icon: const Icon(
          Icons.shopping_basket_outlined,
          color: AppColors.primaryDark,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ShoppingListScreen(),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
