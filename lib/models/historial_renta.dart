class HistorialRenta {
  final String id;
  final DateTime fechaCalculo;
  final String regimenNombre;
  final String regimenEnum;

  // Datos de entrada
  final double ingresos;
  final double gastos;
  final double rentaNeta;

  // Resultado del cálculo
  final double baseImponible;
  final double impuestoRenta;
  final double rentaPorPagar;
  final double perdida;
  final double tasaRenta;
  final String tipoCalculo;
  final bool debePagar;
  final bool tienePerdida;

  // Metadatos
  final String? observaciones;
  final double? coeficientePersonalizado;
  final bool usandoCoeficiente;

  HistorialRenta({
    required this.id,
    required this.fechaCalculo,
    required this.regimenNombre,
    required this.regimenEnum,
    required this.ingresos,
    required this.gastos,
    required this.rentaNeta,
    required this.baseImponible,
    required this.impuestoRenta,
    required this.rentaPorPagar,
    required this.perdida,
    required this.tasaRenta,
    required this.tipoCalculo,
    required this.debePagar,
    required this.tienePerdida,
    this.observaciones,
    this.coeficientePersonalizado,
    this.usandoCoeficiente = false,
  });

  // Factory constructor para crear desde un resultado de cálculo
  factory HistorialRenta.fromCalculoResult({
    required Map<String, dynamic> calculoResult,
    String? observaciones,
  }) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime fechaCalculo = DateTime.parse(
      calculoResult['fecha_calculo'],
    );

    return HistorialRenta(
      id: id,
      fechaCalculo: fechaCalculo,
      regimenNombre: calculoResult['regimen_nombre'],
      regimenEnum: calculoResult['regimen_enum'],
      ingresos: calculoResult['ingresos'],
      gastos: calculoResult['gastos'],
      rentaNeta: calculoResult['renta_neta'],
      baseImponible: calculoResult['base_imponible'],
      impuestoRenta: calculoResult['impuesto_renta'],
      rentaPorPagar: calculoResult['renta_por_pagar'],
      perdida: calculoResult['perdida'],
      tasaRenta: calculoResult['tasa_renta'],
      tipoCalculo: calculoResult['tipo_calculo'] ?? 'Cálculo estándar',
      debePagar: calculoResult['debe_pagar'],
      tienePerdida: calculoResult['tiene_perdida'],
      observaciones: observaciones,
      coeficientePersonalizado: calculoResult['coeficiente_personalizado'],
      usandoCoeficiente: calculoResult['usando_coeficiente'] ?? false,
    );
  }

  // Factory constructor para crear desde Map (para base de datos)
  factory HistorialRenta.fromMap(Map<String, dynamic> map) {
    return HistorialRenta(
      id: map['id'],
      fechaCalculo: DateTime.parse(map['fechaCalculo']),
      regimenNombre: map['regimenNombre'],
      regimenEnum: map['regimenEnum'],
      ingresos: map['ingresos'].toDouble(),
      gastos: map['gastos'].toDouble(),
      rentaNeta: map['rentaNeta'].toDouble(),
      baseImponible: map['baseImponible'].toDouble(),
      impuestoRenta: map['impuestoRenta'].toDouble(),
      rentaPorPagar: map['rentaPorPagar'].toDouble(),
      perdida: map['perdida'].toDouble(),
      tasaRenta: map['tasaRenta'].toDouble(),
      tipoCalculo: map['tipoCalculo'],
      debePagar: map['debePagar'] == 1,
      tienePerdida: map['tienePerdida'] == 1,
      observaciones: map['observaciones'],
      coeficientePersonalizado: map['coeficientePersonalizado']?.toDouble(),
      usandoCoeficiente: map['usandoCoeficiente'] == 1,
    );
  }

  // Convertir a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaCalculo': fechaCalculo.toIso8601String(),
      'regimenNombre': regimenNombre,
      'regimenEnum': regimenEnum,
      'ingresos': ingresos,
      'gastos': gastos,
      'rentaNeta': rentaNeta,
      'baseImponible': baseImponible,
      'impuestoRenta': impuestoRenta,
      'rentaPorPagar': rentaPorPagar,
      'perdida': perdida,
      'tasaRenta': tasaRenta,
      'tipoCalculo': tipoCalculo,
      'debePagar': debePagar ? 1 : 0,
      'tienePerdida': tienePerdida ? 1 : 0,
      'observaciones': observaciones,
      'coeficientePersonalizado': coeficientePersonalizado,
      'usandoCoeficiente': usandoCoeficiente ? 1 : 0,
    };
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() => toMap();

  // Propiedades formateadas para la UI
  String get fechaFormateada {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fechaCalculo.day} ${months[fechaCalculo.month - 1]} ${fechaCalculo.year}';
  }

  String get regimenFormatted => regimenNombre;

  String get resumenCalculo {
    if (tienePerdida) {
      return 'Pérdida: S/ ${perdida.toStringAsFixed(2)}';
    } else if (debePagar) {
      return 'Renta por pagar: S/ ${rentaPorPagar.toStringAsFixed(2)}';
    } else {
      return 'Sin impuesto por pagar';
    }
  }

  @override
  String toString() {
    return 'HistorialRenta{id: $id, fechaCalculo: $fechaCalculo, regimenNombre: $regimenNombre, impuestoRenta: $impuestoRenta}';
  }
}
