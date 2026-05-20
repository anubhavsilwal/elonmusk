class Recipe {
  final String title;
  final String time;
  final String difficulty;
  final String? imageAsset;
  final bool allFound;
  final String? missingNote;
  final bool urgent;

  const Recipe({
    required this.title,
    required this.time,
    required this.difficulty,
    this.imageAsset,
    this.allFound = true,
    this.missingNote,
    this.urgent = false,
  });
}
