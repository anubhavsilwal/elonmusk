import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// Internal helper — returns true once the asset is confirmed to exist.
/// Used so flutter_svg never tries to load a missing file (which throws).
Future<bool> _assetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

/// "ShelfLife" SVG wordmark used in headers.
/// Falls back to styled text if the SVG asset is missing.
class AppLogoText extends StatelessWidget {
  final double height;
  const AppLogoText({super.key, this.height = 32});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists('assets/logo/shelflife_logo.svg'),
      builder: (_, snap) {
        if (snap.data == true) {
          return SvgPicture.asset(
            'assets/logo/shelflife_logo.svg',
            height: height,
          );
        }
        return Text(
          'ShelfLife',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: height * 0.75,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}

/// Green basket SVG icon used on splash & login.
/// Falls back to a styled basket icon if the SVG asset is missing.
class AppLogoIcon extends StatelessWidget {
  final double size;
  const AppLogoIcon({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists('assets/logo/shelflife_icon.svg'),
      builder: (_, snap) {
        if (snap.data == true) {
          return SvgPicture.asset(
            'assets/logo/shelflife_icon.svg',
            width: size,
            height: size,
          );
        }
        return Container(
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
        );
      },
    );
  }
}
