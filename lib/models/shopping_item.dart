class ShoppingItem {
  final String name;
  final String? note;
  bool checked;

  ShoppingItem({
    required this.name,
    this.note,
    this.checked = false,
  });
}
