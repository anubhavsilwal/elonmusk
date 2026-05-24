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
