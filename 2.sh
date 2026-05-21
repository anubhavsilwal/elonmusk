#!/usr/bin/env bash
# =============================================================================
# ShelfLife — Version 2 Update Script
# =============================================================================
# Run this from the ROOT of your Flutter project (the `demoui/` folder),
# AFTER you've already run 1.sh successfully.
#
# This script is INCREMENTAL — it only modifies files that change in v2
# and adds new screens. It does NOT touch your assets/ folder.
#
# Usage:
#   cd /Users/anubhavsilwal/StudioProjects/demoui
#   chmod +x 2.sh
#   ./2.sh
#
# To roll back to v1 (if using git):
#   git reset --hard v1
# To roll back without git (if you made a backup):
#   rm -rf demoui && mv demoui_v1_backup demoui
# =============================================================================
#
# CHANGES IN V2:
#   • Fixed bottom-nav overflow on main screens
#   • Fixed signup step 1 right-overflow
#   • Fixed signup step 3 blank-body bug (was due to Expanded outside Column)
#   • Fixed SVG missing-asset crash (now silently falls back)
#   • All const/lint warnings fixed for "dart fix" cleanliness
#   • DropdownButtonFormField: value → initialValue (Flutter 3.41+)
#   • Removed unused import in pantry_item.dart
#
# UI UPDATES IN V2:
#   1. Shopping cart icon replaces shopping basket in main top app bar
#   2. Full app-wide dark mode (toggle on Profile)
#   3. Edit Profile Details screen
#   4. Privacy & Data screen
#   5. Bottom-nav active indicator is now a circle (not oval)
#   6. Add (+) button uses a darker green
#   7. User updated to "Anubhav Silwal" / anubhav@shelflife.app
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()     { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()    { echo -e "${RED}[ERR]${NC}  $1"; }

if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then
  err "This doesn't look like the project root. cd into demoui/ first."
  exit 1
fi

if [ ! -f "lib/theme/app_colors.dart" ]; then
  err "v1 files not found. Run 1.sh first."
  exit 1
fi

info "Starting ShelfLife v2 update..."

# =============================================================================
# 1. THEME — colors + dark mode + ThemeController
# =============================================================================
info "Updating theme system with dark mode support..."

cat > lib/theme/app_colors.dart <<'DART'
import 'package:flutter/material.dart';

/// Centralized colors. Each semantic color has a light + dark variant.
/// Use AppColors.bgOf(context), AppColors.cardOf(context), etc., from widgets
/// so colors switch automatically with the active theme.
class AppColors {
  AppColors._();

  // ---- Brand (same in both themes) ----------------------------------------
  static const Color primary       = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF2E7D32);   // headers / buttons
  static const Color primaryDeeper = Color(0xFF1B5E20);   // darker for "Add" FAB
  static const Color primaryLight  = Color(0xFFE8F5E9);

  // ---- LIGHT theme colors -------------------------------------------------
  static const Color lightBackground   = Color(0xFFF5F6FA);
  static const Color lightCard         = Colors.white;
  static const Color lightDivider      = Color(0xFFE5E7EB);
  static const Color lightTextPrimary  = Color(0xFF111827);
  static const Color lightTextSecondary= Color(0xFF6B7280);
  static const Color lightTextMuted    = Color(0xFF9CA3AF);
  static const Color lightChipBg       = Color(0xFFF3F4F6);
  static const Color lightChipUnselected = Color(0xFFE3F2FD);
  static const Color lightInputFill    = Colors.white;
  static const Color lightInfoBg       = Color(0xFFEFF6FF);

  // ---- DARK theme colors --------------------------------------------------
  static const Color darkBackground    = Color(0xFF121417);
  static const Color darkCard          = Color(0xFF1E2126);
  static const Color darkDivider       = Color(0xFF2D3138);
  static const Color darkTextPrimary   = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFFB0B4BA);
  static const Color darkTextMuted     = Color(0xFF6B7280);
  static const Color darkChipBg        = Color(0xFF262A30);
  static const Color darkChipUnselected= Color(0xFF1F2429);
  static const Color darkInputFill     = Color(0xFF1E2126);
  static const Color darkInfoBg        = Color(0xFF18242E);

  // ---- Status (same hue in both themes) -----------------------------------
  static const Color warning       = Color(0xFFFF9800);
  static const Color warningLight  = Color(0xFFFFF4E5);
  static const Color danger        = Color(0xFFF44336);
  static const Color dangerLight   = Color(0xFFFFEBEE);
  static const Color safe          = Color(0xFF16A34A);
  static const Color safeLight     = Color(0xFFE8F5E9);

  // ---- Social -------------------------------------------------------------
  static const Color facebookBlue  = Color(0xFF1877F2);

  // ---- Helpers — pick the right color based on context's brightness -------
  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c)       => _isDark(c) ? darkBackground   : lightBackground;
  static Color card(BuildContext c)     => _isDark(c) ? darkCard         : lightCard;
  static Color divider(BuildContext c)  => _isDark(c) ? darkDivider      : lightDivider;
  static Color textPri(BuildContext c)  => _isDark(c) ? darkTextPrimary  : lightTextPrimary;
  static Color textSec(BuildContext c)  => _isDark(c) ? darkTextSecondary: lightTextSecondary;
  static Color textMut(BuildContext c)  => _isDark(c) ? darkTextMuted    : lightTextMuted;
  static Color chipBg(BuildContext c)   => _isDark(c) ? darkChipBg       : lightChipBg;
  static Color infoBg(BuildContext c)   => _isDark(c) ? darkInfoBg       : lightInfoBg;
  static Color chipUnsel(BuildContext c)=> _isDark(c) ? darkChipUnselected : lightChipUnselected;
}
DART

