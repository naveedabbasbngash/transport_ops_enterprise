import 'package:flutter/material.dart';

class Material3Theme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blueGrey,

      scaffoldBackgroundColor: const Color(0xFFF8F9FB),

      // ✅ CORRECT: CardThemeData (not CardTheme widget)
      cardTheme: CardThemeData(
        surfaceTintColor: Colors.white, // removes M3 tint
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}