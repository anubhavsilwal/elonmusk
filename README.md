# ShelfLife

> **Freshness at your fingertips.**

A multipurpose pantry management Flutter app that helps you track expiry dates, reduce food waste, and discover recipes from what you already have on hand.

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Getting Started](#getting-started)
4. [Assets Reference](#assets-reference)
5. [Project Structure](#project-structure)
6. [Version History](#version-history)
7. [Working with Versions (git)](#working-with-versions-git)
8. [Roadmap](#roadmap)
9. [Contributing & Maintenance](#contributing--maintenance)

---

## Features

### Core
- **Pantry tracking** — log items with quantity, category, expiry date, storage location (Fridge / Freezer / Pantry), notes, and optional image
- **Expiry insights** — color-coded badges (safe / soon / expired) with live "days until" counts that update every time the app opens
- **Use First** — items closest to expiring are surfaced first across Home and Pantry views
- **Recipe matching** — recipes ranked by what's in your pantry vs what's missing
- **Shopping list** — tick items, then move all checked items to pantry in one tap
- **Favorites** — save recipes you've liked with one tap on the heart icon
- **Dark mode** — full app-wide light/dark theme; preference persists across launches

### Pantry CRUD
- Add via dedicated "Add" tab (form) or floating bottom sheet
- **Tap any pantry card** → opens edit bottom sheet
- **Swipe-left** to delete, with confirmation dialog + **Undo** snackbar
- Bottom sheet fields: name, quantity, category, expiry date, storage location, image path, notes
- Inline **live search** + category filter chips that work together
- Empty-state messaging when search/filter yields no matches

### Persistence (v3+)
- **Hive local database** — pantry, shopping list, favorites, and dark-mode preference all persist across restarts
- Sample data seeded on first launch
- **"Reset Demo Data"** option on Profile to wipe and reseed for demo purposes

### Onboarding
- 3-step signup flow: Account Basics → Dietary Preferences → Food Allergies
- Unified header across all steps (logo + ShelfLife wordmark)
- Progress bar shows current step

### Insights & Dashboards
- **Home Dashboard**: total items, expiring-soon count, wasted-items bar chart, suggested groceries (derived live from your pantry's expired/expiring items)
- **Profile Analytics**: waste reduction line chart, category distribution donut chart
- **Notifications screen** with sample alerts for expiring items

### Recipe Discovery
- **Use First Suggestions** with a featured "high urgency" card + 2 smaller picks
- **Find by Ingredients** — chip-based selector (add/remove ingredients)
- **Favorite Recipes** carousel (above Matches)
- **Matches for you** — full recipe cards with "all ingredients found" or "missing" badge
- **Recipe Detail screen** — hero image, full ingredient list with green-check (have) / red-X (need) icons, one-tap "+ Buy" to add missing ingredient to shopping list
- **"View All" screens** for Use First, Use First Recipes, Matches for you, and Favorites

### Settings & Account
- Edit Profile Details (avatar, personal info, password change)
- Privacy & Data screen (data sharing toggles, data export, login activity, connected devices, legal docs, clear-all-data action)
- Delete Account flow (currently logs out and returns to Login)

---

## Tech Stack

- **Framework**: Flutter 3.41+
- **Language**: Dart 3.11+
- **State management**: `ChangeNotifier` + `ListenableBuilder` (no third-party state library)
- **Persistence**: [Hive](https://pub.dev/packages/hive) 2.x (key-value, no schema/codegen)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart) (bar, line, pie)
- **Fonts**: [google_fonts](https://pub.dev/packages/google_fonts) — Poppins
- **SVG**: [flutter_svg](https://pub.dev/packages/flutter_svg) with safe FutureBuilder loading
- **Date formatting**: [intl](https://pub.dev/packages/intl)
- **Target**: Android (Pixel 9a resolution); iOS folder present but unverified

---

## Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Android Studio with Android emulator or physical device
- macOS, Linux, or Windows

### First-time setup

```bash
git clone <repo>
cd demoui
flutter pub get
flutter run
```

### If you're switching between versions or hitting weird build errors

```bash
flutter clean
flutter pub get
flutter run
```

### Common gotcha: emulator out of space

If you see `INSUFFICIENT_STORAGE` or `Requested internal only, but not enough space`, it's not a code issue — your Android emulator is full. Fix:

1. **Tools → Device Manager** in Android Studio
2. Click **⋮** next to your emulator → **Wipe Data**
3. Or create a new emulator with **Internal Storage: 8192 MB** (Show Advanced Settings)

---

## Assets Reference

All asset files live under `assets/`. The app gracefully falls back to placeholders for any missing image, so the project remains runnable without them — but for the polished look matching the design, drop in the files listed below.

> **All filenames are case-sensitive on Android.** Use exactly the names shown.

### `assets/logo/`

| File | Description |
|------|-------------|
| `shelflife_logo.svg` | Green "ShelfLife" wordmark, used in all top app bars and onboarding headers |
| `shelflife_icon.svg` | Green basket icon, used on splash + login screens |

### `assets/items/` *(pantry item thumbnails)*

| File | Item |
|------|------|
| `whole_milk.png` | Whole Milk |
| `baby_spinach.png` | Baby Spinach |
| `greek_yogurt.png` | Greek Yogurt |
| `avocados.png` | Avocados |
| `strawberries.png` | Strawberries |
| `baby_carrots.png` | Baby Carrots |
| `chicken_breast.png` | Chicken Breast (frozen, large) |
| `chicken_breast_2.png` | Chicken Breast (fresh, small) |
| `large_eggs.png` | Large Eggs (12pk) |
| `salted_butter.png` | Salted Butter |
| `red_bell_peppers.png` | Red Bell Peppers |
| `organic_kale.png` | Organic Kale |

*Items added in v3 (Whole-Wheat Bread, Cheddar Cheese, Tomatoes, Salmon Fillet, Olive Oil, Brown Rice, Blueberries, Ground Beef) currently use a fallback placeholder; drop matching PNGs in to upgrade them.*

### `assets/recipes/` *(recipe card images)*

| File | Recipe |
|------|--------|
| `spinach_berry_salad.png` | Spinach & Berry Summer Salad |
| `zucchini_leek_soup.png` | Zucchini & Leek Cream Soup |
| `berry_compote_parfait.png` | Berry Compote Parfait |
| `lemon_garlic_stirfry.png` | Lemon Garlic Stir-Fry |
| `honey_glazed_chicken.png` | Honey Glazed Chicken |
| `rainbow_veggie_wrap.png` | Rainbow Veggie Wrap |

*The remaining 9 recipes added in v3 (Avocado Egg Toast, Salmon Teriyaki Bowl, Classic Spaghetti Carbonara, Roasted Veggie Tray Bake, Yogurt Berry Smoothie, Cheesy Beef Tacos, Kale & Quinoa Power Bowl, Garlic Butter Shrimp, Eggs Benedict) use placeholder fallbacks.*

### `assets/onboarding/`

| File | Used on |
|------|---------|
| `login_bg.png` | Pantry-shelves header on login screen + Add Item screen banner |
| `signup_pantry.png` | Jars image on signup step 1 |
| `allergies_food.png` | Food-spread image on signup step 3 (allergies) |

### `assets/profile/`

| File | Used on |
|------|---------|
| `avatar_default.png` | Default user avatar (Profile + Edit Profile) |

### Adding new assets

When you add a new asset folder or file, the script-generated `pubspec.yaml` already registers all five top-level folders, so you just need to:

1. Drop the file into the correct folder
2. Run `flutter clean` then `flutter pub get`
3. Restart the app (hot reload won't always pick up new assets)

---

## Project Structure

```
lib/
├── main.dart                       # initializes Hive + theme controller
├── theme/
│   ├── app_colors.dart             # light + dark palettes + context helpers
│   ├── app_theme.dart              # ThemeData for light + dark
│   └── theme_controller.dart       # ValueNotifier<ThemeMode>
├── store/
│   └── app_store.dart              # single Hive-backed store, ChangeNotifier
├── data/
│   ├── seed_data.dart              # first-launch seed (pantry + shopping)
│   └── recipe_data.dart            # 15 hardcoded recipes
├── models/
│   ├── pantry_item.dart            # PantryItem + StorageLocation enum
│   ├── recipe.dart
│   └── shopping_item.dart
├── widgets/
│   ├── app_logo.dart               # safe SVG loader with fallback
│   ├── main_app_bar.dart           # top bar with cart + bell icons
│   ├── bottom_nav.dart             # 5-tab bottom nav, +Add center FAB
│   ├── onboarding_header.dart      # shared header for onboarding steps
│   └── pantry_item_card.dart       # reused everywhere we list items
└── screens/
    ├── misc/
    │   ├── splash_screen.dart
    │   ├── notifications_screen.dart
    │   ├── edit_profile_screen.dart
    │   └── privacy_screen.dart
    ├── auth/
    │   └── login_screen.dart
    ├── onboarding/
    │   ├── signup_step1_screen.dart    # account basics
    │   ├── signup_step2_screen.dart    # dietary preferences
    │   └── signup_step3_screen.dart    # food allergies
    ├── main/
    │   ├── main_shell.dart             # holds 5 tabs
    │   ├── home_screen.dart
    │   ├── pantry_screen.dart
    │   ├── add_item_screen.dart
    │   ├── recipe_screen.dart
    │   └── profile_screen.dart
    ├── pantry_detail/
    │   └── pantry_item_sheet.dart      # add/edit pantry item bottom sheet
    ├── recipes/
    │   ├── recipe_detail_screen.dart
    │   ├── use_first_all_screen.dart   # all pantry items by soonest expiry
    │   ├── use_first_recipes_screen.dart
    │   ├── matches_for_you_screen.dart
    │   └── favorites_screen.dart
    └── shopping/
        └── shopping_list_screen.dart

assets/
├── logo/        # shelflife_logo.svg, shelflife_icon.svg
├── items/       # per-item PNGs (see Assets Reference)
├── recipes/     # per-recipe PNGs
├── onboarding/  # login_bg, signup_pantry, allergies_food
└── profile/     # avatar_default
```

---

## Version History

> Versions are tagged in git as `v1`, `v2`, `v3`, etc. See [Working with Versions](#working-with-versions-git) below.

### v3.0 — Persistence + Full CRUD (current)

**New features**
- 💾 **Hive local database** — pantry, shopping list, favorites, dark-mode preference all persist across restarts
- ✏️ **Full pantry CRUD** — add, edit, delete via bottom sheet
- 👆 **Tap any pantry card** opens edit bottom sheet
- ⬅️ **Swipe-to-delete** on pantry + shopping cards with **Undo** snackbar
- 🔎 **Live search + category filter** (work together) on Pantry screen with empty-state messaging
- ❤️ **Favorite Recipes** — heart icon toggles favorites, dedicated horizontal section + full-screen view
- 🛒 **Move checked shopping items → pantry** in one tap
- 📖 **Recipe Detail screen** — ingredients with have/need icons, missing-item "+ Buy" → shopping list
- 📋 **"View All" screens**: Use First (pantry), Use First (recipes), Matches for you, Favorites
- 📦 **Storage location** — Fridge / Freezer / Pantry segmented control on edit sheet
- 🗒️ **Item notes** field on edit sheet
- 🌱 **Expanded seed data** — 20 pantry items, 15 recipes, 12 shopping items
- 🛠️ **"Reset Demo Data"** option in Profile for easy demo restoration

**Bug fixes**
- 🐛 Fixed signup step 3 blank-body bug — all 3 onboarding screens now share the same `OnboardingHeader` widget
- 🐛 Fixed SVG placeholder issue — script now normalizes filenames to lowercase + runs `flutter clean`
- 🐛 `DropdownButtonFormField.value` deprecation → `initialValue` (Flutter 3.41+ compat)
- 🐛 Removed unused `package:flutter/material.dart` import from `pantry_item.dart`

**Architecture changes**
- Single `AppStore` (singleton `ChangeNotifier`) is the source of truth for all data
- All list screens now use `StoreListener` (a `ListenableBuilder` wrapper) so they rebuild automatically on data changes
- `sample_data.dart` (v1/v2) split into `seed_data.dart` (write-once Hive seed) + `recipe_data.dart` (hardcoded recipes)

---

### v2.0 — Dark Mode + New Screens

**UI updates**
- 🌙 Full **app-wide dark mode**, toggle from Profile (theme switches in real time, every screen reacts)
- 🛒 Shopping **cart** icon (replaced basket) in main top bar
- ⭕ Bottom nav active indicator is now a **circle** (was an oval in v1)
- 🟢 **Add (+)** FAB uses a darker green shade (`#1B5E20`)
- 👤 User identity: **Anubhav Silwal** / `anubhav@shelflife.app`

**New screens**
- ✏️ **Edit Profile Details** — full form with avatar, personal info section, and password change section
- 🛡️ **Privacy & Data** — toggles for data sharing (anonymous analytics, personalized recs, location, crash reports), data export, login activity, connected devices, legal docs, clear-all-data destructive action

**Bug fixes**
- 🐛 Fixed main-screen bottom-nav overflow (6 px)
- 🐛 Fixed signup step 1 right overflow (12 px) — Birthdate/Gender row now uses `LayoutBuilder` to stack on narrow screens
- 🐛 Fixed signup step 3 partial-blank-body issue
- 🐛 Fixed SVG crashes when assets missing — `FutureBuilder` checks `rootBundle.load()` before rendering, falls back silently
- 🐛 Cleared all `const`/lint warnings; script now runs `dart fix --apply` automatically

---

### v1.0 — Initial UI

**Screens shipped**
- 🎬 Splash screen with 2-second auto-advance
- 🔐 Login screen (Google / Facebook / Email)
- 📝 3-step signup (Account / Dietary Preferences / Food Allergies)
- 🏠 Main shell with 5 tabs (Home / Pantry / Add / Recipe / Profile)
- 📊 Pantry Insights dashboard (total items, expiring soon, wasted items chart)
- 🥦 Use First card list on Home
- 📋 Pantry list with category filter chips
- 🍳 Recipe screen with featured + ingredient picker + matches
- ➕ Add Item form (manual entry, barcode placeholder)
- 👤 Profile with dietary focus, allergies, analytics, account settings
- 🛒 Shopping List screen
- 🔔 Notifications screen

**Infrastructure**
- 🎨 Theme system (light only at this stage)
- 📈 fl_chart integration (bar / line / pie)
- 🔤 Poppins font via google_fonts
- 🖼️ SVG support via flutter_svg
- 🧩 Reusable widgets: `PantryItemCard`, `MainAppBar`, `ShelfBottomNav`

---

## Working with Versions (git)

This project uses git tags as version checkpoints. After every successful update, commit and tag:

```bash
git add .
git commit -m "vN complete and working"
git tag vN
```

### List all tagged versions

```bash
git tag                       # shows: v1, v2, v3, ...
git log --oneline --decorate  # shows commits with their tags
```

### Browse an older version (read-only)

```bash
git checkout v1               # poke around v1's code
git checkout v2               # ...or v2
git checkout main             # return to latest
```

### Permanently roll back

```bash
git reset --hard v2           # nukes everything after v2, no undo
```

### See what changed between two versions

```bash
git diff v1 v2                # full diff
git diff v2 v3 --stat         # just a file-level summary
git log v2..v3 --oneline      # commit messages between v2 and v3
```

### Make a safety backup without git

```bash
cd ..
cp -r demoui demoui_v3_backup
```

---

## Roadmap

Features under consideration for upcoming versions:

### v4 — Native integrations
- 📷 Real barcode scanning ([mobile_scanner](https://pub.dev/packages/mobile_scanner))
- 🖼️ Per-item image picking ([image_picker](https://pub.dev/packages/image_picker)) with on-device storage
- 🔔 Local push notifications for expiring items ([flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications))
- 🔐 Real authentication (Firebase Auth or Supabase Auth)

### v5 — Cloud + sharing
- ☁️ Cloud sync (Firebase / Supabase)
- 👨‍👩‍👧 Share pantry with family members
- 🎙️ Voice input ("Hey ShelfLife, add 2 lbs of chicken")
- 🌍 Multi-language support (English + Nepali)

### v6 — Smart features
- 🔗 Recipe import via URL
- 🤖 AI-powered recipe suggestions from pantry contents
- 📊 Long-term waste analytics with monthly reports
- 🎯 Goal-setting ("reduce waste by 10% this month")

---

## Contributing & Maintenance

### Updating this README

When you ship a new version:

1. **Add a new section** at the top of [Version History](#version-history) with the new version number
2. **Move the previous "(current)"** label down
3. List new features under **🆕 New features**, fixes under **🐛 Bug fixes**, and any architecture changes under **🏗️ Architecture changes**
4. **Update the Features section** at the top if a major capability shipped
5. **Update Assets Reference** if you added new image folders or files
6. **Update Project Structure** if you added new files/folders in `lib/`
7. Update the Roadmap if you delivered an item from it
8. Commit alongside the version bump:

   ```bash
   git add README.md
   git commit -m "vN complete and working"
   git tag vN
   ```

### Sample changelog entry template

```markdown
### vN.0 — Short Title (current)

**🆕 New features**
- 🎨 Description of new visible feature
- ⚙️ Description of new behavior

**🐛 Bug fixes**
- 🐛 What was broken and how it was fixed

**🏗️ Architecture changes**
- Description of any refactor that affects how code is organized
```

### When to remove "(current)"

Whenever you start the next version. The newest version always carries the "(current)" tag in the header.

---

## License

For educational and portfolio use. Sample data, recipes, and imagery are not for commercial use.

---

*ShelfLife — built with Flutter. README last updated: v3.0.*
