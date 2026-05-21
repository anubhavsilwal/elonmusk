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
