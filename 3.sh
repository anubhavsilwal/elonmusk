#!/usr/bin/env bash
# =============================================================================
# ShelfLife — Version 3 Update Script
# =============================================================================
# Run from project root, AFTER 1.sh and 2.sh succeeded.
#
#   cd /Users/anubhavsilwal/StudioProjects/demoui
#   chmod +x 3.sh
#   ./3.sh
#
# v3 adds Hive persistence, full pantry CRUD, favorites, expanded sample data,
# and fixes the broken onboarding screens.
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
  err "Run this from your project root (the demoui/ folder)."
  exit 1
fi

if [ ! -f "lib/theme/theme_controller.dart" ]; then
  err "v2 files not found. Run 2.sh first."
  exit 1
fi

info "Starting ShelfLife v3 update..."

# =============================================================================
# 0. Rename SVG files to expected lowercase + clean Flutter build
# =============================================================================
info "Normalizing SVG asset filenames to lowercase..."
if [ -d "assets/logo" ]; then
  # Rename any capital-L variants to all-lowercase, no-op if already correct
  shopt -s nullglob 2>/dev/null || true
  for f in assets/logo/shelfLife_logo.svg assets/logo/ShelfLife_logo.svg assets/logo/shelflife_Logo.svg; do
    [ -f "$f" ] && mv "$f" "assets/logo/shelflife_logo.svg" 2>/dev/null || true
  done
  for f in assets/logo/shelfLife_icon.svg assets/logo/ShelfLife_icon.svg assets/logo/shelflife_Icon.svg; do
    [ -f "$f" ] && mv "$f" "assets/logo/shelflife_icon.svg" 2>/dev/null || true
  done
  if [ -f "assets/logo/shelflife_logo.svg" ]; then
    ok "Logo SVG found: assets/logo/shelflife_logo.svg"
  else
    warn "Logo SVG missing. Place it at assets/logo/shelflife_logo.svg (all lowercase)."
  fi
  if [ -f "assets/logo/shelflife_icon.svg" ]; then
    ok "Icon SVG found: assets/logo/shelflife_icon.svg"
  else
    warn "Icon SVG missing. Place it at assets/logo/shelflife_icon.svg (all lowercase)."
  fi
fi

# =============================================================================
# 1. pubspec.yaml — add hive + path_provider
# =============================================================================
info "Updating pubspec.yaml (adding hive, path_provider)..."

PROJECT_NAME=$(grep -E "^name:" pubspec.yaml | head -1 | awk '{print $2}')
PROJECT_NAME=${PROJECT_NAME:-demoui}

cat > pubspec.yaml <<EOF
name: $PROJECT_NAME
description: "ShelfLife - Pantry management app."
publish_to: 'none'
version: 1.0.0+3

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
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.4

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
ok "pubspec.yaml updated."

# =============================================================================
# 2. New folders for v3
# =============================================================================
mkdir -p lib/store
mkdir -p lib/screens/pantry_detail
mkdir -p lib/screens/recipes
ok "Folders ready."

# =============================================================================
# 3. MODELS — extended with id, notes, storage location, image
# =============================================================================
info "Updating models..."

cat > lib/models/pantry_item.dart <<'DART'
import 'package:hive/hive.dart';

enum ExpiryStatus { safe, soon, expired }
enum StorageLocation { fridge, freezer, pantry }

extension StorageLocationX on StorageLocation {
  String get label {
    switch (this) {
      case StorageLocation.fridge: return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.pantry: return 'Pantry';
    }
  }
  static StorageLocation parse(String? s) {
    switch (s) {
      case 'freezer': return StorageLocation.freezer;
      case 'pantry':  return StorageLocation.pantry;
      default:        return StorageLocation.fridge;
    }
  }
  String get serialized => name;
}

/// In-memory representation of a pantry item. Persisted to Hive as a Map.
class PantryItem {
  final String id;
  final String name;
  final String category;
  final String quantity;
  final DateTime expiryDate;
  final DateTime addedDate;
  final String? imageAsset;
  final String? imagePath;       // user-supplied path/asset
  final String? notes;
  final StorageLocation storage;

  const PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.addedDate,
    this.imageAsset,
    this.imagePath,
    this.notes,
    this.storage = StorageLocation.fridge,
  });

  // ---- Derived ------------------------------------------------------------
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  ExpiryStatus get status {
    final d = daysUntilExpiry;
    if (d <= 1) return ExpiryStatus.expired;
    if (d <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.safe;
  }

  /// Short human label e.g. "Expires Today", "Expires in 3 days (Oct 25)"
  String get expiryLabel {
    final d = daysUntilExpiry;
    final monthStr = const [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ][expiryDate.month - 1];
    final dateStr = '$monthStr ${expiryDate.day}';
    if (d < 0) return 'Expired ($dateStr)';
    if (d == 0) return 'Expires Today';
    if (d == 1) return 'Expires tomorrow';
    if (d <= 7) return 'Expires in $d days ($dateStr)';
    return 'Exp: $dateStr';
  }

  /// Progress bar fill (0..1) — fuller = more of shelf life used.
  double get progress {
    final total = expiryDate.difference(addedDate).inDays;
    if (total <= 0) return 1.0;
    final used = DateTime.now().difference(addedDate).inDays;
    final p = used / total;
    return p.clamp(0.0, 1.0);
  }

  // ---- Hive (Map) serialization ------------------------------------------
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'expiry': expiryDate.toIso8601String(),
        'added': addedDate.toIso8601String(),
        'imageAsset': imageAsset,
        'imagePath': imagePath,
        'notes': notes,
        'storage': storage.serialized,
      };

  factory PantryItem.fromMap(Map m) => PantryItem(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        quantity: m['quantity'] as String,
        expiryDate: DateTime.parse(m['expiry'] as String),
        addedDate: DateTime.parse(m['added'] as String),
        imageAsset: m['imageAsset'] as String?,
        imagePath: m['imagePath'] as String?,
        notes: m['notes'] as String?,
        storage: StorageLocationX.parse(m['storage'] as String?),
      );

  PantryItem copyWith({
    String? name,
    String? category,
    String? quantity,
    DateTime? expiryDate,
    String? imageAsset,
    String? imagePath,
    String? notes,
    StorageLocation? storage,
  }) =>
      PantryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        expiryDate: expiryDate ?? this.expiryDate,
        addedDate: addedDate,
        imageAsset: imageAsset ?? this.imageAsset,
        imagePath: imagePath ?? this.imagePath,
        notes: notes ?? this.notes,
        storage: storage ?? this.storage,
      );
}

// Suppress the analyzer "Unused import" warning for hive (we'll need it later)
// ignore: unused_element
typedef _UnusedHive = HiveObject;
DART

cat > lib/models/recipe.dart <<'DART'
class Recipe {
  final String id;
  final String title;
  final String time;
  final String difficulty;
  final String? imageAsset;
  final bool allFound;
  final String? missingNote;
  final bool urgent;
  final String description;
  final List<String> ingredients;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.difficulty,
    this.imageAsset,
    this.allFound = true,
    this.missingNote,
    this.urgent = false,
    this.description = '',
    this.ingredients = const [],
    this.tags = const [],
  });
}
DART

cat > lib/models/shopping_item.dart <<'DART'
class ShoppingItem {
  final String id;
  String name;
  String? note;
  bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.note,
    this.checked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'checked': checked,
      };

  factory ShoppingItem.fromMap(Map m) => ShoppingItem(
        id: m['id'] as String,
        name: m['name'] as String,
        note: m['note'] as String?,
        checked: (m['checked'] as bool?) ?? false,
      );
}
DART

ok "Models updated."

# =============================================================================
# 4. HIVE STORE — single source of truth for app data
# =============================================================================
info "Writing Hive store..."

cat > lib/store/app_store.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pantry_item.dart';
import '../models/shopping_item.dart';
import '../theme/theme_controller.dart';
import '../data/seed_data.dart';

