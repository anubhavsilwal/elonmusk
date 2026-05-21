import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/shopping_item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final List<ShoppingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = SampleData.shoppingList();
  }

  int get _checkedCount => _items.where((i) => i.checked).length;

  void _addCheckedToPantry() {
    final count = _checkedCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tick items first to add them to pantry.')),
      );
      return;
    }
    setState(() => _items.removeWhere((i) => i.checked));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count item(s) added to pantry.')),
    );
  }

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
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: Column(
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
                Text('${_items.length} items',
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = _items[i];
                return InkWell(
                  onTap: () => setState(() => item.checked = !item.checked),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.checked,
                          onChanged: (v) =>
                              setState(() => item.checked = v ?? false),
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
                          onPressed: () =>
                              setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: AppColors.bg(context),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _addCheckedToPantry,
            icon: const Icon(Icons.kitchen),
            label: Text(_checkedCount > 0
                ? 'Add $_checkedCount item(s) to Pantry'
                : 'Add Checked Items to Pantry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Shopping List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Olive Oil'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _items.add(ShoppingItem(name: name)));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
