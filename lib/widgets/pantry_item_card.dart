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