/// AppStore — the only place that talks to Hive.
///
/// Listenable: any widget can call `AnimatedBuilder(animation: AppStore.I, ...)`
/// or `ListenableBuilder` and rebuild whenever data changes.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  // ---- Boxes --------------------------------------------------------------
  static const _pantryBox    = 'pantry';
  static const _shoppingBox  = 'shopping';
  static const _favoritesBox = 'favorites';
  static const _settingsBox  = 'settings';

  late Box _pantry;
  late Box _shopping;
  late Box _favorites;
  late Box _settings;

  /// Initialize Hive + open boxes + seed first-launch data.
  /// Call exactly once from main() before runApp().
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_pantryBox);
    await Hive.openBox(_shoppingBox);
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_settingsBox);

    I._pantry    = Hive.box(_pantryBox);
    I._shopping  = Hive.box(_shoppingBox);
    I._favorites = Hive.box(_favoritesBox);
    I._settings  = Hive.box(_settingsBox);

    // First-launch: seed sample data
    if (I._settings.get('seeded') != true) {
      for (final m in SeedData.pantry) {
        await I._pantry.put(m['id'], m);
      }
      for (final m in SeedData.shopping) {
        await I._shopping.put(m['id'], m);
      }
      for (final id in SeedData.favoriteIds) {
        await I._favorites.put(id, true);
      }
      await I._settings.put('seeded', true);
    }

    // Restore dark mode preference
    final dark = I._settings.get('darkMode', defaultValue: false) as bool;
    themeController.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  // =========================================================================
  // PANTRY
  // =========================================================================

  List<PantryItem> get pantryItems {
    final list = _pantry.values
        .map((v) => PantryItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list;
  }

  /// Items expiring soonest first (for "Use First").
  List<PantryItem> get useFirstItems {
    return pantryItems.take(5).toList();
  }

  /// Convenience for charts/dashboards.
  int get totalItemCount => _pantry.length;
  int get expiringSoonCount =>
      pantryItems.where((i) => i.daysUntilExpiry <= 2).length;

  void addPantryItem(PantryItem item) {
    _pantry.put(item.id, item.toMap());
    notifyListeners();
  }

  void updatePantryItem(PantryItem item) {
    _pantry.put(item.id, item.toMap());
    notifyListeners();
  }

  void deletePantryItem(String id) {
    _pantry.delete(id);
    notifyListeners();
  }

  PantryItem? pantryItemById(String id) {
    final v = _pantry.get(id);
    if (v == null) return null;
    return PantryItem.fromMap(Map<String, dynamic>.from(v as Map));
  }

  // =========================================================================
  // SHOPPING LIST
  // =========================================================================

  List<ShoppingItem> get shoppingItems => _shopping.values
      .map((v) => ShoppingItem.fromMap(Map<String, dynamic>.from(v as Map)))
      .toList();

  void addShoppingItem(ShoppingItem item) {
    _shopping.put(item.id, item.toMap());
    notifyListeners();
  }

  void updateShoppingItem(ShoppingItem item) {
    _shopping.put(item.id, item.toMap());
    notifyListeners();
  }

  void deleteShoppingItem(String id) {
    _shopping.delete(id);
    notifyListeners();
  }

  /// Move all checked shopping items into pantry, then remove them
  /// from shopping list. Returns the number moved.
  int moveCheckedToPantry() {
    final checked = shoppingItems.where((i) => i.checked).toList();
    final now = DateTime.now();
    for (final s in checked) {
      final item = PantryItem(
        id: 'p_${DateTime.now().microsecondsSinceEpoch}_${s.id}',
        name: s.name,
        category: 'Other',
        quantity: '1',
        expiryDate: now.add(const Duration(days: 7)),
        addedDate: now,
        storage: StorageLocation.fridge,
      );
      _pantry.put(item.id, item.toMap());
      _shopping.delete(s.id);
    }
    notifyListeners();
    return checked.length;
  }

  // =========================================================================
  // FAVORITES (recipe ids -> true)
  // =========================================================================

  Set<String> get favoriteRecipeIds =>
      _favorites.keys.map((k) => k.toString()).toSet();

  bool isFavorite(String recipeId) => _favorites.get(recipeId) == true;

  void toggleFavorite(String recipeId) {
    if (isFavorite(recipeId)) {
      _favorites.delete(recipeId);
    } else {
      _favorites.put(recipeId, true);
    }
    notifyListeners();
  }

  // =========================================================================
  // SETTINGS
  // =========================================================================

  bool get darkMode =>
      _settings.get('darkMode', defaultValue: false) as bool;

  void setDarkMode(bool v) {
    _settings.put('darkMode', v);
    notifyListeners();
  }

  // =========================================================================
  // DEBUG / RESET
  // =========================================================================

  /// Wipe all data and re-seed.
  Future<void> resetAndReseed() async {
    await _pantry.clear();
    await _shopping.clear();
    await _favorites.clear();
    await _settings.delete('seeded');
    for (final m in SeedData.pantry) {
      await _pantry.put(m['id'], m);
    }
    for (final m in SeedData.shopping) {
      await _shopping.put(m['id'], m);
    }
    for (final id in SeedData.favoriteIds) {
      await _favorites.put(id, true);
    }
    await _settings.put('seeded', true);
    notifyListeners();
  }
}

/// Helper for [ListenableBuilder] convenience.
class StoreListener extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  const StoreListener({super.key, required this.builder});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (ctx, _) => builder(ctx),
    );
  }
}

// Tag the file as used by a debug hook so the analyzer leaves us alone
// ignore: unused_element
const _unused = kReleaseMode;
DART

ok "AppStore (Hive) written."

# =============================================================================
# 5. SEED DATA — ~20 pantry items, ~15 recipes, ~12 shopping items
# =============================================================================
info "Writing seed data..."

cat > lib/data/seed_data.dart <<'DART'
/// First-launch seed data, written into Hive only once.
/// To re-seed at any time, call AppStore.I.resetAndReseed().
class SeedData {
  static DateTime _d(int days) =>
      DateTime.now().add(Duration(days: days));
  static DateTime _added(int daysAgo) =>
      DateTime.now().subtract(Duration(days: daysAgo));

  static String _id(String prefix, int n) => '${prefix}_$n';

