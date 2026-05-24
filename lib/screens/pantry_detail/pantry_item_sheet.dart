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
              style: const ButtonStyle(
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
