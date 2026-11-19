import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta azul marino, medida de la captura de referencia.
/// Los nombres 'violet' y 'lavender' se conservan para no tocar otros
/// archivos: 'violet' es el acento principal y 'lavender' el acento claro.
class AloColors {
  static const bg = Color(0xFF0D1933); // fondo de pantallas
  static const bgDeep = Color(0xFF0B172F); // barra superior e inferior
  static const violet = Color(0xFF3565A5); // acento principal (botones, NUEVO)
  static const lavender = Color(0xFFCAD9F6); // acento claro (iconos, textos)
  static const indicator = Color(0xFF24406F); // tarjetas, hero, indicador
  static const blue = Color(0xFF335C97);
  static const onDark = Colors.white;
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AloColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AloColors.violet,
      onPrimary: Colors.white,
      secondary: AloColors.lavender,
      onSecondary: AloColors.bgDeep,
      surface: AloColors.bgDeep,
    ),
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: AloColors.bgDeep,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AloColors.bgDeep,
      indicatorColor: AloColors.indicator,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AloColors.lavender),
  );
}