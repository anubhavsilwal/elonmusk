#!/usr/bin/env bash
# =============================================================================
# ShelfLife Flutter App — Project Scaffolding Script
# =============================================================================
# Run this from the ROOT of your Flutter project (the `demoui/` folder).
# It will:
#   1. Update pubspec.yaml with required dependencies
#   2. Create asset folders (you drop images in afterwards)
#   3. Build out the full lib/ structure with theme, models, screens, widgets
#   4. Run `flutter pub get`
#
# Usage:
#   cd /Users/anubhavsilwal/StudioProjects/demoui
#   chmod +x 1.sh
#   ./1.sh
# =============================================================================

set -e

# ---- Pretty output helpers --------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()     { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()    { echo -e "${RED}[ERR]${NC}  $1"; }

# ---- Sanity check -----------------------------------------------------------
if [ ! -f "pubspec.yaml" ]; then
  err "pubspec.yaml not found. Run this from the project root (demoui/)."
  exit 1
fi

info "Starting ShelfLife scaffolding..."

# =============================================================================
# 1. ASSET FOLDERS
# =============================================================================
info "Creating asset folders..."
mkdir -p assets/logo
mkdir -p assets/items
mkdir -p assets/recipes
mkdir -p assets/onboarding
mkdir -p assets/profile

cat > assets/README.md <<'README'
# ShelfLife Assets

## Required Files

### `assets/logo/`
- `shelflife_logo.svg`  — the "ShelfLife" green text logo used in headers
- `shelflife_icon.svg`  — the green basket app icon (used on splash & login)

### `assets/items/`  (pantry & home screen)
- `whole_milk.png`
- `baby_spinach.png`
- `greek_yogurt.png`
- `avocados.png`
- `strawberries.png`
- `baby_carrots.png`
- `chicken_breast.png`
- `chicken_breast_2.png`
- `large_eggs.png`
- `salted_butter.png`
- `red_bell_peppers.png`
- `organic_kale.png`

### `assets/recipes/`
- `spinach_berry_salad.png`
- `zucchini_leek_soup.png`
- `berry_compote_parfait.png`
- `lemon_garlic_stirfry.png`
- `honey_glazed_chicken.png`
- `rainbow_veggie_wrap.png`

### `assets/onboarding/`
- `login_bg.png`         — pantry shelves background for login screen
- `signup_pantry.png`    — jars image on signup step 1
- `allergies_food.png`   — food spread image on allergies step 3

### `assets/profile/`
- `avatar_default.png`   — default user avatar
README

ok "Asset folders created. See assets/README.md for filenames to drop in."

# =============================================================================
# 2. pubspec.yaml
# =============================================================================
info "Writing pubspec.yaml..."

# Detect project name from existing pubspec
PROJECT_NAME=$(grep -E "^name:" pubspec.yaml | head -1 | awk '{print $2}')
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME="demoui"
fi

cat > pubspec.yaml <<EOF
name: $PROJECT_NAME
description: "ShelfLife - Pantry management app."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  fl_chart: ^0.69.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/logo/
    - assets/items/
    - assets/recipes/
    - assets/onboarding/
    - assets/profile/
EOF

ok "pubspec.yaml written."

# =============================================================================
# 3. lib/ STRUCTURE
# =============================================================================
info "Building lib/ folder structure..."

# Remove old main.dart, we will rewrite everything
rm -f lib/main.dart

mkdir -p lib/theme
mkdir -p lib/models
mkdir -p lib/data
mkdir -p lib/widgets
mkdir -p lib/screens/auth
mkdir -p lib/screens/onboarding
mkdir -p lib/screens/main
mkdir -p lib/screens/shopping
mkdir -p lib/screens/misc

