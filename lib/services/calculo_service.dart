import '../core/constants/api_config.dart';
import 'database_service.dart';
import '../models/historial_igv.dart';
import '../models/historial_renta.dart';
import '../models/regimen_tributario.dart';
import 'historial_igv_service.dart';
import 'historial_renta_service.dart';

class CalculoService {
  static const double _igvRate = 0.18; // 18%

  // Obtener el saldo anterior del último cálculo
  static Future<double> obtenerSaldoAnterior() async {
    return await HistorialIGVService.obtenerSaldoAnteriorPara(DateTime.now());
  }

  static Future<Map<String, dynamic>> calcularIgv({
    required double ventasGravadas,
    required double compras18,
    double compras10 = 0.0,
    double saldoAnterior = 0.0,
  }) async {
    // Simular llamada asíncrona
    await Future.delayed(AppConfig.simulatedDelay);

    // Calcular IGV según la estructura del Excel
    final double igvVentas = ventasGravadas * _igvRate; // IGV de ventas (18%)
    final double igvCompras18 = compras18 * _igvRate; // IGV de compras al 18%
    final double igvCompras10 = compras10 * 0.10; // IGV de compras al 10%
    final double totalIgvCompras = igvCompras18 + igvCompras10;

    // Cálculo del IGV (IGV Ventas - IGV Compras)
    final double calculoIgv = igvVentas - totalIgvCompras;

    // IGV por cancelar considerando saldo anterior
    final double igvPorCancelar = calculoIgv - saldoAnterior;

    // Determinar si hay saldo a favor o IGV por pagar
    final bool tieneSaldoAFavor = igvPorCancelar < 0;
    final double saldoAFavor = tieneSaldoAFavor ? igvPorCancelar.abs() : 0.0;
    final double igvPorPagar = tieneSaldoAFavor ? 0.0 : igvPorCancelar;

    return {
      'ventas_gravadas': ventasGravadas,
      'igv_ventas': igvVentas,
      'compras_18': compras18,
      'igv_compras_18': igvCompras18,
      'compras_10': compras10,
      'igv_compras_10': igvCompras10,
      'total_igv_compras': totalIgvCompras,
      'calculo_igv': calculoIgv,
      'saldo_anterior': saldoAnterior,
      'igv_por_cancelar': igvPorCancelar,
      'tiene_saldo_a_favor': tieneSaldoAFavor,
      'saldo_a_favor': saldoAFavor,
      'igv_por_pagar': igvPorPagar,
      'tasa_igv': _igvRate,
      'fecha_calculo': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> calcularIgvPorTipo({
    required double ventasGravadas,
    required double compras18,
    double compras10 = 0.0,
    double saldoAnterior = 0.0,
    required dynamic tipoNegocio, // Acepta el enum del screen
    bool guardarEnHistorial =
        true, // Nuevo parámetro para controlar si se guarda
  }) async {
    // Simular llamada asíncrona
    await Future.delayed(AppConfig.simulatedDelay);

    // Determinar la tasa de IGV según el tipo de negocio
    final bool esRestauranteHotel = tipoNegocio.toString().contains(
      'restauranteHotel',
    );
    final double tasaVentas = esRestauranteHotel ? 0.10 : _igvRate;

    // Calcular IGV según el tipo de negocio
    final double igvVentas = ventasGravadas * tasaVentas;
    final double igvCompras18 = compras18 * _igvRate;
    final double igvCompras10 = compras10 * 0.10;
    final double totalIgvCompras = igvCompras18 + igvCompras10;

    // Cálculo del IGV (IGV Ventas - IGV Compras)
    final double calculoIgv = igvVentas - totalIgvCompras;

    // IGV por cancelar considerando saldo anterior
    final double igvPorCancelar = calculoIgv - saldoAnterior;

    // Determinar si hay saldo a favor o IGV por pagar
    final bool tieneSaldoAFavor = igvPorCancelar < 0;
    final double saldoAFavor = tieneSaldoAFavor ? igvPorCancelar.abs() : 0.0;
    final double igvPorPagar = tieneSaldoAFavor ? 0.0 : igvPorCancelar;

    final Map<String, dynamic> resultado = {
      'ventas_gravadas': ventasGravadas,
      'igv_ventas': igvVentas,
      'compras_18': compras18,
      'igv_compras_18': igvCompras18,
      'compras_10': compras10,
      'igv_compras_10': igvCompras10,
      'total_igv_compras': totalIgvCompras,
      'calculo_igv': calculoIgv,
      'saldo_anterior': saldoAnterior,
      'igv_por_cancelar': igvPorCancelar,
      'tiene_saldo_a_favor': tieneSaldoAFavor,
      'saldo_a_favor': saldoAFavor,
      'igv_por_pagar': igvPorPagar,
      'tasa_igv_ventas': tasaVentas,
      'tipo_negocio': esRestauranteHotel ? 'Restaurante/Hotel' : 'General',
      'fecha_calculo': DateTime.now().toIso8601String(),
    };

    // Guardar en historial si está habilitado
    if (guardarEnHistorial) {
      try {
        final tipoNegocioStr = esRestauranteHotel
            ? 'restaurante_hotel'
            : 'general';
        final historial = HistorialIGV.fromCalculoResult(
          calculoResult: resultado,
          tipoNegocio: tipoNegocioStr,
          observaciones:
              'Cálculo automático desde ${resultado['tipo_negocio']}',
        );
        await HistorialIGVService.guardarCalculo(historial);
      } catch (e) {
        // En caso de error al guardar, no afectar el cálculo
        print('Error al guardar en historial: $e');
      }
    }

    return resultado;
  }

  static Future<Map<String, dynamic>> calcularRenta({
    required double ingresos,
    required double gastos,
    required int regimenId,
    double? coeficientePersonalizado,
    bool usarCoeficiente = false,
  }) async {
    // Simular llamada asíncrona
    await Future.delayed(AppConfig.simulatedDelay);

    // Obtener información del régimen
    final regimen = await DatabaseService().obtenerRegimenPorId(regimenId);
    if (regimen == null) {
      throw Exception('Régimen tributario no encontrado');
    }

    // 🎯 Determinar el régimen enum basado en el nombre
    RegimenTributarioEnum regimenEnum;
    final nombreRegimen = regimen.nombre.toUpperCase();

    if (nombreRegimen.contains('NRUS') || nombreRegimen.contains('RUS')) {
      regimenEnum = RegimenTributarioEnum.rus;
    } else if (nombreRegimen.contains('RER') ||
        nombreRegimen.contains('ESPECIAL')) {
      regimenEnum = RegimenTributarioEnum.especial;
    } else if (nombreRegimen.contains('MYPE')) {
      regimenEnum = RegimenTributarioEnum.mype;
    } else {
      regimenEnum = RegimenTributarioEnum.general;
    }

    // 📊 Usar la nueva función optimizada de cálculo de tasa
    double tasaCalculada;
    try {
      tasaCalculada = calcularTasaRenta(
        regimenEnum,
        monto: ingresos,
        coeficiente: usarCoeficiente ? coeficientePersonalizado : null,
      );
    } catch (e) {
      throw Exception('Error en cálculo de tasa: $e');
    }

    // 🧮 Calcular valores base
    final double rentaNeta = ingresos - gastos;
    final double tasaPorcentaje = tasaCalculada * 100;

    double baseImponible;
    double impuestoRenta;
    String tipoCalculo;

    // 📈 Determinar base imponible según el régimen
    switch (regimenEnum) {
      case RegimenTributarioEnum.rus:
        // RUS no paga impuesto a la renta
        baseImponible = ingresos;
        impuestoRenta = 0.0;
        tipoCalculo = 'RUS - Sin impuesto a la renta';
        break;

      case RegimenTributarioEnum.especial:
        // RER: 1.0% sobre ingresos brutos
        if (nombreRegimen.contains('RER')) {
          baseImponible = ingresos;
          impuestoRenta = ingresos * tasaCalculada;
          tipoCalculo =
              'RER - ${tasaPorcentaje.toStringAsFixed(1)}% sobre ingresos brutos';
        } else {
          // Régimen Especial: 1.5% sobre renta neta
          baseImponible = rentaNeta > 0 ? rentaNeta : 0.0;
          impuestoRenta = rentaNeta > 0 ? rentaNeta * tasaCalculada : 0.0;
          tipoCalculo =
              'Especial - ${tasaPorcentaje.toStringAsFixed(1)}% sobre renta neta';
        }
        break;

      case RegimenTributarioEnum.mype:
        // MYPE: Lógica especial según el monto de ingresos
        if (ingresos <= RegimenTributario.limiteMyeBasico) {
          // Tasa básica del 1% sobre ingresos
          baseImponible = ingresos;
          impuestoRenta = ingresos * tasaCalculada;
          tipoCalculo =
              'MYPE - ${tasaPorcentaje.toStringAsFixed(1)}% sobre ingresos (≤ S/ ${RegimenTributario.limiteMyeBasico.toStringAsFixed(0)})';
        } else {
          // Tasa variable sobre renta neta
          baseImponible = rentaNeta > 0 ? rentaNeta : 0.0;
          impuestoRenta = rentaNeta > 0 ? rentaNeta * tasaCalculada : 0.0;
          if (coeficientePersonalizado != null && usarCoeficiente) {
            tipoCalculo =
                'MYPE - Coeficiente ${tasaPorcentaje.toStringAsFixed(2)}% sobre renta neta';
          } else {
            tipoCalculo =
                'MYPE - ${tasaPorcentaje.toStringAsFixed(1)}% sobre renta neta';
          }
        }
        break;

      case RegimenTributarioEnum.general:
        // Régimen General: 1.5% sobre renta neta
        baseImponible = rentaNeta > 0 ? rentaNeta : 0.0;
        impuestoRenta = rentaNeta > 0 ? rentaNeta * tasaCalculada : 0.0;
        tipoCalculo =
            'General - ${tasaPorcentaje.toStringAsFixed(1)}% sobre renta neta';
        break;
    }

    final double rentaPorPagar = impuestoRenta > 0 ? impuestoRenta : 0.0;
    final double perdida = rentaNeta < 0 ? rentaNeta.abs() : 0.0;

    // 📋 Obtener detalles adicionales del cálculo
    Map<String, dynamic>? detalleCalculo;
    try {
      detalleCalculo = regimenEnum.obtenerDetalleCalculo(
        monto: ingresos,
        coeficiente: usarCoeficiente ? coeficientePersonalizado : null,
      );
    } catch (e) {
      // En caso de error, continuar sin detalles adicionales
      detalleCalculo = null;
    }

    final resultado = {
      'ingresos': ingresos,
      'gastos': gastos,
      'renta_neta': rentaNeta,
      'base_imponible': baseImponible,
      'impuesto_renta': impuestoRenta,
      'renta_por_pagar': rentaPorPagar,
      'perdida': perdida,
      'tasa_renta': tasaPorcentaje,
      'tasa_decimal': tasaCalculada,
      'regimen_nombre': regimen.nombre,
      'regimen_enum': regimenEnum.nombre,
      'tipo_calculo': tipoCalculo,
      'fecha_calculo': DateTime.now().toIso8601String(),
      'tiene_perdida': rentaNeta < 0,
      'debe_pagar': rentaPorPagar > 0,
      // Información adicional optimizada
      'detalle_calculo': detalleCalculo,
      'coeficiente_personalizado': coeficientePersonalizado,
      'usando_coeficiente': usarCoeficiente,
      'metodo_calculo': 'funcion_optimizada_v2',
    };

    // 💾 Guardar en historial (similar al IGV)
    try {
      final historial = HistorialRenta.fromCalculoResult(
        calculoResult: resultado,
        observaciones: 'Cálculo automático desde ${regimenEnum.nombre}',
      );
      await HistorialRentaService.guardarCalculo(historial);
    } catch (e) {
      // En caso de error al guardar, no afectar el cálculo
      print('Error al guardar en historial de renta: $e');
    }

    return resultado;
  }

  static Future<Map<String, dynamic>> calcularLiquidacion({
    required double ingresos,
    required double gastos,
    required double ventasGravadas,
    required double compras18,
    double compras10 = 0.0,
    double saldoAnterior = 0.0,
    required int regimenId,
  }) async {
    // Calcular IGV e Impuesto a la Renta
    final igv = await calcularIgv(
      ventasGravadas: ventasGravadas,
      compras18: compras18,
      compras10: compras10,
      saldoAnterior: saldoAnterior,
    );

    final renta = await calcularRenta(
      ingresos: ingresos,
      gastos: gastos,
      regimenId: regimenId,
    );

    return {
      'igv': igv,
      'renta': renta,
      'total_por_pagar':
          (igv['igv_por_pagar'] as double) +
          (renta['renta_por_pagar'] as double),
      'fecha_calculo': DateTime.now().toIso8601String(),
    };
  }
}
