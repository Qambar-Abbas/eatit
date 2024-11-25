import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.white,
    onSecondary: Colors.black,
    error: Colors.red,
    onError: Colors.redAccent,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
    ),
  ),
);