# ---- Theme controller (ValueNotifier) for app-wide toggle ------------------
cat > lib/theme/theme_controller.dart <<'DART'
import 'package:flutter/material.dart';

/// Global theme mode controller.
/// Toggle from anywhere (e.g. the Profile dark-mode switch) via:
///   themeController.value = ThemeMode.dark;
final ValueNotifier<ThemeMode> themeController =
    ValueNotifier<ThemeMode>(ThemeMode.light);
DART

# ---- app_theme.dart — both light and dark themes ---------------------------
cat > lib/theme/app_theme.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // ---- LIGHT THEME --------------------------------------------------------
  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    );

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightCard,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primaryDark,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.lightTextMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ---- DARK THEME ---------------------------------------------------------
  static ThemeData dark() {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.darkCard,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
DART

ok "Theme + dark mode + controller written."

# =============================================================================
# 2. main.dart — listen to themeController for dark mode toggle
# =============================================================================
info "Updating main.dart..."

cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/misc/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ShelfLifeApp());
}

class ShelfLifeApp extends StatelessWidget {
  const ShelfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'ShelfLife',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
DART

ok "main.dart updated."

# =============================================================================
# 3. MODELS — remove unused import from pantry_item.dart
# =============================================================================
info "Cleaning models..."

cat > lib/models/pantry_item.dart <<'DART'
enum ExpiryStatus { safe, soon, expired }

class PantryItem {
  final String name;
  final String category;
  final String quantity;
  final int daysUntilExpiry;
  final String expiryLabel;
  final String? imageAsset;
  final double progress;

  const PantryItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.daysUntilExpiry,
    required this.expiryLabel,
    required this.progress,
    this.imageAsset,
  });

  ExpiryStatus get status {
    if (daysUntilExpiry <= 1) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.safe;
  }
}
DART

ok "Models cleaned."

# =============================================================================
# 4. WIDGETS — app_logo (safe SVG load), app bar (cart icon), bottom nav
# =============================================================================
info "Updating widgets..."

# ---- app_logo.dart — uses FutureBuilder to handle missing SVGs safely ------
cat > lib/widgets/app_logo.dart <<'DART'
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
DART

# ---- main_app_bar.dart — cart icon now (was basket) ------------------------
cat > lib/widgets/main_app_bar.dart <<'DART'
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primary : AppColors.primaryDark;
    return AppBar(
      automaticallyImplyLeading: false,
      title: const AppLogoText(height: 30),
      leading: IconButton(
        icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
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
          icon: Icon(Icons.notifications_none, color: AppColors.textPri(context)),
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
DART

# ---- bottom_nav.dart — circular indicator + darker Add button + no overflow
cat > lib/widgets/bottom_nav.dart <<'DART'
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
DART

# ---- pantry_item_card.dart — theme-aware ----------------------------------
cat > lib/widgets/pantry_item_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../theme/app_colors.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final bool compact;
  final bool showMenu;
  final VoidCallback? onTap;

  const PantryItemCard({
    super.key,
    required this.item,
    this.compact = false,
    this.showMenu = false,
    this.onTap,
  });

  Color get _statusColor {
    switch (item.status) {
      case ExpiryStatus.expired:
        return AppColors.danger;
      case ExpiryStatus.soon:
        return AppColors.warning;
      case ExpiryStatus.safe:
        return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: _statusColor, width: 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _itemImage(context),
            const SizedBox(width: 12),
            Expanded(child: _itemBody(context)),
            if (showMenu)
              Icon(Icons.more_vert, color: AppColors.textSec(context)),
          ],
        ),
      ),
    );
  }

  Widget _itemImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60,
        height: 60,
        color: AppColors.chipBg(context),
        child: item.imageAsset != null
            ? Image.asset(
                item.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('img',
                      style: TextStyle(
                          color: AppColors.textMut(context), fontSize: 12)),
                ),
              )
            : const Center(child: Text('img')),
      ),
    );
  }

  Widget _itemBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (compact)
              Text(
                '${item.daysUntilExpiry} ${item.daysUntilExpiry == 1 ? "Day" : "Days"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        if (!compact)
          Text(
            '${item.category} • ${item.quantity}',
            style: TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 4),
        if (!compact)
          Row(
            children: [
              Icon(
                item.status == ExpiryStatus.expired
                    ? Icons.error_outline
                    : item.status == ExpiryStatus.soon
                        ? Icons.calendar_today
                        : Icons.check_circle_outline,
                color: _statusColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                item.expiryLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          )
        else
          Text(
            item.expiryLabel,
            style: TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 6,
            backgroundColor: AppColors.chipBg(context),
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
          ),
        ),
      ],
    );
  }
}
DART