# ---- lib/main.dart ---------------------------------------------------------
cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
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
    return MaterialApp(
      title: 'ShelfLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
DART

# ---- lib/theme/app_colors.dart ---------------------------------------------
cat > lib/theme/app_colors.dart <<'DART'
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary       = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF2E7D32);
  static const Color primaryLight  = Color(0xFFE8F5E9);

  // Surfaces
  static const Color background    = Color(0xFFF5F6FA);
  static const Color card          = Colors.white;
  static const Color divider       = Color(0xFFE5E7EB);

  // Status
  static const Color warning       = Color(0xFFFF9800);
  static const Color warningLight  = Color(0xFFFFF4E5);
  static const Color danger        = Color(0xFFF44336);
  static const Color dangerLight   = Color(0xFFFFEBEE);
  static const Color safe          = Color(0xFF16A34A);
  static const Color safeLight     = Color(0xFFE8F5E9);

  // Text
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);

  // Social
  static const Color facebookBlue  = Color(0xFF1877F2);

  // Chips
  static const Color chipUnselected = Color(0xFFE3F2FD);
  static const Color chipBg         = Color(0xFFF3F4F6);

  // Info banner
  static const Color infoBg         = Color(0xFFEFF6FF);
}
DART

# ---- lib/theme/app_theme.dart ----------------------------------------------
cat > lib/theme/app_theme.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
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
        color: AppColors.card,
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
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
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

# ---- lib/models/pantry_item.dart -------------------------------------------
cat > lib/models/pantry_item.dart <<'DART'
import 'package:flutter/material.dart';

enum ExpiryStatus { safe, soon, expired }

class PantryItem {
  final String name;
  final String category;
  final String quantity;
  final int daysUntilExpiry;
  final String expiryLabel; // e.g. "Exp: Oct 24"
  final String? imageAsset;
  final double progress;     // 0.0 -> 1.0, how full the colored progress bar is

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

# ---- lib/models/recipe.dart ------------------------------------------------
cat > lib/models/recipe.dart <<'DART'
class Recipe {
  final String title;
  final String time;
  final String difficulty;
  final String? imageAsset;
  final bool allFound;
  final String? missingNote;
  final bool urgent;

  const Recipe({
    required this.title,
    required this.time,
    required this.difficulty,
    this.imageAsset,
    this.allFound = true,
    this.missingNote,
    this.urgent = false,
  });
}
DART

# ---- lib/models/shopping_item.dart -----------------------------------------
cat > lib/models/shopping_item.dart <<'DART'
class ShoppingItem {
  final String name;
  final String? note;
  bool checked;

