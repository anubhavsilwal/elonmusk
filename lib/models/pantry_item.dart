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
