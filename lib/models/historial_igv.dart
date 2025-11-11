class HistorialIGV {
  final String id;
  final DateTime fechaCalculo;
  final String tipoNegocio; // 'general' o 'restaurante_hotel'

  // Datos de entrada
  final double ventasGravadas;
  final double compras18;
  final double compras10;
  final double saldoAnterior;

  // IGV calculado
  final double igvVentas;
  final double igvCompras18;
  final double igvCompras10;
  final double totalIgvCompras;

  // Resultado del cálculo
  final double calculoIgv;
  final double igvPorCancelar;
  final bool tieneSaldoAFavor;
  final double saldoAFavor;
  final double igvPorPagar;
  final double
  saldoResultante; // Este será el saldo anterior para el siguiente cálculo

  // Metadatos
  final double tasaIgvVentas;
  final String? observaciones;

  HistorialIGV({
    required this.id,
    required this.fechaCalculo,
    required this.tipoNegocio,
    required this.ventasGravadas,
    required this.compras18,
    required this.compras10,
    required this.saldoAnterior,
    required this.igvVentas,
    required this.igvCompras18,
    required this.igvCompras10,
    required this.totalIgvCompras,
    required this.calculoIgv,
    required this.igvPorCancelar,
    required this.tieneSaldoAFavor,
    required this.saldoAFavor,
    required this.igvPorPagar,
    required this.saldoResultante,
    required this.tasaIgvVentas,
    this.observaciones,
  });

  // Factory constructor para crear desde un cálculo
  factory HistorialIGV.fromCalculoResult({
    required Map<String, dynamic> calculoResult,
    required String tipoNegocio,
    String? observaciones,
  }) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime fechaCalculo = DateTime.parse(
      calculoResult['fecha_calculo'],
    );

    // El saldo resultante es saldo a favor si tiene, caso contrario es 0
    final double saldoResultante = calculoResult['tiene_saldo_a_favor']
        ? calculoResult['saldo_a_favor']
        : 0.0;

    return HistorialIGV(
      id: id,
      fechaCalculo: fechaCalculo,
      tipoNegocio: tipoNegocio,
      ventasGravadas: calculoResult['ventas_gravadas'],
      compras18: calculoResult['compras_18'],
      compras10: calculoResult['compras_10'],
      saldoAnterior: calculoResult['saldo_anterior'],
      igvVentas: calculoResult['igv_ventas'],
      igvCompras18: calculoResult['igv_compras_18'],
      igvCompras10: calculoResult['igv_compras_10'],
      totalIgvCompras: calculoResult['total_igv_compras'],
      calculoIgv: calculoResult['calculo_igv'],
      igvPorCancelar: calculoResult['igv_por_cancelar'],
      tieneSaldoAFavor: calculoResult['tiene_saldo_a_favor'],
      saldoAFavor: calculoResult['saldo_a_favor'],
      igvPorPagar: calculoResult['igv_por_pagar'],
      saldoResultante: saldoResultante,
      tasaIgvVentas: calculoResult['tasa_igv_ventas'] ?? 0.18,
      observaciones: observaciones,
    );
  }

  // Factory constructor para crear desde Map (para base de datos)
  factory HistorialIGV.fromMap(Map<String, dynamic> map) {
    return HistorialIGV(
      id: map['id'],
      fechaCalculo: DateTime.parse(map['fechaCalculo']),
      tipoNegocio: map['tipoNegocio'],
      ventasGravadas: map['ventasGravadas'].toDouble(),
      compras18: map['compras18'].toDouble(),
      compras10: map['compras10'].toDouble(),
      saldoAnterior: map['saldoAnterior'].toDouble(),
      igvVentas: map['igvVentas'].toDouble(),
      igvCompras18: map['igvCompras18'].toDouble(),
      igvCompras10: map['igvCompras10'].toDouble(),
      totalIgvCompras: map['totalIgvCompras'].toDouble(),
      calculoIgv: map['calculoIgv'].toDouble(),
      igvPorCancelar: map['igvPorCancelar'].toDouble(),
      tieneSaldoAFavor: map['tieneSaldoAFavor'] == 1,
      saldoAFavor: map['saldoAFavor'].toDouble(),
      igvPorPagar: map['igvPorPagar'].toDouble(),
      saldoResultante: map['saldoResultante'].toDouble(),
      tasaIgvVentas: map['tasaIgvVentas'].toDouble(),
      observaciones: map['observaciones'],
    );
  }

  // Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaCalculo': fechaCalculo.toIso8601String(),
      'tipoNegocio': tipoNegocio,
      'ventasGravadas': ventasGravadas,
      'compras18': compras18,
      'compras10': compras10,
      'saldoAnterior': saldoAnterior,
      'igvVentas': igvVentas,
      'igvCompras18': igvCompras18,
      'igvCompras10': igvCompras10,
      'totalIgvCompras': totalIgvCompras,
      'calculoIgv': calculoIgv,
      'igvPorCancelar': igvPorCancelar,
      'tieneSaldoAFavor': tieneSaldoAFavor ? 1 : 0,
      'saldoAFavor': saldoAFavor,
      'igvPorPagar': igvPorPagar,
      'saldoResultante': saldoResultante,
      'tasaIgvVentas': tasaIgvVentas,
      'observaciones': observaciones,
    };
  }

  // Getters útiles
  String get fechaFormateada {
    final meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fechaCalculo.day} ${meses[fechaCalculo.month]} ${fechaCalculo.year}';
  }

  String get tipoNegocioFormatted {
    switch (tipoNegocio) {
      case 'general':
        return 'Negocio General (18%)';
      case 'restaurante_hotel':
        return 'Restaurante/Hotel (10%)';
      default:
        return 'Desconocido';
    }
  }

  String get resumenCalculo {
    if (tieneSaldoAFavor) {
      return 'Saldo a favor: S/ ${saldoAFavor.toStringAsFixed(2)}';
    } else if (igvPorPagar > 0) {
      return 'IGV por pagar: S/ ${igvPorPagar.toStringAsFixed(2)}';
    } else {
      return 'Sin IGV por pagar';
    }
  }

  @override
  String toString() {
    return 'HistorialIGV(id: $id, fecha: $fechaFormateada, saldoResultante: $saldoResultante)';
  }
}
