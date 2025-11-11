// 🧪 Test específico para verificar la detección automática de opciones MYPE

import 'lib/models/regimen_tributario.dart';

void main() {
  print('🎯 === TEST DE DETECCIÓN AUTOMÁTICA MYPE ===\n');

  // Simular diferentes escenarios
  final casos = [
    {
      'descripcion': 'MYPE con S/ 20,000,000 (debería mostrar opciones)',
      'ingresos': 20000000.0,
      'gastos': 0.0,
      'coeficiente': null,
      'deberiaActivarse': true,
    },
    {
      'descripcion': 'MYPE con S/ 1,500,000 (no debería mostrar opciones)',
      'ingresos': 1500000.0,
      'gastos': 0.0,
      'coeficiente': null,
      'deberiaActivarse': false,
    },
    {
      'descripcion': 'MYPE con S/ 2,000,000 y coeficiente 1.2%',
      'ingresos': 2000000.0,
      'gastos': 500000.0,
      'coeficiente': 0.012,
      'deberiaActivarse': true,
    },
  ];

  for (final caso in casos) {
    print('📋 ${caso['descripcion']}');

    final ingresos = caso['ingresos'] as double;
    final gastos = caso['gastos'] as double;
    final coeficiente = caso['coeficiente'] as double?;
    final deberiaActivarse = caso['deberiaActivarse'] as bool;

    // Verificar si supera el límite (esto es lo que hace la lógica de detección)
    final superaLimite = ingresos > RegimenTributario.limiteMyeBasico;

    print('  → Ingresos: S/ ${ingresos.toStringAsFixed(0)}');
    print(
      '  → Límite MYPE: S/ ${RegimenTributario.limiteMyeBasico.toStringAsFixed(0)}',
    );
    print('  → Supera límite: ${superaLimite ? 'SÍ' : 'NO'}');
    print('  → Debería activar opciones: ${deberiaActivarse ? 'SÍ' : 'NO'}');

    if (superaLimite) {
      // Calcular las opciones que se mostrarían
      final opciones = RegimenTributario.calcularTasaMyPE(
        ingresos: ingresos,
        gastosDeducibles: gastos,
        coeficientePersonalizado: coeficiente,
      );

      print('  → Tipo de opción: ${opciones['tipo']}');
      print(
        '  → Tasa aplicable: ${(opciones['tasa'] * 100).toStringAsFixed(2)}%',
      );
      print('  → Descripción: ${opciones['descripcion']}');

      // Verificar la tasa calculada con la función principal
      final tasaCalculada = calcularTasaRenta(
        RegimenTributarioEnum.mype,
        monto: ingresos,
        coeficiente: coeficiente,
      );

      print(
        '  → Tasa con calcularTasaRenta: ${(tasaCalculada * 100).toStringAsFixed(2)}%',
      );
    }

    print(
      '  ${superaLimite == deberiaActivarse ? '✅' : '❌'} Detección correcta\n',
    );
  }

  print('🎯 === RESUMEN ===');
  print('✅ La detección automática debe activarse cuando:');
  print('   • El régimen es MYPE');
  print('   • Los ingresos > S/ 1,605,000');
  print('✅ La lógica aplicará automáticamente:');
  print('   • Sin coeficiente: 1.5%');
  print('   • Con coeficiente < 1.5%: usar coeficiente');
  print('   • Con coeficiente >= 1.5%: usar 1.5% (limitado)');
}
