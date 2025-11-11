import 'package:flutter/material.dart';

class AppColors {
  // Colores principales para un asistente tributario profesional
  static const Color primary = Color(0xFF1565C0); // Azul profesional
  static const Color primaryDark = Color(0xFF0D47A1); // Azul más oscuro
  static const Color primaryLight = Color(0xFF1976D2); // Azul más claro

  static const Color secondary = Color(
    0xFF2E7D32,
  ); // Verde para éxito/confirmación
  static const Color secondaryDark = Color(0xFF1B5E20);
  static const Color secondaryLight = Color(0xFF4CAF50);

  static const Color accent = Color(0xFFFF8F00); // Naranja para alertas
  static const Color accentLight = Color(0xFFFFB74D);

  // Colores funcionales - Más blancos y claros
  static const Color background = Colors.white; // Fondo completamente blanco
  static const Color surface = Colors.white; // Superficies blancas
  static const Color cardBackground = Color(
    0xFFFAFAFA,
  ); // Fondo muy sutil para tarjetas
  static const Color error = Color(0xFFE57373); // Error más suave
  static const Color warning = Color(0xFFFFB74D); // Warning más suave
  static const Color success = Color(0xFF81C784); // Success más suave
  static const Color info = Color(0xFF64B5F6); // Info más suave

  // Colores de texto - Ajustados para mejor contraste en fondo blanco
  static const Color textPrimary = Color(0xFF1A1A1A); // Negro más suave
  static const Color textSecondary = Color(0xFF666666); // Gris más suave
  static const Color textHint = Color(0xFF999999); // Hint más claro

  // Colores específicos para IGV y Renta
  static const Color igvColor = Color(0xFF3F51B5); // Azul índigo para IGV
  static const Color rentaColor = Color(0xFF9C27B0); // Púrpura para Renta
  static const Color saldoFavorColor = Color(
    0xFF4CAF50,
  ); // Verde para saldos a favor

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  // Colores para gráficos y reportes
  static const List<Color> chartColors = [
    Color(0xFF1976D2), // Azul
    Color(0xFF388E3C), // Verde
    Color(0xFFD32F2F), // Rojo
    Color(0xFFF57C00), // Naranja
    Color(0xFF7B1FA2), // Púrpura
    Color(0xFF455A64), // Gris azulado
  ];

  // Opacidades
  static const double lowOpacity = 0.1;
  static const double mediumOpacity = 0.3;
  static const double highOpacity = 0.6;
}
