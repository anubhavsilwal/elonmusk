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
