import 'package:flutter/material.dart';
import '../../data/sample_data.dart';
import '../../models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_app_bar.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final List<String> _selectedIngredients = ['Chicken Breast', 'Bell Peppers'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Use First Suggestions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _featuredCard(SampleData.featuredRecipe),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallRecipe(SampleData.smallRecipes[0])),
              const SizedBox(width: 12),
              Expanded(child: _smallRecipe(SampleData.smallRecipes[1])),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Find by Ingredients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedIngredients.map((i) => Chip(
                    label: Text(i,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                    backgroundColor: AppColors.primaryLight,
                    deleteIcon: const Icon(Icons.close,
                        size: 16, color: AppColors.primaryDark),
                    onDeleted: () =>
                        setState(() => _selectedIngredients.remove(i)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  )),
              ActionChip(
                label: const Icon(Icons.add,
                    size: 18, color: AppColors.textPrimary),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.divider),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Matches for you',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...SampleData.matches.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _matchCard(r),
              )),
        ],
      ),
    );
  }

  Widget _featuredCard(Recipe r) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            r.imageAsset!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: const Color(0xFF6B7280),
              child: const Center(
                child: Icon(Icons.restaurant, size: 64, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('HIGH URGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    )),
              ),
              const SizedBox(height: 8),
              Text(r.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              const Text('Uses your expiring spinach and strawberries.',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallRecipe(Recipe r) {
    return Container(
      height: 130,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              r.imageAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF6B7280),
                child: const Center(
                  child: Icon(Icons.restaurant, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 10,
            child: Text(r.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(Recipe r) {
    final accent = r.allFound ? AppColors.safe : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              r.imageAsset!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.chipBg,
                child: const Icon(Icons.restaurant,
                    color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${r.time} • ${r.difficulty}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                if (r.allFound)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ALL INGREDIENTS FOUND',
                        style: TextStyle(
                          color: AppColors.safe,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        )),
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('1 MISSING',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Text(r.missingNote ?? '',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: AppColors.warning),
        ],
      ),
    );
  }
}