ok "Widgets updated."

# =============================================================================
# 5. MISC SCREENS — splash, notifications (theme-aware + const-clean)
# =============================================================================
info "Updating misc screens..."

cat > lib/screens/misc/splash_screen.dart <<'DART'
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogoIcon(size: 96),
            const SizedBox(height: 24),
            const AppLogoText(height: 40),
            const SizedBox(height: 8),
            Text(
              'Freshness at your fingertips',
              style: TextStyle(fontSize: 14, color: AppColors.textSec(context)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

cat > lib/screens/misc/notifications_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    {
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.danger,
      'title': 'Whole Milk expires today',
      'subtitle': 'Use it for the Spaghetti Carbonara recipe.',
      'time': '2h ago',
    },
    {
      'icon': Icons.calendar_today,
      'color': AppColors.warning,
      'title': 'Baby Spinach expires in 2 days',
      'subtitle': 'Try our Spinach & Berry Summer Salad.',
      'time': '8h ago',
    },
    {
      'icon': Icons.shopping_cart,
      'color': AppColors.primary,
      'title': 'Milk added to shopping list',
      'subtitle': 'Low stock alert was triggered.',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Notifications',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context)),
          ),
          const SizedBox(height: 16),
          ..._items.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (n['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n['icon'] as IconData,
                          color: n['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPri(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSec(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMut(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
DART

ok "Misc screens updated."

# =============================================================================
# 6. AUTH — login (theme-aware + const-clean)
# =============================================================================
info "Updating login..."

cat > lib/screens/auth/login_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../onboarding/signup_step1_screen.dart';
import '../main/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.asset(
                  'assets/onboarding/login_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFDDE5D4),
                    child: const Center(
                      child: Icon(Icons.kitchen,
                          size: 64, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppLogoIcon(size: 72),
              const SizedBox(height: 16),
              const AppLogoText(height: 38),
              const SizedBox(height: 8),
              Text(
                'Freshness at your fingertips',
                style: TextStyle(fontSize: 14, color: AppColors.textPri(context)),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _login,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider(context)),
                        foregroundColor: AppColors.textPri(context),
                      ),
                      icon: const Icon(Icons.g_mobiledata,
                          color: Colors.red, size: 32),
                      label: const Text('Sign in with Google'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.facebookBlue,
                      ),
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text('Sign in with Facebook'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR EMAIL',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSec(context),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email or Username',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPri(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPri(context),
                          ),
                        ),
                        const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep1Screen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: AppColors.textPri(context), fontSize: 14),
                          children: const [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

ok "Login updated."

# =============================================================================
# 7. ONBOARDING — fixes (signup_step1 overflow, signup_step3 blank body)
# =============================================================================
info "Fixing onboarding screens..."

# ---- signup_step1: fix Birthdate/Gender row overflow on narrow devices -----
cat > lib/screens/onboarding/signup_step1_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'signup_step2_screen.dart';

class SignupStep1Screen extends StatelessWidget {
  const SignupStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppLogoIcon(size: 36),
                  SizedBox(width: 8),
                  AppLogoText(height: 30),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step 1 of 3',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      )),
                  Text('Account Basics',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.33,
                  minHeight: 5,
                  backgroundColor: Color(0xFFCFE7D2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 24),
              Text('Create your account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 8),
              Text(
                "Let's start with some basic information to get your pantry organized.",
                style: TextStyle(
                    color: AppColors.textSec(context), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/onboarding/signup_pantry.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFFE9DCC4),
                    child: const Center(
                      child: Icon(Icons.kitchen, size: 64, color: Colors.brown),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _label(context, 'Full Name'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Enter your full name',
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Email Address'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'example@email.com',
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Password'),
              const SizedBox(height: 6),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Min. 8 characters',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Birthdate + Gender — use LayoutBuilder to avoid right overflow.
              LayoutBuilder(
                builder: (_, c) {
                  // On narrow screens, stack vertically. Otherwise side-by-side.
                  final stacked = c.maxWidth < 340;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context, 'Birthdate'),
                        const SizedBox(height: 6),
                        const TextField(
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(context, 'Gender'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          hint: const Text('Select'),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                            DropdownMenuItem(value: 'O', child: Text('Other')),
                            DropdownMenuItem(value: 'N', child: Text('Prefer not to say')),
                          ],
                          onChanged: (_) {},
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Birthdate'),
                            const SizedBox(height: 6),
                            const TextField(
                              decoration: InputDecoration(
                                hintText: 'mm/dd/yyyy',
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Gender'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(isDense: true),
                              hint: const Text('Select'),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Male')),
                                DropdownMenuItem(value: 'F', child: Text('Female')),
                                DropdownMenuItem(value: 'O', child: Text('Other')),
                                DropdownMenuItem(value: 'N', child: Text('Other...')),
                              ],
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignupStep2Screen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next Step'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: AppColors.textPri(context), fontSize: 14),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSec(context)),
                    children: const [
                      TextSpan(text: "By continuing, you agree to ShelfLife's "),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Text(
        s,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPri(context),
        ),
      );
}
DART

# ---- signup_step2 — theme-aware + const cleanup ----------------------------
cat > lib/screens/onboarding/signup_step2_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'signup_step3_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});
  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final Set<String> _selected = {'Vegan'};

  final _options = const [
    {'label': 'Vegan', 'icon': Icons.eco, 'color': AppColors.primaryLight, 'iconColor': AppColors.primaryDark},
    {'label': 'Keto', 'icon': Icons.flash_on, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFB45309)},
    {'label': 'Vegetarian', 'icon': Icons.hotel, 'color': AppColors.primaryLight, 'iconColor': AppColors.primaryDark},
    {'label': 'Paleo', 'icon': Icons.restaurant, 'color': Color(0xFFFFEBEE), 'iconColor': AppColors.danger},
    {'label': 'Gluten-free', 'icon': Icons.grain, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFB45309)},
    {'label': 'Dairy-free', 'icon': Icons.ac_unit, 'color': Color(0xFFE3F2FD), 'iconColor': Color(0xFF1976D2)},
    {'label': 'Pescatarian', 'icon': Icons.set_meal, 'color': Color(0xFFE3F2FD), 'iconColor': Color(0xFF1976D2)},
    {'label': 'Low Carb', 'icon': Icons.trending_down, 'color': Color(0xFFFFF3E0), 'iconColor': AppColors.danger},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.textPri(context)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ONBOARDING',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            )),
                        Text('Step 2 of 3',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPri(context),
                            )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.66,
                        minHeight: 5,
                        backgroundColor: Color(0xFFCFE7D2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Dietary Preferences',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply. This helps us suggest the best recipes and pantry tips for you.',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (_, i) {
                        final opt = _options[i];
                        final label = opt['label'] as String;
                        final isSelected = _selected.contains(label);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selected.remove(label);
                            } else {
                              _selected.add(label);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: opt['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(opt['icon'] as IconData,
                                            color: opt['iconColor'] as Color,
                                            size: 28),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: AppColors.textPri(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primaryDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can always update these preferences later in your Profile settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPri(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.divider(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep3Screen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

# ---- signup_step3 — FIX BLANK BODY BUG, theme-aware, const-clean -----------
# v1 bug: header was at top of Column with a SizedBox.expand(SingleChildScrollView)
# below it that had its own Padding. Some flex configurations caused the
# Expanded(SingleChildScrollView) to collapse. Solution: simpler structure
# using a CustomScrollView-free layout: header is a normal Container,
# scroll body is Expanded(ListView).
cat > lib/screens/onboarding/signup_step3_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../main/main_shell.dart';

class SignupStep3Screen extends StatefulWidget {
  const SignupStep3Screen({super.key});
  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  final Set<String> _selected = {'Peanuts', 'Soy'};
  static const _common = [
    'Peanuts', 'Dairy', 'Soy', 'Shellfish',
    'Gluten', 'Tree Nuts', 'Eggs', 'Fish',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ---- TOP BAR ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      AppLogoIcon(size: 32),
                      SizedBox(width: 8),
                      AppLogoText(height: 30),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none,
                        color: AppColors.textPri(context)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // ---- BODY (scrollable) ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                children: [
                  const Text('STEP 3 OF 3',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 6),
                  Text('Food Allergies',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    "We'll help you spot these in recipes and product labels.",
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search allergies (e.g., Peanuts, Dairy)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Common Allergens',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _common.map((label) {
                      final isSelected = _selected.contains(label);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selected.remove(label);
                          } else {
                            _selected.add(label);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.card(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPri(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Did you know?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPri(context),
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                'Selecting allergies will automatically highlight unsafe items in your pantry and recipes.',
                                style: TextStyle(
                                  color: AppColors.textPri(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/onboarding/allergies_food.png',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: const Color(0xFFEDE7DC),
                            child: const Center(
                              child: Icon(Icons.restaurant_menu,
                                  size: 64, color: Colors.brown),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Safety First',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // ---- BOTTOM BUTTONS ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider(context)),
                      foregroundColor: AppColors.textPri(context),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Previous'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (_) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Start My Pantry'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

ok "Onboarding screens fixed."

# =============================================================================
# 8. MAIN SCREENS — home, pantry, add_item, recipe (theme-aware, const-clean)
# =============================================================================
info "Updating main screens..."

# ---- home_screen.dart ------------------------------------------------------
cat > lib/screens/main/home_screen.dart <<'DART'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text('Pantry Insights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context: context,
                  label: 'Total Items',
                  value: '124',
                  trailing: const Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.safe, size: 16),
                      SizedBox(width: 4),
                      Text('+12%',
                          style: TextStyle(
                              color: AppColors.safe,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  context: context,
                  label: 'Expiring Soon',
                  value: '08',
                  valueColor: AppColors.warning,
                  trailing: Text('Next 48h',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _wasteCard(context),
          const SizedBox(height: 16),
          _suggestedGroceriesCard(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Use First',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...SampleData.useFirst.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PantryItemCard(item: item, compact: true),
              )),
        ],
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _wasteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wasted Items',
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 13)),
                const SizedBox(height: 8),
                const Text('14.2%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    )),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 70,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barGroups: [
                    _bar(0, 5),
                    _bar(1, 6),
                    _bar(2, 3),
                    _bar(3, 9, color: AppColors.danger),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BarChartGroupData _bar(int x, double y,
      {Color color = const Color(0xFFF77272)}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _suggestedGroceriesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suggested Groceries',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              Icon(Icons.shopping_cart_outlined,
                  color: AppColors.textPri(context)),
            ],
          ),
          const SizedBox(height: 12),
          ...SampleData.suggestedGroceries.map((g) {
            final type = g['type']!;
            final reasonColor = type == 'expired'
                ? AppColors.danger
                : type == 'low'
                    ? AppColors.warning
                    : AppColors.textSec(context);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context),
                                )),
                            const SizedBox(height: 2),
                            Text(g['reason']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: reasonColor,
                                  fontWeight: type != 'recipe'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 28),
                    ],
                  ),
                  if (g != SampleData.suggestedGroceries.last)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Divider(
                          height: 1, color: AppColors.divider(context)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
DART

# ---- pantry_screen.dart ----------------------------------------------------
cat > lib/screens/main/pantry_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/pantry_item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _filter = 'All Items';
  static const _filters = ['All Items', 'Dairy', 'Produce', 'Meat'];

  List<PantryItem> get _filteredItems {
    if (_filter == 'All Items') return SampleData.pantry;
    return SampleData.pantry.where((i) => i.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search your pantry...',
              filled: true,
              fillColor: AppColors.card(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final selected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.chipUnsel(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPri(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          ..._filteredItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PantryItemCard(item: item, showMenu: true),
              )),
        ],
      ),
    );
  }
}
DART

# ---- add_item_screen.dart — fix deprecated `value:`, theme-aware -----------
cat > lib/screens/main/add_item_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  int _mode = 0;
  int _qty = 1;
  String _category = 'Meat & Poultry';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _modeToggle(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Inventory',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.playlist_add, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text('Quick-add mode',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mode == 0 ? _manualForm(context) : _barcodePlaceholder(context),
          const SizedBox(height: 24),
          Text('Recently Added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _recentCard(context, 'Produce', 'Organic Kale', 'Qty: 2',
                    AppColors.primaryDark),
                const SizedBox(width: 10),
                _recentCard(context, 'Dairy', 'Whole Milk', 'Qty: 1 gal',
                    AppColors.warning),
                const SizedBox(width: 10),
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/onboarding/login_bg.png',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    color: const Color(0xFFCFE7D2),
                    child: const Center(
                      child: Icon(Icons.kitchen,
                          size: 48, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 14,
                child: Text(
                  'Keep your pantry fresh and organized.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chipUnsel(context),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(child: _modeBtn(context, 'Manual Entry', 0)),
          Expanded(child: _modeBtn(context, 'Barcode Scan', 1)),
        ],
      ),
    );
  }

  Widget _modeBtn(BuildContext context, String label, int idx) {
    final selected = _mode == idx;
    return GestureDetector(
      onTap: () => setState(() => _mode = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPri(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _manualForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.primaryDark, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formLabel(context, 'Item name'),
          const SizedBox(height: 6),
          const TextField(
            decoration:
                InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel(context, 'Quantity'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider(context)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove,
                                color: AppColors.primaryDark),
                            onPressed: () => setState(
                                () => _qty = _qty > 1 ? _qty - 1 : 1),
                          ),
                          Expanded(
                            child: Text('$_qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPri(context),
                                )),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add,
                                color: AppColors.primaryDark),
                            onPressed: () => setState(() => _qty += 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel(context, 'Category'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _category, // FIXED: was `value:` (deprecated)
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        'Meat & Poultry',
                        'Dairy',
                        'Produce',
                        'Grains',
                        'Other',
                      ]
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _formLabel(context, 'Expiry Date'),
          const SizedBox(height: 6),
          const TextField(
            decoration: InputDecoration(
              hintText: 'dd/mm/yyyy',
              suffixIcon: Icon(Icons.calendar_today, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Best-before suggestion',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh poultry typically lasts 2-3 days in the fridge. Suggested date: Oct 27, 2023.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPri(context)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Text('Apply suggestion',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                )),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                color: AppColors.primaryDark, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barcodePlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(context), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner,
              size: 80, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text('Point camera at barcode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 8),
          Text(
            'Scanner will be enabled in the next build.',
            style: TextStyle(
                color: AppColors.textSec(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _recentCard(BuildContext context, String category, String name,
      String qty, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
          const SizedBox(height: 4),
          Text(name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(qty,
              style: TextStyle(
                color: AppColors.textSec(context),
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  Widget _formLabel(BuildContext context, String s) => Text(s,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSec(context),
      ));
}
DART

# ---- recipe_screen.dart — theme-aware --------------------------------------
cat > lib/screens/main/recipe_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final List<String> _selectedIngredients = ['Chicken Breast', 'Bell Peppers'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Use First Suggestions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _featuredCard(SampleData.featuredRecipe),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallRecipe(SampleData.smallRecipes[0])),
              const SizedBox(width: 12),
              Expanded(child: _smallRecipe(SampleData.smallRecipes[1])),
            ],
          ),
          const SizedBox(height: 24),
          Text('Find by Ingredients',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedIngredients.map((i) => Chip(
                    label: Text(i,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                    backgroundColor: AppColors.primaryLight,
                    deleteIcon: const Icon(Icons.close,
                        size: 16, color: AppColors.primaryDark),
                    onDeleted: () =>
                        setState(() => _selectedIngredients.remove(i)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  )),
              ActionChip(
                label: Icon(Icons.add,
                    size: 18, color: AppColors.textPri(context)),
                backgroundColor: AppColors.card(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.divider(context)),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Matches for you',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          ...SampleData.matches.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _matchCard(context, r),
              )),
        ],
      ),
    );
  }

  Widget _featuredCard(Recipe r) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            r.imageAsset!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: const Color(0xFF6B7280),
              child: const Center(
                child: Icon(Icons.restaurant, size: 64, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('HIGH URGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    )),
              ),
              const SizedBox(height: 8),
              Text(r.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              const Text('Uses your expiring spinach and strawberries.',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallRecipe(Recipe r) {
    return Container(
      height: 130,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              r.imageAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF6B7280),
                child: const Center(
                  child: Icon(Icons.restaurant, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 10,
            child: Text(r.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, Recipe r) {
    final accent = r.allFound ? AppColors.safe : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              r.imageAsset!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.chipBg(context),
                child: Icon(Icons.restaurant,
                    color: AppColors.textMut(context)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 4),
                Text('${r.time} • ${r.difficulty}',
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 13)),
                const SizedBox(height: 6),
                if (r.allFound)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ALL INGREDIENTS FOUND',
                        style: TextStyle(
                          color: AppColors.safe,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        )),
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('1 MISSING',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Text(r.missingNote ?? '',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: AppColors.textSec(context),
                          )),
                    ],
                  ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: AppColors.warning),
        ],
      ),
    );
  }
}
DART

ok "Main screens updated."

# =============================================================================
# 9. PROFILE SCREEN — user info, dark mode toggle wired, new screens links
# =============================================================================
info "Updating profile screen..."

cat > lib/screens/main/profile_screen.dart <<'DART'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/main_app_bar.dart';
import '../auth/login_screen.dart';
import '../misc/edit_profile_screen.dart';
import '../misc/privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final darkOn = themeController.value == ThemeMode.dark;
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _avatar(),
          const SizedBox(height: 12),
          Center(
            child: Text('Anubhav Silwal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
          ),
          Center(
            child: Text('anubhav@shelflife.app',
                style: TextStyle(
                    color: AppColors.textSec(context), fontSize: 14)),
          ),
          const SizedBox(height: 20),
          _settingsCard(context, darkOn),
          const SizedBox(height: 14),
          _dietaryCard(context),
          const SizedBox(height: 14),
          _allergiesCard(context),
          const SizedBox(height: 14),
          _analyticsCard(context),
          const SizedBox(height: 14),
          _navTile(context, Icons.manage_accounts, 'Edit Profile Details', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          }),
          const SizedBox(height: 10),
          _navTile(context, Icons.shield_outlined, 'Privacy & Data', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            );
          }),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Delete Account',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('ShelfLife Version 2.4.0 (2024)',
                style: TextStyle(
                    color: AppColors.textMut(context), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.chipBg(context),
              child: ClipOval(
                child: Image.asset(
                  'assets/profile/avatar_default.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textMut(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, bool darkOn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Settings',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Dark Mode',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textPri(context))),
              ),
              Switch(
                value: darkOn,
                onChanged: (v) {
                  themeController.value =
                      v ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Push Notifications',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textPri(context))),
              ),
              Switch(
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dietaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Dietary Focus',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.restaurant, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Vegetarian', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Organic', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Gluten-Free', const Color(0xFFFFF3E0), const Color(0xFFB45309)),
              _pill('+ Add Focus', AppColors.chipBg(context), AppColors.textPri(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allergiesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.danger, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Allergies & Sensitivities',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          _allergyRow(context, 'Peanuts & Tree Nuts'),
          const SizedBox(height: 8),
          _allergyRow(context, 'Shellfish'),
        ],
      ),
    );
  }

  Widget _allergyRow(BuildContext context, String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(s,
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textPri(context)))),
          Icon(Icons.close, color: AppColors.textPri(context), size: 20),
        ],
      ),
    );
  }

  Widget _analyticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Pantry Analytics',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.bar_chart, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waste Reduction',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSec(context))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const labels = ['Jan', 'Feb', 'Mar', 'Apr'];
                                  if (v.toInt() < 0 ||
                                      v.toInt() >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    labels[v.toInt()],
                                    style: TextStyle(
                                      color: AppColors.textSec(context),
                                      fontSize: 11,
                                    ),
                                  );
                                },
                                reservedSize: 20,
                              ),
                            ),
                          ),
                          minX: 0, maxX: 3,
                          minY: 0, maxY: 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 7),
                                FlSpot(1, 6),
                                FlSpot(2, 4),
                                FlSpot(3, 3),
                              ],
                              isCurved: true,
                              color: AppColors.primaryDark,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Distribution',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSec(context))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              startDegreeOffset: 270,
                              sections: [
                                PieChartSectionData(
                                  value: 60,
                                  color: AppColors.primaryDark,
                                  radius: 14,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 40,
                                  color: AppColors.primaryLight,
                                  radius: 14,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('42',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPri(context),
                                  )),
                              Text('items',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSec(context))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                            color: AppColors.primaryDark, label: 'Produce'),
                        SizedBox(width: 10),
                        _LegendDot(
                            color: AppColors.primaryLight, label: 'Dairy'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _navTile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPri(context),
                  )),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSec(context)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.textSec(context))),
      ],
    );
  }
}
DART

ok "Profile updated."

# =============================================================================
# 10. NEW SCREENS — Edit Profile + Privacy & Data
# =============================================================================
info "Adding Edit Profile and Privacy screens..."

# ---- edit_profile_screen.dart ----------------------------------------------
cat > lib/screens/misc/edit_profile_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Anubhav Silwal');
  final _emailCtrl = TextEditingController(text: 'anubhav@shelflife.app');
  final _phoneCtrl = TextEditingController(text: '+977 98XXXXXXXX');
  final _bdayCtrl = TextEditingController(text: '07/15/1999');
  String _gender = 'Male';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bdayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text('Edit Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text('Update your personal information.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 14)),
          const SizedBox(height: 24),
          // ---- Avatar ----
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryLight, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.chipBg(context),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/profile/avatar_default.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 56,
                          color: AppColors.textMut(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Change Photo',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'Personal Info', [
            _label(context, 'Full Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Email Address'),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Phone Number'),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Birthdate'),
            const SizedBox(height: 6),
            TextField(
              controller: _bdayCtrl,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Gender'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(value: 'N/A', child: Text('Prefer not to say')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Password', [
            _label(context, 'Current Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Enter current password',
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'New Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_reset),
                hintText: 'At least 8 characters',
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Confirm New Password'),
            const SizedBox(height: 6),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                hintText: 'Re-enter new password',
              ),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: AppColors.bg(context),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully.')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Text(
        s,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.textSec(context),
        ),
      );
}
DART

# ---- privacy_screen.dart ---------------------------------------------------
cat > lib/screens/misc/privacy_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareUsage = true;
  bool _personalizedRecs = true;
  bool _locationData = false;
  bool _crashReports = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Privacy & Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(
            'Control how your data is used and stored.',
            style: TextStyle(
                color: AppColors.textSec(context), fontSize: 14),
          ),
          const SizedBox(height: 24),
          // ---- Data Sharing ----
          _section(context, 'Data Sharing', [
            _switchRow(
              context,
              'Share Anonymous Usage Data',
              'Help us improve ShelfLife with anonymous analytics.',
              Icons.bar_chart,
              _shareUsage,
              (v) => setState(() => _shareUsage = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Personalized Recommendations',
              'Use your pantry history to suggest better recipes.',
              Icons.recommend,
              _personalizedRecs,
              (v) => setState(() => _personalizedRecs = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Location Data',
              'Find seasonal recipes for your region.',
              Icons.location_on_outlined,
              _locationData,
              (v) => setState(() => _locationData = v),
            ),
            _divider(context),
            _switchRow(
              context,
              'Crash & Error Reports',
              'Automatically send crash logs to help us fix bugs.',
              Icons.bug_report_outlined,
              _crashReports,
              (v) => setState(() => _crashReports = v),
            ),
          ]),
          const SizedBox(height: 16),
          // ---- Data Management ----
          _section(context, 'Your Data', [
            _navRow(context, Icons.cloud_download_outlined,
                'Download My Data', 'Get a copy of your pantry data in CSV.', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Your data export will be ready shortly.')),
              );
            }),
            _divider(context),
            _navRow(context, Icons.history, 'View Login Activity',
                'See recent sign-ins to your account.', () {}),
            _divider(context),
            _navRow(context, Icons.devices_other,
                'Connected Devices', 'Manage where you\'re signed in.', () {}),
          ]),
          const SizedBox(height: 16),
          // ---- Documents ----
          _section(context, 'Legal', [
            _navRow(context, Icons.description_outlined, 'Privacy Policy', null,
                () {}),
            _divider(context),
            _navRow(context, Icons.gavel_outlined, 'Terms of Service', null,
                () {}),
            _divider(context),
            _navRow(context, Icons.cookie_outlined, 'Cookie Preferences', null,
                () {}),
          ]),
          const SizedBox(height: 20),
          // ---- Destructive actions ----
          OutlinedButton.icon(
            onPressed: () => _showClearDialog(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              foregroundColor: AppColors.danger,
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear All Pantry Data'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'For more info, visit shelflife.app/privacy',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMut(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helpers -------------------------------------------------------------

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, IconData icon, String title,
      String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPri(context),
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSec(context)),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: AppColors.divider(context));

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Pantry Data?'),
        content: const Text(
          'This will permanently remove all your pantry items, recipes, and shopping list. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All pantry data cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
DART

ok "Edit Profile + Privacy screens added."

# =============================================================================
# 11. SHOPPING LIST — theme-aware (no UI changes, just dark-mode support)
# =============================================================================
info "Updating shopping list for dark mode..."

cat > lib/screens/shopping/shopping_list_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/shopping_item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final List<ShoppingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = SampleData.shoppingList();
  }

  int get _checkedCount => _items.where((i) => i.checked).length;

  void _addCheckedToPantry() {
    final count = _checkedCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tick items first to add them to pantry.')),
      );
      return;
    }
    setState(() => _items.removeWhere((i) => i.checked));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count item(s) added to pantry.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: isDark ? AppColors.primary : AppColors.primaryDark),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shopping List',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                Text('${_items.length} items',
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = _items[i];
                return InkWell(
                  onTap: () => setState(() => item.checked = !item.checked),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.checked,
                          onChanged: (v) =>
                              setState(() => item.checked = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: item.checked
                                      ? AppColors.textMut(context)
                                      : AppColors.textPri(context),
                                  decoration: item.checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.note != null) ...[
                                const SizedBox(height: 2),
                                Text(item.note!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec(context),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.textSec(context)),
                          onPressed: () =>
                              setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: AppColors.bg(context),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _addCheckedToPantry,
            icon: const Icon(Icons.kitchen),
            label: Text(_checkedCount > 0
                ? 'Add $_checkedCount item(s) to Pantry'
                : 'Add Checked Items to Pantry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Shopping List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Olive Oil'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _items.add(ShoppingItem(name: name)));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
DART

ok "Shopping list updated."

# =============================================================================
# 12. Run dart fix and pub get
# =============================================================================
info "Running dart fix to clean any remaining lints..."
if command -v dart >/dev/null 2>&1; then
  dart fix --apply 2>/dev/null || warn "dart fix had warnings — non-fatal."
  ok "dart fix complete."
else
  warn "dart command not found, skipping."
fi

info "Running flutter pub get..."
if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  ok "Dependencies installed."
else
  warn "flutter command not found. Run 'flutter pub get' manually."
fi

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  ShelfLife v2 update complete!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo
echo "What changed in v2:"
echo "  ✓ Shopping cart icon (replaced basket) in main top bar"
echo "  ✓ Full app-wide dark mode — toggle on Profile > Dark Mode"
echo "  ✓ Edit Profile Details screen (tap on Profile)"
echo "  ✓ Privacy & Data screen (tap on Profile)"
echo "  ✓ Bottom-nav active indicator is now circular"
echo "  ✓ Add (+) button uses darker green"
echo "  ✓ User: Anubhav Silwal / anubhav@shelflife.app"
echo "  ✓ Fixed: bottom overflow in main screens"
echo "  ✓ Fixed: signup step 1 right overflow"
echo "  ✓ Fixed: signup step 3 blank body"
echo "  ✓ Fixed: SVG missing-asset crashes (now silent fallback)"
echo "  ✓ Fixed: all const/lint warnings + deprecated DropdownButtonFormField"
echo
echo "Next steps:"
echo "  1. In Android Studio: File → Invalidate Caches / Restart"
echo "  2. flutter run"
echo
echo "About error #16 (INSUFFICIENT_STORAGE):"
echo "  Your Android emulator is out of space — not a code bug."
echo "  Fix: Tools → Device Manager → ⋮ → Wipe Data on that emulator."
echo
echo "Rollback to v1 (if using git):"
echo "  git reset --hard v1"
echo