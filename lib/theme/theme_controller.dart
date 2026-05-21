import 'package:flutter/material.dart';

/// Global theme mode controller.
/// Toggle from anywhere (e.g. the Profile dark-mode switch) via:
///   themeController.value = ThemeMode.dark;
final ValueNotifier<ThemeMode> themeController =
    ValueNotifier<ThemeMode>(ThemeMode.light);
