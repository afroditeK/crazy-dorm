// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Enables Material You look
    colorSchemeSeed: Colors.deepPurple, // Primary color seed
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: GoogleFonts.poppinsTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[200],
    ),
  );

  static final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.deepPurple,
  brightness: Brightness.dark,
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  // Other dark theme customizations here
);

}

// import 'package:flutter/material.dart';

// final ThemeData appTheme = ThemeData(
//   colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
//   useMaterial3: true,
//   scaffoldBackgroundColor: Colors.grey[50],
//   textTheme: const TextTheme(
//     bodyMedium: TextStyle(fontSize: 16),
//     titleLarge: TextStyle(fontWeight: FontWeight.bold),
//   ),
// );
