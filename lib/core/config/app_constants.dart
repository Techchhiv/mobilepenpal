/// Centralized design and layout constants for the application.
class AppConstants {
  AppConstants._();

  // ─── Global layout ───────────────────────────────────────────
  /// Maximum content width used across screens (e.g. home, stage).
  static const double globalMaxWidth = 600.0;

  // ─── Responsive breakpoints (int – required by responsive_framework) ──
  static const int mobileBreakpoint = 450;
  static const int tabletBreakpoint = 950;

  // ─── AutoScale design widths ─────────────────────────────────
  /// The virtual width the UI was designed for on phones.
  static const double mobileDesignWidth = 390.0;

  /// The virtual width used when auto-scaling for tablets.
  static const double tabletDesignWidth = 550.0;

  /// The virtual width used when auto-scaling for desktops.
  static const double desktopDesignWidth = 800.0;

  // ─── AutoScale design heights for Landscape ──────────────────
  /// The virtual height used when auto-scaling for mobile landscape.
  static const double mobileDesignHeight = 390.0;

  /// The virtual height used when auto-scaling for tablet landscape.
  static const double tabletDesignHeight = 800.0;
}