  // ---- Pantry (20 items) --------------------------------------------------
  static List<Map<String, dynamic>> get pantry => [
        {
          'id': _id('p', 1),
          'name': 'Whole Milk',
          'category': 'Dairy',
          'quantity': '1 Gallon',
          'expiry': _d(0).toIso8601String(),
          'added': _added(6).toIso8601String(),
          'imageAsset': 'assets/items/whole_milk.png',
          'imagePath': null,
          'notes': 'Top shelf of fridge',
          'storage': 'fridge',
        },
        {
          'id': _id('p', 2),
          'name': 'Baby Spinach',
          'category': 'Produce',
          'quantity': '1 bag',
          'expiry': _d(2).toIso8601String(),
          'added': _added(3).toIso8601String(),
          'imageAsset': 'assets/items/baby_spinach.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 3),
          'name': 'Greek Yogurt',
          'category': 'Dairy',
          'quantity': '500g tub',
          'expiry': _d(3).toIso8601String(),
          'added': _added(4).toIso8601String(),
          'imageAsset': 'assets/items/greek_yogurt.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 4),
          'name': 'Avocados',
          'category': 'Produce',
          'quantity': '2 units',
          'expiry': _d(5).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': 'assets/items/avocados.png',
          'imagePath': null,
          'notes': null,
          'storage': 'pantry',
        },
        {
          'id': _id('p', 5),
          'name': 'Strawberries',
          'category': 'Produce',
          'quantity': '1 pack',
          'expiry': _d(6).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': 'assets/items/strawberries.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 6),
          'name': 'Baby Carrots',
          'category': 'Produce',
          'quantity': '2 Bags',
          'expiry': _d(3).toIso8601String(),
          'added': _added(4).toIso8601String(),
          'imageAsset': 'assets/items/baby_carrots.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 7),
          'name': 'Chicken Breast',
          'category': 'Meat',
          'quantity': '1.5 lbs',
          'expiry': _d(12).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': 'assets/items/chicken_breast.png',
          'imagePath': null,
          'notes': 'Vacuum sealed',
          'storage': 'freezer',
        },
        {
          'id': _id('p', 8),
          'name': 'Chicken Breast',
          'category': 'Meat',
          'quantity': '1 lb',
          'expiry': _d(4).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': 'assets/items/chicken_breast_2.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 9),
          'name': 'Large Eggs (12pk)',
          'category': 'Dairy',
          'quantity': '1 Carton',
          'expiry': _d(8).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': 'assets/items/large_eggs.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 10),
          'name': 'Salted Butter',
          'category': 'Dairy',
          'quantity': '4 sticks',
          'expiry': _d(12).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': 'assets/items/salted_butter.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 11),
          'name': 'Red Bell Peppers',
          'category': 'Produce',
          'quantity': '2 units',
          'expiry': _d(3).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': 'assets/items/red_bell_peppers.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 12),
          'name': 'Organic Kale',
          'category': 'Produce',
          'quantity': '1 bunch',
          'expiry': _d(4).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': 'assets/items/organic_kale.png',
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 13),
          'name': 'Whole-Wheat Bread',
          'category': 'Grains',
          'quantity': '1 loaf',
          'expiry': _d(5).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': 'Bread bin on counter',
          'storage': 'pantry',
        },
        {
          'id': _id('p', 14),
          'name': 'Cheddar Cheese',
          'category': 'Dairy',
          'quantity': '250g block',
          'expiry': _d(20).toIso8601String(),
          'added': _added(3).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 15),
          'name': 'Tomatoes',
          'category': 'Produce',
          'quantity': '6 units',
          'expiry': _d(7).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': null,
          'storage': 'pantry',
        },
        {
          'id': _id('p', 16),
          'name': 'Salmon Fillet',
          'category': 'Meat',
          'quantity': '2 fillets',
          'expiry': _d(2).toIso8601String(),
          'added': _added(0).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': 'Wild caught',
          'storage': 'fridge',
        },
        {
          'id': _id('p', 17),
          'name': 'Olive Oil',
          'category': 'Other',
          'quantity': '500ml',
          'expiry': _d(180).toIso8601String(),
          'added': _added(30).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': 'Extra virgin',
          'storage': 'pantry',
        },
        {
          'id': _id('p', 18),
          'name': 'Brown Rice',
          'category': 'Grains',
          'quantity': '2 kg bag',
          'expiry': _d(240).toIso8601String(),
          'added': _added(15).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': null,
          'storage': 'pantry',
        },
        {
          'id': _id('p', 19),
          'name': 'Blueberries',
          'category': 'Produce',
          'quantity': '1 pint',
          'expiry': _d(4).toIso8601String(),
          'added': _added(1).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': null,
          'storage': 'fridge',
        },
        {
          'id': _id('p', 20),
          'name': 'Ground Beef',
          'category': 'Meat',
          'quantity': '500g',
          'expiry': _d(1).toIso8601String(),
          'added': _added(2).toIso8601String(),
          'imageAsset': null,
          'imagePath': null,
          'notes': 'Use today or freeze',
          'storage': 'fridge',
        },
      ];

  // ---- Shopping List (12 items) -------------------------------------------
  static List<Map<String, dynamic>> get shopping => [
        {'id': 's_1',  'name': 'Pancetta',          'note': 'Expired item',      'checked': false},
        {'id': 's_2',  'name': 'Parmesan',          'note': 'From recipe: Spaghetti Carbonara', 'checked': false},
        {'id': 's_3',  'name': 'Milk',              'note': 'Low stock',         'checked': false},
        {'id': 's_4',  'name': 'Whole-Wheat Bread', 'note': null,                'checked': false},
        {'id': 's_5',  'name': 'Honey',             'note': 'For Honey Glazed Chicken', 'checked': false},
        {'id': 's_6',  'name': 'Fresh Basil',       'note': null,                'checked': false},
        {'id': 's_7',  'name': 'Garlic (1 bulb)',   'note': null,                'checked': false},
        {'id': 's_8',  'name': 'Lemons (4)',        'note': null,                'checked': false},
        {'id': 's_9',  'name': 'Pasta',             'note': null,                'checked': false},
        {'id': 's_10', 'name': 'Coffee Beans',      'note': '250g, medium roast', 'checked': false},
        {'id': 's_11', 'name': 'Almond Milk',       'note': 'Unsweetened',       'checked': false},
        {'id': 's_12', 'name': 'Bananas',           'note': null,                'checked': false},
      ];

  // ---- Favorite recipe ids ------------------------------------------------
  static List<String> get favoriteIds => ['r_2', 'r_4', 'r_7'];
}
DART

# ---- lib/data/recipe_data.dart — 15 recipes -------------------------------
cat > lib/data/recipe_data.dart <<'DART'
import '../models/recipe.dart';

class RecipeData {
  static const List<Recipe> all = [
    Recipe(
      id: 'r_1',
      title: 'Spinach & Berry Summer Salad',
      time: '15 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/spinach_berry_salad.png',
      urgent: true,
      description: 'A refreshing salad that uses your expiring spinach and strawberries.',
      ingredients: ['Baby Spinach', 'Strawberries', 'Feta Cheese', 'Walnuts', 'Balsamic Glaze'],
      tags: ['Use First', 'Vegetarian', 'Quick'],
    ),
    Recipe(
      id: 'r_2',
      title: 'Zucchini & Leek Cream Soup',
      time: '30 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/zucchini_leek_soup.png',
      description: 'Velvety soup perfect for cool evenings.',
      ingredients: ['Zucchini', 'Leeks', 'Cream', 'Garlic', 'Vegetable Stock'],
      tags: ['Vegetarian', 'Comfort Food'],
    ),
    Recipe(
      id: 'r_3',
      title: 'Berry Compote Parfait',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/berry_compote_parfait.png',
      description: 'Layered yogurt parfait with warm berry compote and granola.',
      ingredients: ['Greek Yogurt', 'Strawberries', 'Blueberries', 'Granola', 'Honey'],
      tags: ['Breakfast', 'Quick'],
    ),
    Recipe(
      id: 'r_4',
      title: 'Lemon Garlic Stir-Fry',
      time: '20 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/lemon_garlic_stirfry.png',
      allFound: true,
      description: 'Quick stir-fry with bright lemon and aromatic garlic.',
      ingredients: ['Chicken Breast', 'Bell Peppers', 'Garlic', 'Lemons', 'Soy Sauce'],
      tags: ['Quick', 'High Protein'],
    ),
    Recipe(
      id: 'r_5',
      title: 'Honey Glazed Chicken',
      time: '35 mins',
      difficulty: 'Medium',
      imageAsset: 'assets/recipes/honey_glazed_chicken.png',
      allFound: false,
      missingNote: 'Need: Honey',
      description: 'Sticky-sweet glaze on tender chicken with asparagus.',
      ingredients: ['Chicken Breast', 'Honey', 'Soy Sauce', 'Garlic', 'Asparagus'],
      tags: ['Dinner'],
    ),
    Recipe(
      id: 'r_6',
      title: 'Rainbow Veggie Wrap',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/rainbow_veggie_wrap.png',
      allFound: true,
      description: 'Colorful, crunchy wrap with hummus and fresh vegetables.',
      ingredients: ['Tortilla', 'Hummus', 'Bell Peppers', 'Carrots', 'Spinach', 'Cucumber'],
      tags: ['Vegetarian', 'Lunch', 'Quick'],
    ),
    Recipe(
      id: 'r_7',
      title: 'Avocado Egg Toast',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: null,
      description: 'Creamy avocado and runny egg on toasted bread.',
      ingredients: ['Whole-Wheat Bread', 'Avocados', 'Large Eggs', 'Chili Flakes', 'Lemon'],
      tags: ['Breakfast', 'Quick'],
    ),
    Recipe(
      id: 'r_8',
      title: 'Salmon Teriyaki Bowl',
      time: '25 mins',
      difficulty: 'Medium',
      imageAsset: null,
      description: 'Glazed salmon over brown rice with steamed veggies.',
      ingredients: ['Salmon Fillet', 'Brown Rice', 'Soy Sauce', 'Honey', 'Broccoli'],
      tags: ['High Protein', 'Dinner'],
    ),
    Recipe(
      id: 'r_9',
      title: 'Classic Spaghetti Carbonara',
      time: '20 mins',
      difficulty: 'Medium',
      imageAsset: null,
      allFound: false,
      missingNote: 'Need: Pancetta, Parmesan',
      description: 'Authentic Roman pasta with eggs, cheese, and pepper.',
      ingredients: ['Pasta', 'Large Eggs', 'Parmesan', 'Pancetta', 'Black Pepper'],
      tags: ['Italian', 'Dinner'],
    ),
    Recipe(
      id: 'r_10',
      title: 'Roasted Veggie Tray Bake',
      time: '40 mins',
      difficulty: 'Easy',
      imageAsset: null,
      description: 'One-pan roasted vegetables with olive oil and herbs.',
      ingredients: ['Bell Peppers', 'Tomatoes', 'Olive Oil', 'Carrots', 'Garlic'],
      tags: ['Vegetarian', 'Meal Prep'],
    ),
    Recipe(
      id: 'r_11',
      title: 'Yogurt Berry Smoothie',
      time: '5 mins',
      difficulty: 'Very Easy',
      imageAsset: null,
      description: 'Quick energizing smoothie packed with antioxidants.',
      ingredients: ['Greek Yogurt', 'Blueberries', 'Strawberries', 'Honey', 'Almond Milk'],
      tags: ['Breakfast', 'Smoothie', 'Quick'],
    ),
    Recipe(
      id: 'r_12',
      title: 'Cheesy Beef Tacos',
      time: '25 mins',
      difficulty: 'Easy',
      imageAsset: null,
      description: 'Quick weeknight tacos with seasoned ground beef and cheese.',
      ingredients: ['Ground Beef', 'Cheddar Cheese', 'Tortilla', 'Tomatoes', 'Lemons'],
      tags: ['Dinner', 'Family Friendly'],
    ),
    Recipe(
      id: 'r_13',
      title: 'Kale & Quinoa Power Bowl',
      time: '20 mins',
      difficulty: 'Easy',
      imageAsset: null,
      description: 'Nutrient-packed bowl with lemon-tahini dressing.',
      ingredients: ['Organic Kale', 'Brown Rice', 'Avocados', 'Lemons', 'Olive Oil'],
      tags: ['Vegetarian', 'Healthy', 'Meal Prep'],
    ),
    Recipe(
      id: 'r_14',
      title: 'Garlic Butter Shrimp',
      time: '15 mins',
      difficulty: 'Easy',
      imageAsset: null,
      description: 'Quick shrimp sautéed in garlic butter with lemon.',
      ingredients: ['Salted Butter', 'Garlic', 'Lemons', 'Fresh Basil'],
      tags: ['Quick', 'Seafood'],
    ),
    Recipe(
      id: 'r_15',
      title: 'Eggs Benedict',
      time: '25 mins',
      difficulty: 'Medium',
      imageAsset: null,
      description: 'Brunch classic with poached eggs and hollandaise sauce.',
      ingredients: ['Large Eggs', 'Whole-Wheat Bread', 'Salted Butter', 'Lemons'],
      tags: ['Brunch'],
    ),
  ];

