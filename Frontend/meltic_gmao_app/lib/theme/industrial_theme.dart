import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndustrialTheme {
  // Paleta Industrial 4.0 (Dark Navy & Cyan)
  static const Color spaceCadet = Color(0xFF0A192F); // Fondo profundo
  static const Color claudCloud = Color(0xFF112240); // Superficies / Cards
  static const Color electricBlue = Color(
    0xFF00E5FF,
  ); // Acento primario (Meltic Cyan)
  static const Color neonCyan = Color(0xFF00E5FF); // Acento secundario (datos)
  static const Color slateGray = Color(0xFF8892B0); // Texto secundario

  // Colores de estado SCADA
  static const Color operativeGreen = Color(0xFF00C853);
  static const Color warningOrange = Color(0xFFFFA500);
  static const Color criticalRed = Color(0xFFD32F2F);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: electricBlue,
    scaffoldBackgroundColor: spaceCadet,
    cardColor: claudCloud,

    // Tipografía limpia e industrial
    textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: GoogleFonts.montserrat(color: slateGray),
        ),

    // Barras de navegación
    appBarTheme: const AppBarTheme(
      backgroundColor: spaceCadet,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: neonCyan),
    ),

    // Botones con estilo neón sutil
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricBlue,
        foregroundColor: spaceCadet,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    ),

    // Diseño de inputs industriales
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: claudCloud,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: slateGray.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      labelStyle: const TextStyle(color: slateGray),
      prefixIconColor: neonCyan,
    ),

    // Cards con bordes suaves
    cardTheme: CardThemeData(
      color: claudCloud,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 16),
    ),
  );
}
