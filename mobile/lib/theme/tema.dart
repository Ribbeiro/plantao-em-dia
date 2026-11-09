import 'package:flutter/material.dart';

/// Identidade visual: azul hospitalar + turquesa (cores comuns em ambientes de saúde),
/// fundo cinza-azulado bem claro e cartões brancos, como em sistemas clínicos.
class CoresMarca {
  static const azul = Color(0xFF0B5CAD);
  static const azulEscuro = Color(0xFF073B73);
  static const turquesa = Color(0xFF0FA3A3);
  static const fundoClaro = Color(0xFFF1F5F9);
  static const bordaClara = Color(0xFFDCE4EC);

  /// Gradiente usado no cabeçalho do login e na barra superior.
  static const gradiente = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulEscuro, azul, Color(0xFF0E7FA8)],
  );
}

ThemeData temaPlantao(Brightness brilho) {
  final claro = brilho == Brightness.light;
  final base = ColorScheme.fromSeed(
    seedColor: CoresMarca.azul,
    brightness: brilho,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  final cores = claro
      ? base.copyWith(
          primary: CoresMarca.azul,
          onPrimary: Colors.white,
          secondary: CoresMarca.turquesa,
          onSecondary: Colors.white,
          primaryContainer: const Color(0xFFE1EDFA),
          onPrimaryContainer: CoresMarca.azulEscuro,
          secondaryContainer: const Color(0xFFD6F2F1),
          onSecondaryContainer: const Color(0xFF00504F),
          surface: Colors.white,
          outlineVariant: CoresMarca.bordaClara,
        )
      : base.copyWith(secondary: const Color(0xFF4FD1CB));

  return ThemeData(
    useMaterial3: true,
    colorScheme: cores,
    scaffoldBackgroundColor: claro ? CoresMarca.fundoClaro : cores.surface,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: claro ? CoresMarca.azul : cores.surfaceContainer,
      foregroundColor: claro ? Colors.white : cores.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: claro ? Colors.white : cores.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: claro ? Colors.white : cores.surfaceContainer,
      indicatorColor: claro ? cores.secondaryContainer : cores.secondary.withValues(alpha: 0.25),
      elevation: 3,
      shadowColor: Colors.black26,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? (claro ? CoresMarca.azul : cores.onSurface) : null,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? (claro ? CoresMarca.azul : cores.onSurface) : null),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cores.secondary,
      foregroundColor: claro ? Colors.white : Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: claro ? const Color(0xFFF7FAFC) : cores.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cores.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: claro ? Colors.white : cores.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cores.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      selectedColor: claro ? cores.primaryContainer : null,
      side: BorderSide(color: cores.outlineVariant),
    ),
  );
}