  ShoppingItem({
    required this.name,
    this.note,
    this.checked = false,
  });
}
DART

# ---- lib/data/sample_data.dart ---------------------------------------------
cat > lib/data/sample_data.dart <<'DART'
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class SampleData {
  // ---- Home: Use First -----------------------------------------------------
  static const List<PantryItem> useFirst = [
    PantryItem(
      name: 'Whole Milk (1L)',
      category: 'Dairy',
      quantity: '1L',
      daysUntilExpiry: 1,
      expiryLabel: 'Expires tomorrow',
      progress: 0.2,
      imageAsset: 'assets/items/whole_milk.png',
    ),
    PantryItem(
      name: 'Baby Spinach',
      category: 'Produce',
      quantity: '1 bag',
      daysUntilExpiry: 2,
      expiryLabel: 'Exp: Oct 24',
      progress: 0.4,
      imageAsset: 'assets/items/baby_spinach.png',
    ),
    PantryItem(
      name: 'Greek Yogurt',
      category: 'Dairy',
      quantity: '1 tub',
      daysUntilExpiry: 3,
      expiryLabel: 'Exp: Oct 25',
      progress: 0.5,
      imageAsset: 'assets/items/greek_yogurt.png',
    ),
    PantryItem(
      name: 'Avocados (2x)',
      category: 'Produce',
      quantity: '2 units',
      daysUntilExpiry: 5,
      expiryLabel: 'Exp: Oct 27',
      progress: 0.7,
      imageAsset: 'assets/items/avocados.png',
    ),
    PantryItem(
      name: 'Strawberries',
      category: 'Produce',
      quantity: '1 pack',
      daysUntilExpiry: 6,
      expiryLabel: 'Exp: Oct 28',
      progress: 0.85,
      imageAsset: 'assets/items/strawberries.png',
    ),
  ];

  // ---- Pantry full list ----------------------------------------------------
  static const List<PantryItem> pantry = [
    PantryItem(
      name: 'Whole Milk',
      category: 'Dairy',
      quantity: '1 Gallon',
      daysUntilExpiry: 0,
      expiryLabel: 'Expires Today',
      progress: 0.95,
      imageAsset: 'assets/items/whole_milk.png',
    ),
    PantryItem(
      name: 'Baby Carrots',
      category: 'Produce',
      quantity: '2 Bags',
      daysUntilExpiry: 3,
      expiryLabel: 'Expires in 3 days',
      progress: 0.6,
      imageAsset: 'assets/items/baby_carrots.png',
    ),
    PantryItem(
      name: 'Chicken Breast',
      category: 'Meat',
      quantity: '1.5 lbs',
      daysUntilExpiry: 12,
      expiryLabel: 'Expires in 12 days',
      progress: 0.4,
      imageAsset: 'assets/items/chicken_breast.png',
    ),
    PantryItem(
      name: 'Avocados',
      category: 'Produce',
      quantity: '3 units',
      daysUntilExpiry: 8,
      expiryLabel: 'Expires in 8 days',
      progress: 0.55,
      imageAsset: 'assets/items/avocados.png',
    ),
    PantryItem(
      name: 'Chicken Breast',
      category: 'Meat',
      quantity: '1 lb',
      daysUntilExpiry: 4,
      expiryLabel: 'Expires in 4 days (Oct 26)',
      progress: 0.7,
      imageAsset: 'assets/items/chicken_breast_2.png',
    ),
    PantryItem(
      name: 'Large Eggs (12pk)',
      category: 'Dairy',
      quantity: '1 Carton',
      daysUntilExpiry: 8,
      expiryLabel: 'Expires in 8 days (Oct 30)',
      progress: 1.0,
      imageAsset: 'assets/items/large_eggs.png',
    ),
    PantryItem(
      name: 'Salted Butter',
      category: 'Dairy',
      quantity: '4 sticks',
      daysUntilExpiry: 12,
      expiryLabel: 'Expires in 12 days (Nov 3)',
      progress: 0.5,
      imageAsset: 'assets/items/salted_butter.png',
    ),
    PantryItem(
      name: 'Red Bell Peppers',
      category: 'Produce',
      quantity: '2 units',
      daysUntilExpiry: 3,
      expiryLabel: 'Expires in 3 days (Oct 25)',
      progress: 0.8,
      imageAsset: 'assets/items/red_bell_peppers.png',
    ),
  ];

  // ---- Recipes -------------------------------------------------------------
  static const Recipe featuredRecipe = Recipe(
    title: 'Spinach & Berry Summer Salad',
    time: '15 mins',
    difficulty: 'Easy',
    imageAsset: 'assets/recipes/spinach_berry_salad.png',
    urgent: true,
  );

  static const List<Recipe> smallRecipes = [
    Recipe(
      title: 'Zucchini & Leek Cream Soup',
      time: '30 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/zucchini_leek_soup.png',
    ),
    Recipe(
      title: 'Berry Compote Parfait',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/berry_compote_parfait.png',
    ),
  ];

  static const List<Recipe> matches = [
    Recipe(
      title: 'Lemon Garlic Stir-Fry',
      time: '20 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/lemon_garlic_stirfry.png',
      allFound: true,
    ),
    Recipe(
      title: 'Honey Glazed Chicken',
      time: '35 mins',
      difficulty: 'Medium',
      imageAsset: 'assets/recipes/honey_glazed_chicken.png',
      allFound: false,
      missingNote: 'Need: Honey',
    ),
    Recipe(
      title: 'Rainbow Veggie Wrap',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/rainbow_veggie_wrap.png',
      allFound: true,
    ),
  ];

  // ---- Suggested Groceries on Home ----------------------------------------
  static const List<Map<String, String>> suggestedGroceries = [
    {'name': 'Pancetta', 'reason': 'Expired', 'type': 'expired'},
    {
      'name': 'Parmesan',
      'reason': 'From recipe: Spaghetti Carbonara',
      'type': 'recipe',
    },
    {'name': 'Milk', 'reason': 'Low stock', 'type': 'low'},
  ];

  // ---- Shopping list -------------------------------------------------------
  static List<ShoppingItem> shoppingList() => [
        ShoppingItem(name: 'Pancetta', note: 'Expired item'),
        ShoppingItem(name: 'Parmesan', note: 'From recipe: Spaghetti Carbonara'),
        ShoppingItem(name: 'Milk', note: 'Low stock'),
        ShoppingItem(name: 'Whole-Wheat Bread'),
        ShoppingItem(name: 'Olive Oil', note: 'Almost out'),
        ShoppingItem(name: 'Fresh Basil'),
        ShoppingItem(name: 'Tomatoes (6)'),
      ];
}
DART

ok "Theme, models and sample data written."

# =============================================================================
# 4. SHARED WIDGETS
# =============================================================================
info "Writing shared widgets..."

# ---- lib/widgets/app_logo.dart ---------------------------------------------
cat > lib/widgets/app_logo.dart <<'DART'
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
DART

# ---- lib/widgets/main_app_bar.dart -----------------------------------------
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
DART

# ---- lib/widgets/bottom_nav.dart -------------------------------------------
cat > lib/widgets/bottom_nav.dart <<'DART'
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/main/main_shell.dart';

/// Bottom navigation bar shared by all main-app screens.
/// 5 tabs: Home / Pantry / [+Add FAB center] / Recipe / Profile
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(context, 1, Icons.kitchen_outlined, Icons.kitchen,
                  'Pantry'),
              _addButton(context),
              _navItem(context, 3, Icons.receipt_long_outlined,
                  Icons.receipt_long, 'Recipe'),
              _navItem(context, 4, Icons.person_outline, Icons.person,
                  'Profile'),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(iconActive, color: Colors.white, size: 22),
                )
              else
                Icon(icon, color: AppColors.textPrimary, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 2),
              Text(
                'Add',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
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

# ---- lib/widgets/pantry_item_card.dart -------------------------------------
cat > lib/widgets/pantry_item_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../theme/app_colors.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final bool compact; // home use-first style if true
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
          color: Colors.white,
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
            _itemImage(),
            const SizedBox(width: 12),
            Expanded(child: _itemBody()),
            if (showMenu)
              const Icon(Icons.more_vert, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _itemImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60,
        height: 60,
        color: const Color(0xFFE5E7EB),
        child: item.imageAsset != null
            ? Image.asset(
                item.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Text('img', style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12))),
              )
            : const Center(child: Text('img')),
      ),
    );
  }

  Widget _itemBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFEEF2F7),
            valueColor: AlwaysStoppedAnimation(_statusColor),
          ),
        ),
      ],
    );
  }
}
DART

