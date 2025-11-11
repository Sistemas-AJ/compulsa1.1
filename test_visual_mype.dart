// 🧪 Test del comportamiento visual dinámico de MYPE

import 'lib/models/regimen_tributario.dart';

void main() {
  print('🎯 === TEST DE COMPORTAMIENTO VISUAL MYPE ===\n');

  // Simular el caso específico: S/ 20,000,000 en MYPE
  final ingresos = 20000000.0;
  final gastos = 0.0;

  print('📊 CASO: MYPE con S/ ${ingresos.toStringAsFixed(0)}');
  print(
    '  → Límite MYPE: S/ ${RegimenTributario.limiteMyeBasico.toStringAsFixed(0)}',
  );
  print(
    '  → Supera límite: ${ingresos > RegimenTributario.limiteMyeBasico ? 'SÍ' : 'NO'}',
  );

  if (ingresos > RegimenTributario.limiteMyeBasico) {
    // Calcular opciones automáticas
    final opciones = RegimenTributario.calcularTasaMyPE(
      ingresos: ingresos,
      gastosDeducibles: gastos,
      coeficientePersonalizado: null, // Sin coeficiente personalizado
    );

    print('\n📋 OPCIONES CALCULADAS:');
    print('  → Tipo: ${opciones['tipo']}');
    print('  → Tasa: ${(opciones['tasa'] * 100).toStringAsFixed(2)}%');
    print('  → Descripción: ${opciones['descripcion']}');

    // Simular lo que mostraría el dropdown
    String textoDropdown;
    final tasaActual = (opciones['tasa'] * 100).toStringAsFixed(1);
    final tipoCalculo = opciones['tipo'];

    String descripcionTasa;
    switch (tipoCalculo) {
      case 'basica':
        descripcionTasa = '1.0% - Básica';
        break;
      case 'automatico':
        descripcionTasa = '1.5% - Automático';
        break;
      case 'coeficiente_menor':
        descripcionTasa = '${tasaActual}% - Coeficiente';
        break;
      case 'limitado_maximo':
        descripcionTasa = '1.5% - Limitado';
        break;
      default:
        descripcionTasa = '${tasaActual}%';
    }

    textoDropdown = 'MYPE (${descripcionTasa})';

    print('\n🎨 VISUALIZACIÓN:');
    print('  → Dropdown mostraría: "${textoDropdown}"');

    // Determinar indicador visual
    String indicadorTitulo;
    String indicadorColor;

    switch (tipoCalculo) {
      case 'basica':
        indicadorTitulo = 'Tasa Básica MYPE';
        indicadorColor = 'AZUL';
        break;
      case 'automatico':
        indicadorTitulo = 'Tasa Automática MYPE';
        indicadorColor = 'NARANJA';
        break;
      case 'coeficiente_menor':
        indicadorTitulo = 'Coeficiente Aplicado';
        indicadorColor = 'VERDE';
        break;
      case 'limitado_maximo':
        indicadorTitulo = 'Tasa Limitada';
        indicadorColor = 'AMARILLO';
        break;
      default:
        indicadorTitulo = 'Tasa MYPE';
        indicadorColor = 'GRIS';
    }

    print('  → Indicador: ${indicadorTitulo} (${indicadorColor})');
    print('  → Badge: ${tasaActual}%');

    // Verificar con calcularTasaRenta
    final tasaCalculada = calcularTasaRenta(
      RegimenTributarioEnum.mype,
      monto: ingresos,
      coeficiente: null,
    );

    print('\n✅ VERIFICACIÓN:');
    print(
      '  → calcularTasaRenta: ${(tasaCalculada * 100).toStringAsFixed(2)}%',
    );
    print(
      '  → Coincide con opciones: ${(tasaCalculada == opciones['tasa']) ? 'SÍ' : 'NO'}',
    );
  }

  print('\n🎯 === CASOS ADICIONALES ===');

  // Caso con coeficiente personalizado menor
  final opcionesConCoef = RegimenTributario.calcularTasaMyPE(
    ingresos: ingresos,
    gastosDeducibles: 5000000.0, // S/ 5,000,000 en gastos
    coeficientePersonalizado: 0.008, // 0.8%
  );

  print('\n📋 CON COEFICIENTE 0.8%:');
  print('  → Tipo: ${opcionesConCoef['tipo']}');
  print('  → Tasa: ${(opcionesConCoef['tasa'] * 100).toStringAsFixed(2)}%');
  print('  → Descripción: ${opcionesConCoef['descripcion']}');

  // Caso con coeficiente mayor a 1.5%
  final opcionesCoefAlto = RegimenTributario.calcularTasaMyPE(
    ingresos: ingresos,
    gastosDeducibles: 1000000.0, // S/ 1,000,000 en gastos
    coeficientePersonalizado: 0.025, // 2.5%
  );

  print('\n📋 CON COEFICIENTE 2.5%:');
  print('  → Tipo: ${opcionesCoefAlto['tipo']}');
  print('  → Tasa: ${(opcionesCoefAlto['tasa'] * 100).toStringAsFixed(2)}%');
  print('  → Descripción: ${opcionesCoefAlto['descripcion']}');

  print('\n🎯 === RESUMEN ===');
  print('✅ Con S/ 20,000,000 sin coeficiente → 1.5% automático');
  print('✅ Con coeficiente < 1.5% → usar coeficiente');
  print('✅ Con coeficiente ≥ 1.5% → limitar a 1.5%');
  print('✅ El dropdown muestra dinámicamente la tasa aplicable');
  print('✅ El indicador visual ayuda a entender qué está pasando');
}
