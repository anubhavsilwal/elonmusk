import 'package:flutter/material.dart';
import '../../data/recipe_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../main/recipe_screen.dart';

class UseFirstRecipesScreen extends StatelessWidget {
  const UseFirstRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipes = RecipeData.useFirst.isEmpty
        ? RecipeData.all.take(5).toList()
        : RecipeData.useFirst;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text('Use First Suggestions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          Text(
              'Recipes that use your expiring items so nothing goes to waste.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 16),
          ...recipes.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: matchCard(context, r),
              )),
        ],
      ),
    );
  }
}
