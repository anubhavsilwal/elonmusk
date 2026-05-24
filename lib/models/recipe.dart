class Recipe {
  final String id;
  final String title;
  final String time;
  final String difficulty;
  final String? imageAsset;
  final bool allFound;
  final String? missingNote;
  final bool urgent;
  final String description;
  final List<String> ingredients;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.difficulty,
    this.imageAsset,
    this.allFound = true,
    this.missingNote,
    this.urgent = false,
    this.description = '',
    this.ingredients = const [],
    this.tags = const [],
  });
}
