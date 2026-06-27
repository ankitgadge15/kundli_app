import 'package:flutter/material.dart';
import 'screens/birth_details_screen.dart';

void main() {
  runApp(const KundliApp());
}

class KundliApp extends StatelessWidget {
  const KundliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kundli App',
      theme: _buildTheme(),
      home: const BirthDetailsScreen(),
    );
  }

  ThemeData _buildTheme() {
    const bgColor       = Color(0xFF0F0A1E);
    const surfaceColor  = Color(0xFF1A1030);
    const primaryColor  = Color(0xFF9C27B0);
    const onPrimary     = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.dark(
        primary:        primaryColor,
        onPrimary:      onPrimary,
        secondary:      const Color(0xFF7C4DFF),
        surface:        surfaceColor,
        onSurface:      Colors.white,
        surfaceContainerHighest: const Color(0xFF241840),
        outline:        Colors.purple.withOpacity(0.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF3D2060), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF241840),
        labelStyle: TextStyle(color: Colors.purple.shade200),
        hintStyle: const TextStyle(color: Colors.white30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
        ),
        prefixIconColor: Colors.purple.shade300,
        suffixIconColor: Colors.purple.shade300,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.purple.shade200,
          side: BorderSide(color: Colors.purple.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.purple.withOpacity(0.2),
        thickness: 1,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(primaryColor),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF241840),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.purple.withOpacity(0.3)),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        bodyLarge:  TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}