import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/calculos/calculos_screen.dart';
import '../screens/calculos/igv_screen.dart';
import '../screens/calculos/renta_screen.dart';
import '../screens/declaraciones/declaraciones_screen.dart';
import '../screens/declaraciones/declaracion_form_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/empresa/perfil_usuario_screen.dart';
import '../screens/actividad/actividad_reciente_screen.dart';

class AppRoutes {
  // Rutas principales
  static const String home = '/';
  static const String calculos = '/calculos';
  static const String igv = '/igv';
  static const String renta = '/renta';
  static const String declaraciones = '/declaraciones';
  static const String declaracionForm = '/declaracion-form';
  static const String reportes = '/reportes';

  static const String perfilUsuario = '/perfil-usuario';
  static const String actividadReciente = '/actividad-reciente';

  // Mapa de rutas
  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const HomeScreen(),
      calculos: (context) => const CalculosScreen(),
      igv: (context) => const IgvScreen(),
      renta: (context) => const RentaScreen(),
      declaraciones: (context) => const DeclaracionesScreen(),
      declaracionForm: (context) => const DeclaracionFormScreen(),
      reportes: (context) => const ReportesScreen(),
      perfilUsuario: (context) => const PerfilUsuarioScreen(),
      actividadReciente: (context) => const ActividadRecienteScreen(),
    };
  }

  // Navegación programática
  static Future<void> navigateTo(BuildContext context, String routeName) {
    return Navigator.pushNamed(context, routeName);
  }

  static Future<void> navigateAndReplace(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.pushReplacementNamed(context, routeName);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
