import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF4E5B73);
  static const primary = Color(0xFF3D5AF1);
  static const primaryDark = Color(0xFF263AA8);
  static const teal = Color(0xFF0B9B8E);
  static const canvas = Color(0xFFF3F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E9F2);
  static const softBlue = Color(0xFFEEF1FF);
  static const softTeal = Color(0xFFE8F8F5);
  static const softAmber = Color(0xFFFFF4DD);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
      primary: AppPalette.primary,
      secondary: AppPalette.teal,
      surface: AppPalette.surface,
    );
    final base = ThemeData(colorScheme: colors, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.canvas,
      textTheme: base.textTheme
          .apply(bodyColor: AppPalette.ink, displayColor: AppPalette.ink)
          .copyWith(
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
            titleSmall: base.textTheme.titleSmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              color: AppPalette.ink,
              height: 1.35,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: AppPalette.muted,
              height: 1.35,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              color: AppPalette.muted,
              height: 1.3,
            ),
            labelLarge: base.textTheme.labelLarge?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppPalette.canvas,
        foregroundColor: AppPalette.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppPalette.ink,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: AppPalette.muted,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppPalette.primary,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(color: Color(0xFF69758B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD8E0EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: const BorderSide(color: AppPalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppPalette.softBlue,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppPalette.primary
                : AppPalette.muted,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppPalette.surface,
        side: const BorderSide(color: AppPalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          color: AppPalette.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppPalette.ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppPalette.ink,
        iconColor: AppPalette.muted,
        titleTextStyle: TextStyle(
          color: AppPalette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: AppPalette.muted,
          fontSize: 14,
          height: 1.3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: const Color(0x33172033),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        titleTextStyle: const TextStyle(
          color: AppPalette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.primary,
      ),
    );
  }
}
