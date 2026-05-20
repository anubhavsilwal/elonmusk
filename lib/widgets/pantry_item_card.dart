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