  static Recipe? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// "Use First" — recipes flagged urgent (matched to expiring items).
  static List<Recipe> get useFirst => all.where((r) => r.urgent).toList();

  /// Picks for "Matches for you" — first few non-urgent recipes.
  static List<Recipe> get matches =>
      all.where((r) => !r.urgent).take(4).toList();
}
DART

# Delete the v1/v2 sample_data.dart (replaced by seed_data + recipe_data)
if [ -f "lib/data/sample_data.dart" ]; then
  rm lib/data/sample_data.dart
  ok "Removed old sample_data.dart (replaced by seed_data + recipe_data)."
fi

ok "Seed + recipe data written."

# =============================================================================
# 6. main.dart — initialize Hive before runApp
# =============================================================================
info "Updating main.dart to initialize Hive..."

cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'store/app_store.dart';
import 'screens/misc/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await AppStore.init();
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
# 7. UPDATE pantry_item_card — reads expiry from PantryItem directly,
#                              no longer needs `compact` external label
# =============================================================================
info "Updating PantryItemCard widget..."

cat > lib/widgets/pantry_item_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../theme/app_colors.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final bool compact;
  final bool showMenu;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PantryItemCard({
    super.key,
    required this.item,
    this.compact = false,
    this.showMenu = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _statusColor {
    switch (item.status) {
      case ExpiryStatus.expired: return AppColors.danger;
      case ExpiryStatus.soon:    return AppColors.warning;
      case ExpiryStatus.safe:    return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: _statusColor, width: 5)),
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
            : Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textMut(context), size: 24),
              ),
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
                _daysLabel(),
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
              Expanded(
                child: Text(
                  item.expiryLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
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

  String _daysLabel() {
    final d = item.daysUntilExpiry;
    if (d < 0) return 'Expired';
    if (d == 0) return 'Today';
    if (d == 1) return '1 Day';
    return '$d Days';
  }
}
DART
ok "PantryItemCard updated."

# =============================================================================
# 8. ONBOARDING TOP-BAR HELPER — same top nav used in step 1 across all 3 steps
# =============================================================================
info "Writing shared onboarding top-bar widget..."

cat > lib/widgets/onboarding_header.dart <<'DART'
import 'package:flutter/material.dart';
import 'app_logo.dart';

/// The shared header used across all 3 onboarding screens.
/// Matches the look of signup_step1: basket icon + ShelfLife wordmark
/// inline at the top.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          AppLogoIcon(size: 36),
          SizedBox(width: 8),
          AppLogoText(height: 30),
        ],
      ),
    );
  }
}
DART
ok "Onboarding header widget written."

# =============================================================================
# 9. ONBOARDING — all 3 steps use OnboardingHeader (matches step 1)
# =============================================================================
info "Rewriting all 3 onboarding screens with shared top nav..."

# ---- signup_step1_screen.dart (uses OnboardingHeader) ----------------------
cat > lib/screens/onboarding/signup_step1_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/onboarding_header.dart';
import 'signup_step2_screen.dart';

