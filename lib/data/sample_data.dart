import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class SampleData {
  // ---- Home: Use First -----------------------------------------------------
  static const List<PantryItem> useFirst = [
    PantryItem(
      name: 'Whole Milk (1L)',
      category: 'Dairy',
      quantity: '1L',
      daysUntilExpiry: 1,
      expiryLabel: 'Expires tomorrow',
      progress: 0.2,
      imageAsset: 'assets/items/whole_milk.png',
    ),
    PantryItem(
      name: 'Baby Spinach',
      category: 'Produce',
      quantity: '1 bag',
      daysUntilExpiry: 2,
      expiryLabel: 'Exp: Oct 24',
      progress: 0.4,
      imageAsset: 'assets/items/baby_spinach.png',
    ),
    PantryItem(
      name: 'Greek Yogurt',
      category: 'Dairy',
      quantity: '1 tub',
      daysUntilExpiry: 3,
      expiryLabel: 'Exp: Oct 25',
      progress: 0.5,
      imageAsset: 'assets/items/greek_yogurt.png',
    ),
    PantryItem(
      name: 'Avocados (2x)',
      category: 'Produce',
      quantity: '2 units',
      daysUntilExpiry: 5,
      expiryLabel: 'Exp: Oct 27',
      progress: 0.7,
      imageAsset: 'assets/items/avocados.png',
    ),
    PantryItem(
      name: 'Strawberries',
      category: 'Produce',
      quantity: '1 pack',
      daysUntilExpiry: 6,
      expiryLabel: 'Exp: Oct 28',
      progress: 0.85,
      imageAsset: 'assets/items/strawberries.png',
    ),
  ];

  // ---- Pantry full list ----------------------------------------------------
  static const List<PantryItem> pantry = [
    PantryItem(
      name: 'Whole Milk',
      category: 'Dairy',
      quantity: '1 Gallon',
      daysUntilExpiry: 0,
      expiryLabel: 'Expires Today',
      progress: 0.95,
      imageAsset: 'assets/items/whole_milk.png',
    ),
    PantryItem(
      name: 'Baby Carrots',
      category: 'Produce',
      quantity: '2 Bags',
      daysUntilExpiry: 3,
      expiryLabel: 'Expires in 3 days',
      progress: 0.6,
      imageAsset: 'assets/items/baby_carrots.png',
    ),
    PantryItem(
      name: 'Chicken Breast',
      category: 'Meat',
      quantity: '1.5 lbs',
      daysUntilExpiry: 12,
      expiryLabel: 'Expires in 12 days',
      progress: 0.4,
      imageAsset: 'assets/items/chicken_breast.png',
    ),
    PantryItem(
      name: 'Avocados',
      category: 'Produce',
      quantity: '3 units',
      daysUntilExpiry: 8,
      expiryLabel: 'Expires in 8 days',
      progress: 0.55,
      imageAsset: 'assets/items/avocados.png',
    ),
    PantryItem(
      name: 'Chicken Breast',
      category: 'Meat',
      quantity: '1 lb',
      daysUntilExpiry: 4,
      expiryLabel: 'Expires in 4 days (Oct 26)',
      progress: 0.7,
      imageAsset: 'assets/items/chicken_breast.png',
    ),
    PantryItem(
      name: 'Large Eggs (12pk)',
      category: 'Dairy',
      quantity: '1 Carton',
      daysUntilExpiry: 8,
      expiryLabel: 'Expires in 8 days (Oct 30)',
      progress: 1.0,
      imageAsset: 'assets/items/large_eggs.png',
    ),
    PantryItem(
      name: 'Salted Butter',
      category: 'Dairy',
      quantity: '4 sticks',
      daysUntilExpiry: 12,
      expiryLabel: 'Expires in 12 days (Nov 3)',
      progress: 0.5,
      imageAsset: 'assets/items/salted_butter.png',
    ),
    PantryItem(
      name: 'Red Bell Peppers',
      category: 'Produce',
      quantity: '2 units',
      daysUntilExpiry: 3,
      expiryLabel: 'Expires in 3 days (Oct 25)',
      progress: 0.8,
      imageAsset: 'assets/items/red_bell_peppers.png',
    ),
  ];

  // ---- Recipes -------------------------------------------------------------
  static const Recipe featuredRecipe = Recipe(
    title: 'Spinach & Berry Summer Salad',
    time: '15 mins',
    difficulty: 'Easy',
    imageAsset: 'assets/recipes/spinach_berry_salad.png',
    urgent: true,
  );

  static const List<Recipe> smallRecipes = [
    Recipe(
      title: 'Zucchini & Leek Cream Soup',
      time: '30 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/zucchini_leek_soup.png',
    ),
    Recipe(
      title: 'Berry Compote Parfait',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/berry_compote_parfait.png',
    ),
  ];

  static const List<Recipe> matches = [
    Recipe(
      title: 'Lemon Garlic Stir-Fry',
      time: '20 mins',
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/lemon_garlic_stirfry.png',
      allFound: true,
    ),
    Recipe(
      title: 'Honey Glazed Chicken',
      time: '35 mins',
      difficulty: 'Medium',
      imageAsset: 'assets/recipes/honey_glazed_chicken.png',
      allFound: false,
      missingNote: 'Need: Honey',
    ),
    Recipe(
      title: 'Rainbow Veggie Wrap',
      time: '10 mins',
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/rainbow_veggie_wrap.png',
      allFound: true,
    ),
  ];

  // ---- Suggested Groceries on Home ----------------------------------------
  static const List<Map<String, String>> suggestedGroceries = [
    {'name': 'Pancetta', 'reason': 'Expired', 'type': 'expired'},
    {
      'name': 'Parmesan',
      'reason': 'From recipe: Spaghetti Carbonara',
      'type': 'recipe',
    },
    {'name': 'Milk', 'reason': 'Low stock', 'type': 'low'},
  ];

  // ---- Shopping list -------------------------------------------------------
  static List<ShoppingItem> shoppingList() => [
        ShoppingItem(name: 'Pancetta', note: 'Expired item'),
        ShoppingItem(name: 'Parmesan', note: 'From recipe: Spaghetti Carbonara'),
        ShoppingItem(name: 'Milk', note: 'Low stock'),
        ShoppingItem(name: 'Whole-Wheat Bread'),
        ShoppingItem(name: 'Olive Oil', note: 'Almost out'),
        ShoppingItem(name: 'Fresh Basil'),
        ShoppingItem(name: 'Tomatoes (6)'),
      ];
}
