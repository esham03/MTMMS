import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// GLOBAL THEME CONTROLLER & NOTIFIER
// ============================================================
class ThemeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode =>
      themeModeNotifier.value == ThemeMode.dark;

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  static void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }
}

// ============================================================
// OFFICIAL GOA / MTMMS PALETTE � WEB-SYNCED
// Primary: Solar Orange #FF5100  |  Navy: #0F172A / #0A0F1D
// ============================================================
class AppColors {
  AppColors._();

  // Primary Brand � Solar Orange (matches web --primary: #FF5100)
  static const Color primary        = Color(0xFFFF5100);
  static const Color primaryDark    = Color(0xFFD63E00);
  static const Color primaryLight   = Color(0xFFFF7700);
  static const Color primarySurface = Color(0xFFFFF4EC);

  // Navy Palette (matches web sidebar / AppBar: #0F172A, #0A0F1D)
  static const Color primaryDeepNavy = Color(0xFF0F172A);
  static const Color deepNavy        = Color(0xFF0A0F1D);

  // Accent Colors (matches web CSS vars)
  static const Color accent        = Color(0xFFFF5100);
  static const Color accentLight   = Color(0xFFFFF1E6);
  static const Color accentDark    = Color(0xFFC2410C);
  static const Color accentAmber   = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentCyan    = Color(0xFF0284C7);

  // Operator Signature Colors (matches web --operator-*)
  static const Color operatorJio    = Color(0xFF0084FF);
  static const Color operatorAirtel = Color(0xFFEF4444);
  static const Color operatorVi     = Color(0xFFFF5100);
  static const Color operatorBsnl   = Color(0xFF10B981);

  // Light Theme Background Surfaces
  static const Color background      = Color(0xFFF8FAFC);
  static const Color bgWarm          = Color(0xFFFAEEE6);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color card            = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);

  // Typography (matches web --text-*)
  static const Color textPrimary   = Color(0xFF0A0F1D);
  static const Color textSecondary = Color(0xFF1E293B);
  static const Color textMuted     = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);

  // Status Colors
  static const Color success       = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFEBF8F1);
  static const Color successBorder  = Color(0xFFA7E0BE);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF9EC);
  static const Color warningBorder  = Color(0xFFF7DE9B);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorSurface   = Color(0xFFFDF2F2);
  static const Color errorBorder    = Color(0xFFF5B7B1);
  static const Color info           = Color(0xFF0284C7);
  static const Color infoSurface    = Color(0xFFE7F1FF);

  // Structural & Lines
  static const Color border      = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color divider     = Color(0xFFE2E8F0);

  // Dark Theme (matches web [data-theme="dark"])
  static const Color darkBg       = Color(0xFF0C1220);
  static const Color darkSurface  = Color(0xFF131B2E);
  static const Color darkCard     = Color(0xFF1A253C);
  static const Color darkElevated = Color(0xFF22304E);
  static const Color darkBorder   = Color(0x26FFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5100), Color(0xFFFF7700)],
  );

  // Navy AppBar/Sidebar gradient (matches web navbar & sidebar bg)
  static const LinearGradient navBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1D), Color(0xFF0F172A)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1D), Color(0xFF0F172A)],
  );

  // appBarGradient alias ? navy (updated from orange)
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1D), Color(0xFF0F172A)],
  );

  static const LinearGradient telecomGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5100), Color(0xFFFF7700)],
  );

  static const LinearGradient accentGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFD4A72C), Color(0xFFF3C96A)],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1D), Color(0xFF0F172A)],
  );

  // Backwards compat aliases
  static const Color cyanAccent   = Color(0xFF0284C7);
  static const Color skyAccent    = Color(0xFF0284C7);
  static const Color yellowAccent = Color(0xFFF59E0B);
  static const Color indigoAccent = Color(0xFFFF5100);

  // Dynamic helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBg : background;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  static Color surfaceBg(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color borderCol(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color textPri(BuildContext context) =>
      isDark(context) ? Colors.white : textPrimary;

  static Color textSec(BuildContext context) =>
      isDark(context) ? const Color(0xFFCBD5E1) : textSecondary;

  static Color textMut(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : textMuted;

  static Color primarySurf(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A0C00) : primarySurface;

  static Color dividerCol(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A253C) : divider;

  static Color inputBg(BuildContext context) =>
      isDark(context) ? darkElevated : const Color(0xFFF8FAFC);
}

// ============================================================
// OFFICIAL GOVERNMENT APP THEME (WEB-SYNCED)
// ============================================================
class AppTheme {
  AppTheme._();

  // -- LIGHT THEME ---------------------------------------------
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        tertiary: AppColors.accentAmber,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium:GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge:    GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium:   GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge:     GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium:    GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge:    GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall:    GoogleFonts.poppins(color: AppColors.textMuted,   fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // Deep Navy AppBar (matches web top navbar)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.4);
          return AppColors.border;
        }),
      ),
    );
  }

  // -- DARK THEME (matches web [data-theme="dark"]) -------------
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        tertiary: AppColors.accentAmber,
        surface: AppColors.darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium:GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge:    GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium:   GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge:     GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium:    GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge:    GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall:    GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        elevation: 16,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.1), thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkElevated,
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return const Color(0xFF94A3B8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.4);
          return AppColors.darkElevated;
        }),
      ),
    );
  }
}