ok "Shared widgets written."

# =============================================================================
# 5. MISC SCREENS (splash, notifications)
# =============================================================================
info "Writing misc screens..."

# ---- lib/screens/misc/splash_screen.dart -----------------------------------
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
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogoIcon(size: 96),
            const SizedBox(height: 24),
            const AppLogoText(height: 40),
            const SizedBox(height: 8),
            const Text(
              'Freshness at your fingertips',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

# ---- lib/screens/misc/notifications_screen.dart ----------------------------
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ..._items.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n['time'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
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

ok "Misc screens written."

# =============================================================================
# 6. AUTH SCREENS
# =============================================================================
info "Writing auth screens..."

# ---- lib/screens/auth/login_screen.dart ------------------------------------
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Pantry header image
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
              const Text(
                'Freshness at your fingertips',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _login,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        foregroundColor: AppColors.textPrimary,
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
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR EMAIL',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email or Username',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Password',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
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
                          onPressed: () => setState(() => _obscure = !_obscure),
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
                        text: const TextSpan(
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          children: [
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

ok "Login screen written."

# =============================================================================
# 7. ONBOARDING SCREENS (3 steps)
# =============================================================================
info "Writing onboarding screens..."

# ---- lib/screens/onboarding/signup_step1_screen.dart -----------------------
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogoIcon(size: 36),
                  const SizedBox(width: 8),
                  const AppLogoText(height: 30),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Step 1 of 3',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark)),
                  const Text('Account Basics',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.33,
                  minHeight: 5,
                  backgroundColor: Color(0xFFCFE7D2),
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Create your account',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                "Let's start with some basic information to get your pantry organized.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              _label('Full Name'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Enter your full name',
                ),
              ),
              const SizedBox(height: 16),
              _label('Email Address'),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'example@email.com',
                ),
              ),
              const SizedBox(height: 16),
              _label('Password'),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Birthdate'),
                        const SizedBox(height: 6),
                        const TextField(
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
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
                        _label('Gender'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          hint: const Text('Select'),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                            DropdownMenuItem(value: 'O', child: Text('Other')),
                            DropdownMenuItem(
                                value: 'N', child: Text('Prefer not to say')),
                          ],
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ),
                ],
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
                    text: const TextSpan(
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      children: [
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
              const Center(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    children: [
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

  Widget _label(String s) => Text(
        s,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );
}
DART

# ---- lib/screens/onboarding/signup_step2_screen.dart -----------------------
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
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
                      children: const [
                        Text('ONBOARDING',
                            style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                        Text('Step 2 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
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
                            AlwaysStoppedAnimation(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Dietary Preferences',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Select all that apply. This helps us suggest the best recipes and pantry tips for you.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
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
                              color: Colors.white,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
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
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: AppColors.primaryDark, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can always update these preferences later in your Profile settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
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
            const Divider(height: 1),
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

# ---- lib/screens/onboarding/signup_step3_screen.dart -----------------------
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
  final _common = const [
    'Peanuts', 'Dairy', 'Soy', 'Shellfish', 'Gluten', 'Tree Nuts', 'Eggs', 'Fish'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      AppLogoIcon(size: 32),
                      SizedBox(width: 8),
                      AppLogoText(height: 30),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: AppColors.textPrimary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STEP 3 OF 3',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 6),
                    const Text('Food Allergies',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      "We'll help you spot these in recipes and product labels.",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search allergies (e.g., Peanuts, Dairy)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Common Allergens',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
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
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
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
                                        : AppColors.textPrimary,
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
                        color: AppColors.infoBg,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Did you know?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                SizedBox(height: 4),
                                Text(
                                  'Selecting allergies will automatically highlight unsafe items in your pantry and recipes.',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      foregroundColor: AppColors.textPrimary,
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

ok "Onboarding screens written."

# =============================================================================
# 8. MAIN SHELL (holds the 5 tabs) + 5 MAIN SCREENS
# =============================================================================
info "Writing main shell + main screens..."

# ---- lib/screens/main/main_shell.dart --------------------------------------
cat > lib/screens/main/main_shell.dart <<'DART'
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'add_item_screen.dart';
import 'recipe_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatelessWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const PantryScreen(),
      const AddItemScreen(),
      const RecipeScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[initialIndex],
      bottomNavigationBar: ShelfBottomNav(currentIndex: initialIndex),
    );
  }
}
DART

# ---- lib/screens/main/home_screen.dart -------------------------------------
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
          const Text('Pantry Insights',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(
                label: 'Total Items',
                value: '124',
                trailing: const Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.safe, size: 16),
                    SizedBox(width: 4),
                    Text('+12%',
                      style: TextStyle(color: AppColors.safe,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                label: 'Expiring Soon',
                value: '08',
                valueColor: AppColors.warning,
                trailing: const Text('Next 48h',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              )),
            ],
          ),
          const SizedBox(height: 12),
          _wasteCard(),
          const SizedBox(height: 16),
          _suggestedGroceriesCard(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Use First',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600)),
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
    required String label,
    required String value,
    Color valueColor = AppColors.textPrimary,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: valueColor,
              )),
          const SizedBox(height: 4),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _wasteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Wasted Items',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                Text('14.2%',
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
                color: const Color(0xFFFFF0F0),
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

  static BarChartGroupData _bar(int x, double y, {Color color = const Color(0xFFF77272)}) {
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

  Widget _suggestedGroceriesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Suggested Groceries',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 12),
          ...SampleData.suggestedGroceries.map((g) {
            final type = g['type']!;
            final reasonColor = type == 'expired'
                ? AppColors.danger
                : type == 'low'
                    ? AppColors.warning
                    : AppColors.textSecondary;
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
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
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
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Divider(height: 1),
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

# ---- lib/screens/main/pantry_screen.dart -----------------------------------
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
  final _filters = const ['All Items', 'Dairy', 'Produce', 'Meat'];

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
              fillColor: Colors.white,
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
                            : AppColors.chipUnselected,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
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

# ---- lib/screens/main/add_item_screen.dart ---------------------------------
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
  int _mode = 0; // 0 = manual, 1 = barcode
  int _qty = 1;
  String _category = 'Meat & Poultry';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          _modeToggle(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Inventory',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: const [
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
          _mode == 0 ? _manualForm() : _barcodePlaceholder(),
          const SizedBox(height: 24),
          const Text('Recently Added',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _recentCard('Produce', 'Organic Kale', 'Qty: 2',
                    AppColors.primaryDark),
                const SizedBox(width: 10),
                _recentCard('Dairy', 'Whole Milk', 'Qty: 1 gal',
                    AppColors.warning),
                const SizedBox(width: 10),
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.divider,
                      style: BorderStyle.solid,
                    ),
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
                      child: Icon(Icons.kitchen, size: 48, color: AppColors.primary),
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

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chipUnselected,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(child: _modeBtn('Manual Entry', 0)),
          Expanded(child: _modeBtn('Barcode Scan', 1)),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, int idx) {
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
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _manualForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.primaryDark, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formLabel('Item name'),
          const SizedBox(height: 6),
          const TextField(
            decoration: InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel('Quantity'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
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
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
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
                    _formLabel('Category'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(),
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
          _formLabel('Expiry Date'),
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
              color: AppColors.infoBg,
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
                      const Text('Best-before suggestion',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text(
                        'Fresh poultry typically lasts 2-3 days in the fridge. Suggested date: Oct 27, 2023.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: const [
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

  Widget _barcodePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        children: const [
          Icon(Icons.qr_code_scanner, size: 80, color: AppColors.primaryDark),
          SizedBox(height: 16),
          Text('Point camera at barcode',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          SizedBox(height: 8),
          Text(
            'Scanner will be enabled in the next build.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _recentCard(String category, String name, String qty, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 4),
          Text(qty,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  Widget _formLabel(String s) => Text(s,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSecondary,
      ));
}
DART

# ---- lib/screens/main/recipe_screen.dart -----------------------------------
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
              const Text('Use First Suggestions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
          const Text('Find by Ingredients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                label: const Icon(Icons.add,
                    size: 18, color: AppColors.textPrimary),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.divider),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Matches for you',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...SampleData.matches.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _matchCard(r),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
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

  Widget _matchCard(Recipe r) {
    final accent = r.allFound ? AppColors.safe : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: AppColors.chipBg,
                child: const Icon(Icons.restaurant,
                    color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${r.time} • ${r.difficulty}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
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
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: AppColors.textSecondary,
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

# ---- lib/screens/main/profile_screen.dart ----------------------------------
cat > lib/screens/main/profile_screen.dart <<'DART'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _avatar(),
          const SizedBox(height: 12),
          const Center(
            child: Text('Elena Rodriguez',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const Center(
            child: Text('elena.rod@example.com',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          _settingsCard(),
          const SizedBox(height: 14),
          _dietaryCard(),
          const SizedBox(height: 14),
          _allergiesCard(),
          const SizedBox(height: 14),
          _analyticsCard(),
          const SizedBox(height: 14),
          _navTile(Icons.manage_accounts, 'Edit Profile Details'),
          const SizedBox(height: 10),
          _navTile(Icons.shield_outlined, 'Privacy & Data'),
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
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
          const Center(
            child: Text('ShelfLife Version 2.4.0 (2024)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
              backgroundColor: AppColors.chipBg,
              child: ClipOval(
                child: Image.asset(
                  'assets/profile/avatar_default.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textMuted,
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

  Widget _settingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              const Icon(Icons.dark_mode_outlined,
                  color: AppColors.textPrimary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Dark Mode', style: TextStyle(fontSize: 15)),
              ),
              Switch(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.textPrimary),
              const SizedBox(width: 12),
              const Expanded(
                child:
                    Text('Push Notifications', style: TextStyle(fontSize: 15)),
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

  Widget _dietaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
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
              _pill('+ Add Focus', AppColors.chipBg, AppColors.textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allergiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _allergyRow('Peanuts & Tree Nuts'),
          const SizedBox(height: 8),
          _allergyRow('Shellfish'),
        ],
      ),
    );
  }

  Widget _allergyRow(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 15))),
          const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }

  Widget _analyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
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
                    const Text('Waste Reduction',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
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
                                  if (v.toInt() < 0 || v.toInt() >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    labels[v.toInt()],
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
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
                    const Text('Category Distribution',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
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
                            children: const [
                              Text('42',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text('items',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot(color: AppColors.primaryDark, label: 'Produce'),
                        SizedBox(width: 10),
                        _LegendDot(color: AppColors.primaryLight, label: 'Dairy'),
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

  Widget _navTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
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
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
DART

ok "Main app screens written."

# =============================================================================
# 9. SHOPPING LIST SCREEN
# =============================================================================
info "Writing shopping list screen..."

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryDark),
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
                const Text('Shopping List',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text('${_items.length} items',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
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
                      color: Colors.white,
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
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  decoration: item.checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.note != null) ...[
                                const SizedBox(height: 2),
                                Text(item.note!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    )),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textSecondary),
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
        color: AppColors.background,
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

ok "Shopping list screen written."

# =============================================================================
# 10. ANDROID MANIFEST — ensure label is "ShelfLife"
# =============================================================================
info "Tweaking AndroidManifest label..."
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  # macOS sed needs the -i '' syntax; use a portable hack
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/android:label="[^"]*"/android:label="ShelfLife"/' \
      android/app/src/main/AndroidManifest.xml || true
  else
    sed -i 's/android:label="[^"]*"/android:label="ShelfLife"/' \
      android/app/src/main/AndroidManifest.xml || true
  fi
  ok "AndroidManifest label set to ShelfLife."
else
  warn "AndroidManifest.xml not found, skipping label update."
fi

# =============================================================================
# 11. flutter pub get
# =============================================================================
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
echo -e "${GREEN}  ShelfLife scaffolding complete!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo
echo "Next steps:"
echo "  1. Drop your image assets into the assets/ folders."
echo "     See assets/README.md for the exact filenames expected."
echo "  2. Drop your SVG logo files:"
echo "       assets/logo/shelflife_logo.svg   (the green 'ShelfLife' wordmark)"
echo "       assets/logo/shelflife_icon.svg   (the green basket icon)"
echo "  3. Run the app:"
echo "       flutter run"
echo
echo "Navigation flow:"
echo "  Splash → Login → (Register opens Signup Step 1 → 2 → 3) → Main Shell"
echo "  Main Shell: Home / Pantry / Add / Recipe / Profile"
echo "  Top-left basket icon → Shopping List"
echo "  Top-right bell → Notifications"
echo