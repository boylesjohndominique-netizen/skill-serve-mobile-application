import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_animations.dart';

/// Builds Material 3 [ThemeData] for light and dark modes, wiring every
/// component theme (buttons, inputs, cards, nav bar, etc.) to the shared
/// design tokens so new screens inherit consistent styling automatically.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(
        brightness: Brightness.light,
        scaffoldBg: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        line: AppColors.line,
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        scaffoldBg: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textOnDark,
        line: AppColors.lineDark,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color onSurface,
    required Color line,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.secondary,
      onPrimary: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primary,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: AppTextStyles.bodyLarge.fontFamily,

      // ── Smooth page transitions across all platforms ──
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _SlideFadeTransitionBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: (isDark
                ? AppTextStyles.onDark(AppTextStyles.headlineMedium)
                : AppTextStyles.headlineMedium)
            .copyWith(color: onSurface),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: isDark ? Colors.black54 : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: line.withValues(alpha: 0.6), width: 0.8),
        ),
      ),

      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.neutral200,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 0,
          animationDuration: AppAnimations.fast,
        ),
      ),

      // ── Filled buttons (e.g. inline "Book now" actions) ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.neutral200,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.secondary,
        selectionColor: AppColors.secondary.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.secondary,
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: line, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          animationDuration: AppAnimations.fast,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: AppTextStyles.button,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: AppColors.secondarySoft,
        circularTrackColor: AppColors.secondarySoft,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.neutral300,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),

      // ── Tab bar theme — rounded pill indicator ──
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.secondary,
        labelColor: isDark ? Colors.white : AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.label,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
            AppColors.secondary.withValues(alpha: 0.08)),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: const Border(
            bottom: BorderSide(color: AppColors.secondary, width: 2.5),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        selectedColor: AppColors.secondary,
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.label,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          side: BorderSide.none,
        ),
      ),

      // ── Switch theme ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.neutral300 : AppColors.neutral200;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.secondary;
          return isDark ? AppColors.surfaceAltDark : AppColors.neutral100;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return isDark ? AppColors.lineDark : AppColors.neutral200;
        }),
      ),

      // ── Radio / checkbox — brass when active ──
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary
              : AppColors.neutral300,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.primary),
        side: const BorderSide(color: AppColors.neutral300, width: 1.6),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.onDark(AppTextStyles.bodyMedium),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
    );
  }
}

/// Smooth slide + fade page transition used app-wide.
class _SlideFadeTransitionBuilder extends PageTransitionsBuilder {
  const _SlideFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.defaultCurve,
    );
    final slideIn = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(fadeIn);

    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppAnimations.defaultCurve,
    );
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.03, 0),
    ).animate(fadeOut);

    return SlideTransition(
      position: slideOut,
      child: SlideTransition(
        position: slideIn,
        child: FadeTransition(
          opacity: fadeIn,
          child: child,
        ),
      ),
    );
  }
}
