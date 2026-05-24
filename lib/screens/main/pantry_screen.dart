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
