// Test para la aplicación Compulsa - Asistente Tributario
//
// Este test verifica que la aplicación se inicie correctamente y muestre
// la pantalla principal con los elementos esperados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:compulsa/main.dart';

void main() {
  testWidgets('Compulsa app smoke test', (WidgetTester tester) async {
    // Construir nuestra aplicación y generar un frame
    await tester.pumpWidget(const CompulsaApp());

    // Verificar que se muestre el título de la aplicación
    expect(find.text('Compulsa - Asistente Tributario'), findsOneWidget);

    // Verificar que se muestre el mensaje de bienvenida
    expect(find.text('¡Bienvenido!'), findsOneWidget);

    // Verificar que se muestre el subtítulo
    expect(
      find.text('Tu asistente tributario inteligente para Perú'),
      findsOneWidget,
    );

    // Verificar que existan las secciones principales
    expect(find.text('Acceso Rápido'), findsOneWidget);
    expect(find.text('Funciones Principales'), findsOneWidget);
    expect(find.text('Actividad Reciente'), findsOneWidget);

    // Verificar que existan los botones principales
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Calcular'), findsOneWidget);
    expect(find.text('Declaraciones'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
  });

  testWidgets('Navigation test', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const CompulsaApp());

    // Buscar y tocar el botón de Empresas
    await tester.tap(find.text('Empresas'));
    await tester.pumpAndSettle();

    // Verificar que navegó a la pantalla de empresas
    expect(find.text('Empresas'), findsOneWidget);

    // Regresar a la pantalla principal
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verificar que regresó al dashboard
    expect(find.text('¡Bienvenido!'), findsOneWidget);
  });

  testWidgets('Floating action button test', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const CompulsaApp());

    // Verificar que existe el FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Calcular'), findsOneWidget);

    // Tocar el FloatingActionButton
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verificar que navegó a la pantalla de cálculos
    expect(find.text('Cálculos Tributarios'), findsOneWidget);
  });
}
