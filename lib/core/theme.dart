import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores aproximados tomados de las capturas del sitio.
/// TODO: reemplazar por los valores exactos del CSS de alobienplataforma.com.
class AloColors {
  static const bg = Color(0xFF1E1646);
  static const bgDeep = Color(0xFF160F36);
  static const violet = Color(0xFF7C4DDB);
  static const lavender = Color(0xFF8B6FD6);
  static const blue = Color(0xFF0077B6);
  static const onDark = Colors.white;
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AloColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AloColors.violet,
      secondary: AloColors.lavender,
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
      indicatorColor: AloColors.violet.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AloColors.lavender),
  );
}