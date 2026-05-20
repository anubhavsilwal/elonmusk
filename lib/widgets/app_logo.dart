import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// SVG "ShelfLife" wordmark used in headers.
/// Falls back to styled text if the SVG asset is missing.
class AppLogoText extends StatelessWidget {
  final double height;
  const AppLogoText({super.key, this.height = 32});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/shelflife_logo.svg',
      height: height,
      placeholderBuilder: (_) => Text(
        'ShelfLife',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: height * 0.75,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// SVG basket icon used on splash & login.
class AppLogoIcon extends StatelessWidget {
  final double size;
  const AppLogoIcon({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/shelflife_icon.svg',
      width: size,
      height: size,
      placeholderBuilder: (_) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.shopping_basket_outlined,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