class SignupStep1Screen extends StatelessWidget {
  const SignupStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Step 1 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                        Text('Account Basics',
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Create your account',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
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
                            child: Icon(Icons.kitchen,
                                size: 64, color: Colors.brown),
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
                    LayoutBuilder(builder: (_, c) {
                      if (c.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Birthdate'),
                            const SizedBox(height: 6),
                            const TextField(
                              decoration: InputDecoration(
                                hintText: 'mm/dd/yyyy',
                                suffixIcon:
                                    Icon(Icons.calendar_today, size: 18),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                    suffixIcon:
                                        Icon(Icons.calendar_today, size: 18),
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
                                  decoration:
                                      const InputDecoration(isDense: true),
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
                    }),
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
                                color: AppColors.textPri(context),
                                fontSize: 14),
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
                              style: TextStyle(
                                  decoration: TextDecoration.underline),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  decoration: TextDecoration.underline),
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
          ],
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

# ---- signup_step2_screen.dart (uses OnboardingHeader) ----------------------
cat > lib/screens/onboarding/signup_step2_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/onboarding_header.dart';
import 'signup_step3_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});
  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final Set<String> _selected = {'Vegan'};

  static const _options = [
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
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Step 2 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                        Text('Dietary Preferences',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
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
                            color: AppColors.textPri(context))),
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
                                      Text(label,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color:
                                                  AppColors.textPri(context))),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(Icons.check_circle,
                                        color: AppColors.primaryDark),
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
                                  color: AppColors.textPri(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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

# ---- signup_step3_screen.dart (FIXED - uses OnboardingHeader, no blank body)
cat > lib/screens/onboarding/signup_step3_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/onboarding_header.dart';
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
            const OnboardingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Step 3 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                        Text('Food Allergies',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPri(context))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 5,
                        backgroundColor: Color(0xFFCFE7D2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Food Allergies',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
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
                              child: const Text('Safety First',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
ok "Onboarding screens rewritten with unified top nav."

# =============================================================================
# 10. PANTRY EDIT SHEET — bottom-sheet for editing or adding items
# =============================================================================
info "Writing pantry edit bottom-sheet..."

cat > lib/screens/pantry_detail/pantry_item_sheet.dart <<'DART'
import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';

/// Shows a modal bottom sheet for ADD or EDIT pantry item.
/// Pass [existing] to edit; omit it to add a new item.
Future<void> showPantryItemSheet(BuildContext context, {PantryItem? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PantryItemForm(existing: existing),
  );
}

class _PantryItemForm extends StatefulWidget {
  final PantryItem? existing;
  const _PantryItemForm({this.existing});
  @override
  State<_PantryItemForm> createState() => _PantryItemFormState();
}

class _PantryItemFormState extends State<_PantryItemForm> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _notes;
  late final TextEditingController _imagePath;
  late String _category;
  late DateTime _expiry;
  late StorageLocation _storage;

  static const _categories = [
    'Dairy', 'Produce', 'Meat', 'Grains', 'Beverages', 'Snacks', 'Other'
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _qty = TextEditingController(text: e?.quantity ?? '1');
    _notes = TextEditingController(text: e?.notes ?? '');
    _imagePath = TextEditingController(text: e?.imagePath ?? '');
    _category = e?.category ?? 'Other';
    if (!_categories.contains(_category)) _category = 'Other';
    _expiry = e?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    _storage = e?.storage ?? StorageLocation.fridge;
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _notes.dispose();
    _imagePath.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }
    final now = DateTime.now();
    final item = PantryItem(
      id: widget.existing?.id ??
          'p_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      quantity: _qty.text.trim().isEmpty ? '1' : _qty.text.trim(),
      expiryDate: _expiry,
      addedDate: widget.existing?.addedDate ?? now,
      imageAsset: widget.existing?.imageAsset,
      imagePath: _imagePath.text.trim().isEmpty ? null : _imagePath.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      storage: _storage,
    );
    if (_isEdit) {
      AppStore.I.updatePantryItem(item);
    } else {
      AppStore.I.addPantryItem(item);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Item updated.' : 'Item added.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Edit Item' : 'Add New Item',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
            const SizedBox(height: 16),
            _label(context, 'Item name'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Fresh Chicken Breast',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Quantity'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qty,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 500g or 2',
                          isDense: true,
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
                      _label(context, 'Category'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label(context, 'Expiry Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider(context)),
                  ),
                ),
                child: Text(
                  '${_expiry.year}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: AppColors.textPri(context)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Storage Location'),
            const SizedBox(height: 6),
            SegmentedButton<StorageLocation>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(
                    value: StorageLocation.fridge,
                    label: Text('Fridge'),
                    icon: Icon(Icons.kitchen, size: 18)),
                ButtonSegment(
                    value: StorageLocation.freezer,
                    label: Text('Freezer'),
                    icon: Icon(Icons.ac_unit, size: 18)),
                ButtonSegment(
                    value: StorageLocation.pantry,
                    label: Text('Pantry'),
                    icon: Icon(Icons.inventory_2, size: 18)),
              ],
              selected: {_storage},
              onSelectionChanged: (s) => setState(() => _storage = s.first),
            ),
            const SizedBox(height: 14),
            _label(context, 'Image path (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _imagePath,
              decoration: const InputDecoration(
                hintText: 'assets/items/example.png',
                prefixIcon: Icon(Icons.image_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Top shelf, vacuum sealed...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEdit)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppStore.I.deletePantryItem(widget.existing!.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted.')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      label: const Text('Delete',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                if (_isEdit) const SizedBox(width: 12),
                Expanded(
                  flex: _isEdit ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    child: Text(_isEdit ? 'Save Changes' : 'Add to Pantry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Text(s,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSec(context),
      ));
}
DART
ok "Pantry item sheet written."

# =============================================================================
# 11. PANTRY SCREEN — live data, search, filter, swipe-to-delete, tap-to-edit
# =============================================================================
info "Updating pantry screen with live data + CRUD..."

cat > lib/screens/main/pantry_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _filter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  static const _filters = ['All', 'Dairy', 'Produce', 'Meat', 'Grains', 'Other'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PantryItem> _apply(List<PantryItem> source) {
    var items = source;
    if (_filter != 'All') {
      items = items.where((i) => i.category == _filter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q) ||
              (i.notes ?? '').toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  Future<void> _confirmDelete(PantryItem item) async {
    // Capture the item first so we can undo after delete
    final scaffold = ScaffoldMessenger.of(context);
    AppStore.I.deletePantryItem(item.id);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted.'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => AppStore.I.addPantryItem(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: StoreListener(
        builder: (ctx) {
          final items = _apply(AppStore.I.pantryItems);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search your pantry...',
                  filled: true,
                  fillColor: AppColors.card(context),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
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
              if (items.isEmpty)
                _emptyState(context)
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete this item?'),
                                  content: Text(
                                      'Remove "${item.name}" from your pantry?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _confirmDelete(item),
                        child: PantryItemCard(
                          item: item,
                          showMenu: true,
                          onTap: () =>
                              showPantryItemSheet(context, existing: item),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty || _filter != 'All'
                ? 'No matches found.'
                : 'Your pantry is empty.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSec(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _query.isNotEmpty || _filter != 'All'
                ? 'Try a different search or filter.'
                : 'Tap + to add your first item.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textMut(context)),
          ),
        ],
      ),
    );
  }
}
DART
ok "Pantry screen updated."

# =============================================================================
# 12. ADD ITEM SCREEN — writes to store, shows recently-added from store
# =============================================================================
info "Updating add item screen with live store..."

cat > lib/screens/main/add_item_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  int _mode = 0;
  final _nameCtrl = TextEditingController();
  int _qty = 1;
  String _category = 'Meat';
  DateTime? _expiry;
  StorageLocation _storage = StorageLocation.fridge;

  static const _categories = [
    'Dairy', 'Produce', 'Meat', 'Grains', 'Beverages', 'Snacks', 'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _applySuggestion() {
    setState(() => _expiry = DateTime.now().add(const Duration(days: 3)));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }
    final now = DateTime.now();
    final item = PantryItem(
      id: 'p_${now.microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity: '$_qty',
      expiryDate: _expiry ?? now.add(const Duration(days: 7)),
      addedDate: now,
      storage: _storage,
    );
    AppStore.I.addPantryItem(item);
    _nameCtrl.clear();
    setState(() {
      _qty = 1;
      _expiry = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to pantry.')),
    );
  }

  String _expiryText() {
    if (_expiry == null) return 'dd/mm/yyyy';
    return '${_expiry!.day.toString().padLeft(2,'0')}/${_expiry!.month.toString().padLeft(2,'0')}/${_expiry!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: StoreListener(
        builder: (ctx) {
          final recent = AppStore.I.pantryItems.toList()
            ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
          final recentTop = recent.take(5).toList();
          return ListView(
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
                    ...recentTop.map((item) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _recentCard(
                            context,
                            item.category,
                            item.name,
                            'Qty: ${item.quantity}',
                            _colorForCategory(item.category),
                          ),
                        )),
                    Container(
                      width: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider(context)),
                      ),
                      child: Center(
                        child: Icon(Icons.add,
                            color: AppColors.textMut(context), size: 32),
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
                    child: GestureDetector(
                      onTap: _save,
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
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Color _colorForCategory(String c) {
    switch (c) {
      case 'Dairy': return AppColors.warning;
      case 'Produce': return AppColors.primaryDark;
      case 'Meat': return AppColors.danger;
      default: return AppColors.primaryDark;
    }
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
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                hintText: 'e.g. Fresh Chicken Breast'),
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
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      items: _categories
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
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(_expiryText(),
                  style: TextStyle(
                    color: _expiry == null
                        ? AppColors.textMut(context)
                        : AppColors.textPri(context),
                  )),
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
                        'Fresh poultry typically lasts 2-3 days in the fridge.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPri(context)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _applySuggestion,
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
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.add),
            label: const Text('Add to Pantry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
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
            'Scanner will be enabled in a future build.',
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
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(qty,
              style: TextStyle(
                color: AppColors.textSec(context), fontSize: 12,
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
ok "Add item screen updated."

# =============================================================================
# 13. HOME SCREEN — live data from store
# =============================================================================
info "Updating home screen with live data..."

cat > lib/screens/main/home_screen.dart <<'DART'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';
import '../pantry_detail/pantry_item_sheet.dart';
import '../recipes/use_first_all_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: StoreListener(
        builder: (ctx) {
          final total = AppStore.I.totalItemCount;
          final expiringSoon = AppStore.I.expiringSoonCount;
          final useFirst = AppStore.I.useFirstItems;
          return ListView(
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
                      value: '$total',
                      trailing: const Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: AppColors.safe, size: 16),
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
                      value: expiringSoon.toString().padLeft(2, '0'),
                      valueColor: AppColors.warning,
                      trailing: Text('Next 48h',
                          style: TextStyle(
                              color: AppColors.textSec(context),
                              fontSize: 12)),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UseFirstAllScreen()),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (useFirst.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'No items in pantry yet. Add some!',
                      style: TextStyle(color: AppColors.textSec(context)),
                    ),
                  ),
                )
              else
                ...useFirst.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PantryItemCard(
                        item: item,
                        compact: true,
                        onTap: () =>
                            showPantryItemSheet(context, existing: item),
                      ),
                    )),
            ],
          );
        },
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
    // Build suggestions from live store: expired or expiring-soon items
    final expired = AppStore.I.pantryItems
        .where((i) => i.daysUntilExpiry <= 0)
        .take(2)
        .toList();
    final lowStock = AppStore.I.pantryItems
        .where((i) => i.daysUntilExpiry > 0 && i.daysUntilExpiry <= 3)
        .take(1)
        .toList();
    final suggestions = [
      ...expired.map((i) => {
            'name': i.name,
            'reason': 'Expired',
            'type': 'expired',
          }),
      ...lowStock.map((i) => {
            'name': i.name,
            'reason': 'Expiring in ${i.daysUntilExpiry} day${i.daysUntilExpiry == 1 ? '' : 's'}',
            'type': 'low',
          }),
    ];

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
          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing to restock right now.',
                  style: TextStyle(color: AppColors.textSec(context))),
            )
          else
            ...suggestions.asMap().entries.map((entry) {
              final g = entry.value;
              final last = entry.key == suggestions.length - 1;
              final type = g['type']!;
              final reasonColor = type == 'expired'
                  ? AppColors.danger
                  : AppColors.warning;
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
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline,
                            color: AppColors.primary, size: 28),
                      ],
                    ),
                    if (!last)
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
ok "Home screen updated."

# =============================================================================
# 14. RECIPE SCREEN — Use First, Favorites in middle, View All buttons
# =============================================================================
info "Updating recipe screen with favorites + view-all..."

cat > lib/screens/main/recipe_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../models/recipe.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/use_first_recipes_screen.dart';
import '../recipes/matches_for_you_screen.dart';
import '../recipes/favorites_screen.dart';

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
      body: StoreListener(
        builder: (ctx) {
          final useFirst = RecipeData.useFirst;
          final smallSet = RecipeData.all
              .where((r) => !r.urgent)
              .skip(0)
              .take(2)
              .toList();
          final favorites = RecipeData.all
              .where((r) => AppStore.I.isFavorite(r.id))
              .toList();
          final matches = RecipeData.matches;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              // ---- Use First Suggestions ----
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UseFirstRecipesScreen()),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (useFirst.isNotEmpty) _featuredCard(useFirst.first),
              const SizedBox(height: 12),
              if (smallSet.length >= 2)
                Row(
                  children: [
                    Expanded(child: _smallRecipe(smallSet[0])),
                    const SizedBox(width: 12),
                    Expanded(child: _smallRecipe(smallSet[1])),
                  ],
                ),
              const SizedBox(height: 24),

              // ---- Find by Ingredients ----
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
                        onDeleted: () => setState(
                            () => _selectedIngredients.remove(i)),
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
                    onPressed: () => _addIngredientDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---- Favorite Recipes (above Matches) ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: AppColors.danger, size: 22),
                      const SizedBox(width: 6),
                      Text('Favorite Recipes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavoritesScreen()),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (favorites.isEmpty)
                _emptyFavorites(context)
              else
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _favoriteCard(favorites[i]),
                  ),
                ),
              const SizedBox(height: 24),

