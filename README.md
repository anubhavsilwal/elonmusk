# ShelfLife

> Freshness at your fingertips.

A multipurpose pantry management Flutter app that helps you track expiry dates,
reduce food waste, and discover recipes based on what you already have.

---

## Table of Contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Tech Stack](#tech-stack)
4. [Getting Started](#getting-started)
5. [Project Structure](#project-structure)
6. [Version History](#version-history)
7. [Roadmap](#roadmap)

---

## Features

### Core
- **Pantry tracking** — log items with quantity, category, expiry date, storage location
- **Expiry insights** — color-coded badges (safe / soon / expired), live "days until" counts
- **Use First** — items closest to expiring surfaced first
- **Recipe matching** — recipes ranked by what's in your pantry vs what's missing
- **Shopping list** — tick items, then move to pantry in one tap
- **Favorites** — save recipes you've liked with one tap on the heart
- **Dark mode** — app-wide light/dark theme, preference persists

### Pantry CRUD
- Add via main "Add" tab (form) or bottom-sheet
- Tap any pantry card → edit in bottom sheet
- Swipe-left to delete, with confirmation + Undo
- Live search + category filter (work together)

### Persistence
- Hive local database — everything persists across app restarts
- Sample data seeded on first launch
- Reset Demo Data option (Profile → Reset Demo Data)

### Onboarding
- 3-step signup: account → dietary prefs → allergies
- Unified header across all 3 steps

### Insights
- Total items, expiring soon counter
- Wasted-items bar chart
- Suggested groceries (derived from expired/expiring items)
- Pantry analytics on Profile: waste reduction line chart, category pie chart

---

## Screenshots

Drop screenshots in `docs/screenshots/` and reference them here once captured.

| Home | Pantry | Recipes | Add | Profile |
|------|--------|---------|-----|---------|

---

## Tech Stack

- **Framework**: Flutter 3.41+
- **Language**: Dart 3.11+
- **State**: `ChangeNotifier` + `ListenableBuilder` (no third-party state mgmt)
- **Persistence**: [Hive](https://pub.dev/packages/hive) 2.x (key-value, no schema/codegen)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Fonts**: [google_fonts](https://pub.dev/packages/google_fonts) (Poppins)
- **Icons / SVG**: [flutter_svg](https://pub.dev/packages/flutter_svg)
- **Target**: Android (iOS folder present but unverified)

---

## Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Android Studio / Xcode with an emulator or real device
- macOS, Linux, or Windows

### First-time setup

```bash
git clone <repo>
cd demoui
flutter pub get
flutter run
```

If you're switching from a previous version and you see weird build errors:

```bash
flutter clean
flutter pub get
flutter run
```

### Assets

Drop image assets into the `assets/` folders described in `assets/README.md`.
The app gracefully falls back to placeholders for any missing image, so the
app remains runnable without them.

Required logo files (lowercase!):
- `assets/logo/shelflife_logo.svg` — green "ShelfLife" wordmark
- `assets/logo/shelflife_icon.svg` — green basket icon

---

## Project Structure

```
lib/
├── main.dart                    # initializes Hive + theme controller
├── theme/
│   ├── app_colors.dart          # light + dark palettes + context helpers
│   ├── app_theme.dart           # ThemeData for light + dark
│   └── theme_controller.dart    # ValueNotifier<ThemeMode>
├── store/
│   └── app_store.dart           # single Hive-backed store, ChangeNotifier
├── data/
│   ├── seed_data.dart           # first-launch seed (pantry + shopping)
│   └── recipe_data.dart         # 15 hardcoded recipes
├── models/
│   ├── pantry_item.dart
│   ├── recipe.dart
│   └── shopping_item.dart
├── widgets/
│   ├── app_logo.dart            # safe SVG loader with fallback
│   ├── main_app_bar.dart        # top app bar w/ cart + bell
│   ├── bottom_nav.dart          # 5-tab bottom nav, +Add FAB center
│   ├── onboarding_header.dart   # shared header for onboarding steps
│   └── pantry_item_card.dart    # used everywhere we list items
└── screens/
    ├── misc/
    │   ├── splash_screen.dart
    │   ├── notifications_screen.dart
    │   ├── edit_profile_screen.dart
    │   └── privacy_screen.dart
    ├── auth/
    │   └── login_screen.dart
    ├── onboarding/
    │   ├── signup_step1_screen.dart
    │   ├── signup_step2_screen.dart
    │   └── signup_step3_screen.dart
    ├── main/
    │   ├── main_shell.dart       # holds 5 tabs
    │   ├── home_screen.dart
    │   ├── pantry_screen.dart
    │   ├── add_item_screen.dart
    │   ├── recipe_screen.dart
    │   └── profile_screen.dart
    ├── pantry_detail/
    │   └── pantry_item_sheet.dart  # add/edit bottom sheet
    ├── recipes/
    │   ├── recipe_detail_screen.dart
    │   ├── use_first_all_screen.dart
    │   ├── use_first_recipes_screen.dart
    │   ├── matches_for_you_screen.dart
    │   └── favorites_screen.dart
    └── shopping/
        └── shopping_list_screen.dart

assets/
├── logo/      (shelflife_logo.svg, shelflife_icon.svg)
├── items/     (per-item PNGs)
├── recipes/   (per-recipe PNGs)
├── onboarding/(login_bg, signup_pantry, allergies_food)
└── profile/   (avatar_default)
```

---

## Version History

### v3.0 — Persistence + Full CRUD (current)
- ✨ **Hive local database** — pantry, shopping list, favorites, dark-mode preference all persist across restarts
- ✨ **Full pantry CRUD** — add, edit, delete via bottom sheet
- ✨ **Swipe-to-delete** on pantry + shopping cards with Undo
- ✨ **Tap-to-edit** — any pantry card opens edit bottom sheet
- ✨ **Live search + category filter** (work together) on Pantry screen
- ✨ **Favorite Recipes** — heart icon toggles, dedicated section + screen
- ✨ **Move checked shopping items → pantry** in one tap
- ✨ **Recipe Detail screen** — ingredients with have/need icons, missing-item shopping list button
- ✨ **"View All" screens** — Use First (pantry), Use First (recipes), Matches for you, Favorites
- ✨ **Expanded seed data** — 20 pantry items, 15 recipes, 12 shopping items
- ✨ **Pantry edit sheet** — name, qty, category, expiry, storage location, notes, image path
- ✨ **Storage location** — Fridge / Freezer / Pantry segmented control
- 🐛 Fixed signup step 3 blank-body bug (now uses unified onboarding header)
- 🐛 Fixed SVG missing-asset placeholder issue (filename normalization + flutter clean)
- 🐛 All 3 onboarding screens now share the same top header style
- 🛠️ Added "Reset Demo Data" option in Profile for easy demo restoration

### v2.0 — Dark Mode + New Screens
- 🎨 Full app-wide dark mode, toggle from Profile
- 🎨 Shopping cart icon (replaced basket) in main top bar
- 🎨 Bottom nav active indicator is a circle (was an oval)
- 🎨 Add (+) FAB uses a darker green shade
- ➕ Edit Profile Details screen
- ➕ Privacy & Data screen with toggles + data export
- ✏️ User: Anubhav Silwal / anubhav@shelflife.app
- 🐛 Fixed main-screen bottom-nav overflow (6px)
- 🐛 Fixed signup step 1 right overflow (12px)
- 🐛 Fixed signup step 3 blank body
- 🐛 Fixed SVG crashes when assets missing (silent fallback)
- 🐛 All `const`/lint warnings cleared, `dart fix --apply` auto-runs
- 🐛 `DropdownButtonFormField.value` → `initialValue` (Flutter 3.41+ compat)

### v1.0 — Initial UI
- 🎉 Splash screen with auto-advance
- 🎉 Login screen (Google / Facebook / Email)
- 🎉 3-step signup (Account / Dietary / Allergies)
- 🎉 Main shell with 5 tabs (Home / Pantry / Add / Recipe / Profile)
- 🎉 Pantry Insights dashboard
- 🎉 Use First card list
- 🎉 Pantry list with category filter
- 🎉 Recipe screen with featured + ingredient picker + matches
- 🎉 Add Item form (manual entry, barcode placeholder)
- 🎉 Profile with dietary focus, allergies, analytics, account settings
- 🎉 Shopping List screen
- 🎉 Notifications screen
- 🎉 Theme system (light only at this stage)
- 🎉 fl_chart integration (bar / line / pie)

---

## Roadmap

Possible features for upcoming versions:

- **v4** — Real barcode scanning (mobile_scanner)
- **v4** — Per-item image picking (image_picker)
- **v4** — Push notifications for expiring items (flutter_local_notifications)
- **v4** — Authentication (Firebase Auth or similar)
- **v5** — Cloud sync (Firebase / Supabase)
- **v5** — Sharing pantry with family members
- **v5** — Voice input ("Hey ShelfLife, add 2 lbs of chicken")
- **v6** — Recipe import via URL
- **v6** — AI-powered recipe suggestions

---

## Switching Between Versions

This project uses git tags for version checkpoints. To navigate:

```bash
git tag                    # list all version tags
git checkout v1            # browse v1 source (read-only)
git checkout v2            # browse v2 source
git checkout main          # back to latest
```

To roll back permanently to an older version:

```bash
git reset --hard v2        # wipes all changes after v2
```

To save the current version:

```bash
git add .
git commit -m "vN complete and working"
git tag vN
```

---

## License

For educational use. Sample data and recipes are not commercial.
