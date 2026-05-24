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
  final StorageLocation _storage = StorageLocation.fridge;

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