              // ---- Matches for you ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Matches for you',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MatchesForYouScreen()),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...matches.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: matchCard(context, r),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _addIngredientDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Onion'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty &&
                  !_selectedIngredients.contains(name)) {
                setState(() => _selectedIngredients.add(name));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: r),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: r.imageAsset != null
                ? Image.asset(
                    r.imageAsset!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _featuredFallback(),
                  )
                : _featuredFallback(),
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
                Text(r.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _featuredFallback() {
    return Container(
      height: 200,
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _smallRecipe(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: r),
        ),
      ),
      child: Container(
        height: 130,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned.fill(
              child: r.imageAsset != null
                  ? Image.asset(
                      r.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _smallFallback(),
                    )
                  : _smallFallback(),
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
      ),
    );
  }

  Container _smallFallback() {
    return Container(
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white),
      ),
    );
  }

  Widget _favoriteCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: r),
        ),
      ),
      child: SizedBox(
        width: 180,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: r.imageAsset != null
                    ? Image.asset(r.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppColors.chipBg(context),
                              child: Icon(Icons.restaurant,
                                  color: AppColors.textMut(context),
                                  size: 32),
                            ))
                    : Container(
                        color: AppColors.chipBg(context),
                        child: Icon(Icons.restaurant,
                            color: AppColors.textMut(context), size: 32),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPri(context),
                        )),
                    const SizedBox(height: 4),
                    Text('${r.time} • ${r.difficulty}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyFavorites(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border,
              color: AppColors.textMut(context), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No favorites yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text('Tap the heart on a recipe to save it here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Public match card — reused by other screens so favorite toggle is
/// consistent everywhere.
Widget matchCard(BuildContext context, Recipe r) {
  final accent = r.allFound ? AppColors.safe : AppColors.warning;
  final isFav = AppStore.I.isFavorite(r.id);
  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: r),
      ),
    ),
    child: Container(
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
            child: r.imageAsset != null
                ? Image.asset(
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
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AppColors.chipBg(context),
                    child: Icon(Icons.restaurant,
                        color: AppColors.textMut(context)),
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
                        child: const Text('1+ MISSING',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.missingNote ?? '',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: AppColors.textSec(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.danger : AppColors.warning,
            ),
            onPressed: () => AppStore.I.toggleFavorite(r.id),
          ),
        ],
      ),
    ),
  );
}
DART
ok "Recipe screen updated."

# =============================================================================
# 15. RECIPE LIST SCREENS — View All targets
# =============================================================================
info "Writing recipe list/detail screens..."

# ---- Use First (pantry items, from Home) -----------------------------------
cat > lib/screens/recipes/use_first_all_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/pantry_item_card.dart';
import '../pantry_detail/pantry_item_sheet.dart';

/// All pantry items sorted by soonest expiry (Use First).
class UseFirstAllScreen extends StatelessWidget {
  const UseFirstAllScreen({super.key});

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
      body: StoreListener(
        builder: (ctx) {
          final items = AppStore.I.pantryItems;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Use First',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('${items.length} items sorted by soonest expiry.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Pantry is empty.',
                        style:
                            TextStyle(color: AppColors.textSec(context))),
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PantryItemCard(
                        item: item,
                        compact: true,
                        onTap: () =>
                            showPantryItemSheet(context, existing: item),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- Use First Recipes -----------------------------------------------------
cat > lib/screens/recipes/use_first_recipes_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../main/recipe_screen.dart';

class UseFirstRecipesScreen extends StatelessWidget {
  const UseFirstRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipes = RecipeData.useFirst.isEmpty
        ? RecipeData.all.take(5).toList()
        : RecipeData.useFirst;
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text('Use First Suggestions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(
              'Recipes that use your expiring items so nothing goes to waste.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 16),
          ...recipes.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: matchCard(context, r),
              )),
        ],
      ),
    );
  }
}
DART

# ---- Matches for You -------------------------------------------------------
cat > lib/screens/recipes/matches_for_you_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../main/recipe_screen.dart';

class MatchesForYouScreen extends StatelessWidget {
  const MatchesForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipes = RecipeData.all.where((r) => !r.urgent).toList();
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text('Matches for you',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text('Recipes that match your selected ingredients.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 16),
          ...recipes.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: matchCard(context, r),
              )),
        ],
      ),
    );
  }
}
DART

# ---- Favorites screen ------------------------------------------------------
cat > lib/screens/recipes/favorites_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../main/recipe_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
      body: StoreListener(
        builder: (ctx) {
          final favs = RecipeData.all
              .where((r) => AppStore.I.isFavorite(r.id))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite,
                      color: AppColors.danger, size: 26),
                  const SizedBox(width: 8),
                  Text('Favorite Recipes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text('${favs.length} recipe${favs.length == 1 ? '' : 's'} saved.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: AppColors.textMut(context)),
                      const SizedBox(height: 12),
                      Text('No favorites yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSec(context),
                          )),
                      const SizedBox(height: 6),
                      Text('Tap the heart on a recipe to save it here.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMut(context))),
                    ],
                  ),
                )
              else
                ...favs.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: matchCard(context, r),
                    )),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- Recipe Detail Screen --------------------------------------------------
