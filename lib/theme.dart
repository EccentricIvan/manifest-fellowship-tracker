import 'package:flutter/material.dart';

const Color kGoldenOrange = Color(0xFFF5A623);
const Color kBrandBlack = Color(0xFF000000);
const Color kBrandWhite = Color(0xFFFFFFFF);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kGoldenOrange,
    brightness: Brightness.light,
  ).copyWith(
    primary: kGoldenOrange,
    onPrimary: kBrandBlack,
    secondary: kBrandBlack,
    onSecondary: kBrandWhite,
    surface: kBrandWhite,
    onSurface: kBrandBlack,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: kBrandWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBrandBlack,
      foregroundColor: kBrandWhite,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kGoldenOrange,
      foregroundColor: kBrandBlack,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kGoldenOrange,
        foregroundColor: kBrandBlack,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kGoldenOrange, width: 2),
      ),
    ),
  );
}
