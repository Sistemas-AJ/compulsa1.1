import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config/routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Inicializar sqflite_ffi solo para plataformas desktop (no web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const CompulsaApp());
}

class CompulsaApp extends StatelessWidget {
  const CompulsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compulsa - Asistente Tributario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme:
          AppTheme.lightTheme, // Usar tema claro también para el modo oscuro
      themeMode: ThemeMode.light, // Forzar siempre el tema claro
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