cat > lib/screens/recipes/recipe_detail_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../models/shopping_item.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: StoreListener(
        builder: (ctx) {
          final isFav = AppStore.I.isFavorite(recipe.id);
          final pantryNames = AppStore.I.pantryItems
              .map((p) => p.name.toLowerCase())
              .toSet();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.danger : Colors.white,
                    ),
                    onPressed: () => AppStore.I.toggleFavorite(recipe.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageAsset != null
                      ? Image.asset(
                          recipe.imageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF6B7280)),
                        )
                      : const ColoredBox(color: Color(0xFF6B7280)),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.time,
                                style: TextStyle(
                                  color: AppColors.textSec(context),
                                )),
                            const SizedBox(width: 12),
                            Icon(Icons.local_fire_department_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.difficulty,
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recipe.description.isNotEmpty)
                          Text(recipe.description,
                              style: TextStyle(
                                color: AppColors.textPri(context),
                                fontSize: 14,
                                height: 1.45,
                              )),
                        const SizedBox(height: 16),
                        if (recipe.tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recipe.tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(t,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          )),
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 24),
                        Text('Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map((ing) {
                          final have = pantryNames
                              .any((p) => p.contains(ing.toLowerCase()));
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  have
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color:
                                      have ? AppColors.safe : AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(ing,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPri(context),
                                      )),
                                ),
                                if (!have)
                                  TextButton(
                                    onPressed: () {
                                      AppStore.I.addShoppingItem(ShoppingItem(
                                        id: 's_${DateTime.now().microsecondsSinceEpoch}',
                                        name: ing,
                                        note: 'For ${recipe.title}',
                                      ));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            '$ing added to shopping list.'),
                                      ));
                                    },
                                    child: const Text('+ Buy',
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
DART

ok "Recipe list/detail screens written."

# =============================================================================
# 16. SHOPPING LIST — backed by store, persists, moves to pantry
# =============================================================================
info "Updating shopping list with live store..."

cat > lib/screens/shopping/shopping_list_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../../store/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
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
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StoreListener(
        builder: (ctx) {
          final items = AppStore.I.shoppingItems;
          final checked = items.where((i) => i.checked).length;
          return Column(
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
                    Text(
                        '${items.length} items • $checked ticked',
                        style: TextStyle(
                            color: AppColors.textSec(context), fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Remove',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              AppStore.I.deleteShoppingItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${item.name} removed.'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () =>
                                        AppStore.I.addShoppingItem(item),
                                  ),
                                ),
                              );
                            },
                            child: _shoppingTile(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StoreListener(
        builder: (ctx) {
          final count =
              AppStore.I.shoppingItems.where((i) => i.checked).length;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: AppColors.bg(context),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (count == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Tick items first to add them to pantry.')),
                    );
                    return;
                  }
                  final moved = AppStore.I.moveCheckedToPantry();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$moved item(s) added to pantry.')),
                  );
                },
                icon: const Icon(Icons.kitchen),
                label: Text(count > 0
                    ? 'Add $count item(s) to Pantry'
                    : 'Add Checked Items to Pantry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _shoppingTile(BuildContext context, ShoppingItem item) {
    return InkWell(
      onTap: () {
        item.checked = !item.checked;
        AppStore.I.updateShoppingItem(item);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (v) {
                item.checked = v ?? false;
                AppStore.I.updateShoppingItem(item);
              },
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
              onPressed: () => AppStore.I.deleteShoppingItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text('Your shopping list is empty.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context),
              )),
          const SizedBox(height: 6),
          Text('Tap + to add items.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMut(context))),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Shopping List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(hintText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                Navigator.pop(context);
                return;
              }
              AppStore.I.addShoppingItem(ShoppingItem(
                id: 's_${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              ));
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
# 17. PROFILE — dark mode persists, name updated, reset-data debug option
# =============================================================================
info "Updating profile with persisted dark mode..."

cat > lib/screens/main/profile_screen.dart <<'DART'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../store/app_store.dart';
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
    return Scaffold(
      appBar: const MainAppBar(),
      body: StoreListener(
        builder: (ctx) {
          final darkOn = AppStore.I.darkMode;
          return ListView(
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
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                );
              }),
              const SizedBox(height: 10),
              _navTile(context, Icons.shield_outlined, 'Privacy & Data', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                );
              }),
              const SizedBox(height: 10),
              _navTile(context, Icons.restart_alt, 'Reset Demo Data', () {
                _showResetDialog(context);
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
                child: Text('ShelfLife Version 3.0.0',
                    style: TextStyle(
                        color: AppColors.textMut(context), fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
            'This wipes the pantry, shopping list and favorites, then reloads sample data. Useful for demos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStore.I.resetAndReseed();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo data reset.')),
                );
              }
            },
            child: const Text('Reset'),
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
              Icon(Icons.dark_mode_outlined,
                  color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Dark Mode',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textPri(context))),
              ),
              Switch(
                value: darkOn,
                onChanged: (v) {
                  AppStore.I.setDarkMode(v);
                  themeController.value =
                      v ? ThemeMode.dark : ThemeMode.light;
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
                                  return Text(labels[v.toInt()],
                                      style: TextStyle(
                                        color: AppColors.textSec(context),
                                        fontSize: 11,
                                      ));
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
                              sections: _pieSections(),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${AppStore.I.totalItemCount}',
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

  List<PieChartSectionData> _pieSections() {
    final items = AppStore.I.pantryItems;
    if (items.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: AppColors.chipBg(context),
          radius: 14,
          showTitle: false,
        ),
      ];
    }
    final produce = items.where((i) => i.category == 'Produce').length;
    final dairy = items.where((i) => i.category == 'Dairy').length;
    return [
      PieChartSectionData(
        value: produce.toDouble().clamp(0.1, 100),
        color: AppColors.primaryDark,
        radius: 14,
        showTitle: false,
      ),
      PieChartSectionData(
        value: dairy.toDouble().clamp(0.1, 100),
        color: AppColors.primaryLight,
        radius: 14,
        showTitle: false,
      ),
    ];
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
ok "Profile screen updated."

# =============================================================================
# 18. README — comprehensive version history + setup
# =============================================================================
info "Writing README.md..."

cat > README.md <<'README_EOF'
# ShelfLife

> Freshness at your fingertips.

A multipurpose pantry management Flutter app that helps you track expiry dates,
reduce food waste, and discover recipes based on what you already have.

---

## Table of Contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Tech Stack](#tech-stack)
4. [Getting Started](#getting-started)
5. [Project Structure](#project-structure)
6. [Version History](#version-history)
7. [Roadmap](#roadmap)

---

## Features

### Core
- **Pantry tracking** — log items with quantity, category, expiry date, storage location
- **Expiry insights** — color-coded badges (safe / soon / expired), live "days until" counts
- **Use First** — items closest to expiring surfaced first
- **Recipe matching** — recipes ranked by what's in your pantry vs what's missing
- **Shopping list** — tick items, then move to pantry in one tap
- **Favorites** — save recipes you've liked with one tap on the heart
- **Dark mode** — app-wide light/dark theme, preference persists

### Pantry CRUD
- Add via main "Add" tab (form) or bottom-sheet
- Tap any pantry card → edit in bottom sheet
- Swipe-left to delete, with confirmation + Undo
- Live search + category filter (work together)

### Persistence
- Hive local database — everything persists across app restarts
- Sample data seeded on first launch
- Reset Demo Data option (Profile → Reset Demo Data)

### Onboarding
- 3-step signup: account → dietary prefs → allergies
- Unified header across all 3 steps

### Insights
- Total items, expiring soon counter
- Wasted-items bar chart
- Suggested groceries (derived from expired/expiring items)
- Pantry analytics on Profile: waste reduction line chart, category pie chart

---

## Screenshots

Drop screenshots in `docs/screenshots/` and reference them here once captured.

| Home | Pantry | Recipes | Add | Profile |
|------|--------|---------|-----|---------|

---

## Tech Stack

- **Framework**: Flutter 3.41+
- **Language**: Dart 3.11+
- **State**: `ChangeNotifier` + `ListenableBuilder` (no third-party state mgmt)
- **Persistence**: [Hive](https://pub.dev/packages/hive) 2.x (key-value, no schema/codegen)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Fonts**: [google_fonts](https://pub.dev/packages/google_fonts) (Poppins)
- **Icons / SVG**: [flutter_svg](https://pub.dev/packages/flutter_svg)
- **Target**: Android (iOS folder present but unverified)

---

## Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Android Studio / Xcode with an emulator or real device
- macOS, Linux, or Windows

### First-time setup

```bash
git clone <repo>
cd demoui
flutter pub get
flutter run
```

If you're switching from a previous version and you see weird build errors:

```bash
flutter clean
flutter pub get
flutter run
```

### Assets

Drop image assets into the `assets/` folders described in `assets/README.md`.
The app gracefully falls back to placeholders for any missing image, so the
app remains runnable without them.

Required logo files (lowercase!):
- `assets/logo/shelflife_logo.svg` — green "ShelfLife" wordmark
- `assets/logo/shelflife_icon.svg` — green basket icon

---

## Project Structure

```
lib/
├── main.dart                    # initializes Hive + theme controller
├── theme/
│   ├── app_colors.dart          # light + dark palettes + context helpers
│   ├── app_theme.dart           # ThemeData for light + dark
│   └── theme_controller.dart    # ValueNotifier<ThemeMode>
├── store/
│   └── app_store.dart           # single Hive-backed store, ChangeNotifier
├── data/
│   ├── seed_data.dart           # first-launch seed (pantry + shopping)
│   └── recipe_data.dart         # 15 hardcoded recipes
├── models/
│   ├── pantry_item.dart
│   ├── recipe.dart
│   └── shopping_item.dart
├── widgets/
│   ├── app_logo.dart            # safe SVG loader with fallback
│   ├── main_app_bar.dart        # top app bar w/ cart + bell
│   ├── bottom_nav.dart          # 5-tab bottom nav, +Add FAB center
│   ├── onboarding_header.dart   # shared header for onboarding steps
│   └── pantry_item_card.dart    # used everywhere we list items
└── screens/
    ├── misc/
    │   ├── splash_screen.dart
    │   ├── notifications_screen.dart
    │   ├── edit_profile_screen.dart
    │   └── privacy_screen.dart
    ├── auth/
    │   └── login_screen.dart
    ├── onboarding/
    │   ├── signup_step1_screen.dart
    │   ├── signup_step2_screen.dart
    │   └── signup_step3_screen.dart
    ├── main/
    │   ├── main_shell.dart       # holds 5 tabs
    │   ├── home_screen.dart
    │   ├── pantry_screen.dart
    │   ├── add_item_screen.dart
    │   ├── recipe_screen.dart
    │   └── profile_screen.dart
    ├── pantry_detail/
    │   └── pantry_item_sheet.dart  # add/edit bottom sheet
    ├── recipes/
    │   ├── recipe_detail_screen.dart
    │   ├── use_first_all_screen.dart
    │   ├── use_first_recipes_screen.dart
    │   ├── matches_for_you_screen.dart
    │   └── favorites_screen.dart
    └── shopping/
        └── shopping_list_screen.dart

assets/
├── logo/      (shelflife_logo.svg, shelflife_icon.svg)
├── items/     (per-item PNGs)
├── recipes/   (per-recipe PNGs)
├── onboarding/(login_bg, signup_pantry, allergies_food)
└── profile/   (avatar_default)
```

---

## Version History

### v3.0 — Persistence + Full CRUD (current)
- ✨ **Hive local database** — pantry, shopping list, favorites, dark-mode preference all persist across restarts
- ✨ **Full pantry CRUD** — add, edit, delete via bottom sheet
- ✨ **Swipe-to-delete** on pantry + shopping cards with Undo
- ✨ **Tap-to-edit** — any pantry card opens edit bottom sheet
- ✨ **Live search + category filter** (work together) on Pantry screen
- ✨ **Favorite Recipes** — heart icon toggles, dedicated section + screen
- ✨ **Move checked shopping items → pantry** in one tap
- ✨ **Recipe Detail screen** — ingredients with have/need icons, missing-item shopping list button
- ✨ **"View All" screens** — Use First (pantry), Use First (recipes), Matches for you, Favorites
- ✨ **Expanded seed data** — 20 pantry items, 15 recipes, 12 shopping items
- ✨ **Pantry edit sheet** — name, qty, category, expiry, storage location, notes, image path
- ✨ **Storage location** — Fridge / Freezer / Pantry segmented control
- 🐛 Fixed signup step 3 blank-body bug (now uses unified onboarding header)
- 🐛 Fixed SVG missing-asset placeholder issue (filename normalization + flutter clean)
- 🐛 All 3 onboarding screens now share the same top header style
- 🛠️ Added "Reset Demo Data" option in Profile for easy demo restoration

### v2.0 — Dark Mode + New Screens
- 🎨 Full app-wide dark mode, toggle from Profile
- 🎨 Shopping cart icon (replaced basket) in main top bar
- 🎨 Bottom nav active indicator is a circle (was an oval)
- 🎨 Add (+) FAB uses a darker green shade
- ➕ Edit Profile Details screen
- ➕ Privacy & Data screen with toggles + data export
- ✏️ User: Anubhav Silwal / anubhav@shelflife.app
- 🐛 Fixed main-screen bottom-nav overflow (6px)
- 🐛 Fixed signup step 1 right overflow (12px)
- 🐛 Fixed signup step 3 blank body
- 🐛 Fixed SVG crashes when assets missing (silent fallback)
- 🐛 All `const`/lint warnings cleared, `dart fix --apply` auto-runs
- 🐛 `DropdownButtonFormField.value` → `initialValue` (Flutter 3.41+ compat)

### v1.0 — Initial UI
- 🎉 Splash screen with auto-advance
- 🎉 Login screen (Google / Facebook / Email)
- 🎉 3-step signup (Account / Dietary / Allergies)
- 🎉 Main shell with 5 tabs (Home / Pantry / Add / Recipe / Profile)
- 🎉 Pantry Insights dashboard
- 🎉 Use First card list
- 🎉 Pantry list with category filter
- 🎉 Recipe screen with featured + ingredient picker + matches
- 🎉 Add Item form (manual entry, barcode placeholder)
- 🎉 Profile with dietary focus, allergies, analytics, account settings
- 🎉 Shopping List screen
- 🎉 Notifications screen
- 🎉 Theme system (light only at this stage)
- 🎉 fl_chart integration (bar / line / pie)

---

## Roadmap

Possible features for upcoming versions:

- **v4** — Real barcode scanning (mobile_scanner)
- **v4** — Per-item image picking (image_picker)
- **v4** — Push notifications for expiring items (flutter_local_notifications)
- **v4** — Authentication (Firebase Auth or similar)
- **v5** — Cloud sync (Firebase / Supabase)
- **v5** — Sharing pantry with family members
- **v5** — Voice input ("Hey ShelfLife, add 2 lbs of chicken")
- **v6** — Recipe import via URL
- **v6** — AI-powered recipe suggestions

---

## Switching Between Versions

This project uses git tags for version checkpoints. To navigate:

```bash
git tag                    # list all version tags
git checkout v1            # browse v1 source (read-only)
git checkout v2            # browse v2 source
git checkout main          # back to latest
```

To roll back permanently to an older version:

```bash
git reset --hard v2        # wipes all changes after v2
```

To save the current version:

```bash
git add .
git commit -m "vN complete and working"
git tag vN
```

---

## License

For educational use. Sample data and recipes are not commercial.
README_EOF
ok "README.md written."

# =============================================================================
# 19. Clean + pub get + dart fix
# =============================================================================
info "Cleaning Flutter build cache (so new assets are picked up)..."
if command -v flutter >/dev/null 2>&1; then
  flutter clean >/dev/null 2>&1 || warn "flutter clean had issues, continuing..."
  ok "Build cache cleared."
  info "Running flutter pub get..."
  flutter pub get
  ok "Dependencies installed."
else
  warn "flutter command not found. Run: flutter clean && flutter pub get"
fi

info "Running dart fix for any remaining lints..."
if command -v dart >/dev/null 2>&1; then
  dart fix --apply 2>/dev/null || warn "dart fix had warnings — non-fatal."
fi

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  ShelfLife v3 update complete!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo
echo "What's new in v3:"
echo "  ✓ Hive persistence — everything saves across restarts"
echo "  ✓ Full pantry CRUD with swipe-to-delete + Undo"
echo "  ✓ Tap any pantry card → edit in bottom sheet"
echo "  ✓ Live search + category filter on Pantry"
echo "  ✓ Favorite Recipes section + dedicated screen"
echo "  ✓ Recipe Detail screen (ingredients with have/need)"
echo "  ✓ View All screens for Use First and Matches"
echo "  ✓ 20 pantry items, 15 recipes, 12 shopping items seeded"
echo "  ✓ Shopping list -> pantry move (one tap)"
echo "  ✓ Dark mode preference persists"
echo "  ✓ Fixed signup step 3 (now uses unified header)"
echo "  ✓ SVG files normalized to lowercase + flutter clean ran"
echo "  ✓ Reset Demo Data option in Profile (for demos)"
echo
echo "Next steps:"
echo "  1. In Android Studio: File → Invalidate Caches / Restart"
echo "  2. flutter run"
echo
echo "Saving v3 to git:"
echo "  git add ."
echo "  git commit -m \"v3 complete and working\""
echo "  git tag v3"
echo
echo "Rolling back to v2 (if needed):"
echo "  git reset --hard v2"
echo
