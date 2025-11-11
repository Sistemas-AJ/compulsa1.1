class Empresa {
  final int? id;
  final int regimenId;
  final String nombreRazonSocial;
  final String ruc;
  final String? imagenPerfil;

  Empresa({
    this.id,
    required this.regimenId,
    required this.nombreRazonSocial,
    required this.ruc,
    this.imagenPerfil,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] as int?,
      regimenId: json['regimen_id'] as int,
      nombreRazonSocial: json['nombre_razon_social'] as String,
      ruc: json['ruc'] as String,
      imagenPerfil: json['imagen_perfil'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regimen_id': regimenId,
      'nombre_razon_social': nombreRazonSocial,
      'ruc': ruc,
      'imagen_perfil': imagenPerfil,
    };
  }
}

class LiquidacionMensual {
  final int id;
  final int empresaId;
  final String periodo;
  final double totalVentasNetas;
  final double totalComprasNetas;
  final double igvResultante;
  final double rentaCalculada;

  LiquidacionMensual({
    required this.id,
    required this.empresaId,
    required this.periodo,
    required this.totalVentasNetas,
    required this.totalComprasNetas,
    required this.igvResultante,
    required this.rentaCalculada,
  });

  factory LiquidacionMensual.fromJson(Map<String, dynamic> json) {
    return LiquidacionMensual(
      id: json['id'],
      empresaId: json['empresa_id'],
      periodo: json['periodo'],
      totalVentasNetas: (json['total_ventas_netas'] as num).toDouble(),
      totalComprasNetas: (json['total_compras_netas'] as num).toDouble(),
      igvResultante: (json['igv_resultante'] as num).toDouble(),
      rentaCalculada: (json['renta_calculada'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'periodo': periodo,
      'total_ventas_netas': totalVentasNetas,
      'total_compras_netas': totalComprasNetas,
      'igv_resultante': igvResultante,
      'renta_calculada': rentaCalculada,
    };
  }
}

class PagoRealizado {
  final int id;
  final int liquidacionId;
  final String tipoImpuesto;
  final double montoPagado;
  final String fechaPago;
  final String codigoOperacion;

  PagoRealizado({
    required this.id,
    required this.liquidacionId,
    required this.tipoImpuesto,
    required this.montoPagado,
    required this.fechaPago,
    required this.codigoOperacion,
  });

  factory PagoRealizado.fromJson(Map<String, dynamic> json) {
    return PagoRealizado(
      id: json['id'],
      liquidacionId: json['liquidacion_id'],
      tipoImpuesto: json['tipo_impuesto'],
      montoPagado: (json['monto_pagado'] as num).toDouble(),
      fechaPago: json['fecha_pago'],
      codigoOperacion: json['codigo_operacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liquidacion_id': liquidacionId,
      'tipo_impuesto': tipoImpuesto,
      'monto_pagado': montoPagado,
      'fecha_pago': fechaPago,
      'codigo_operacion': codigoOperacion,
    };
  }
}

class SaldoFiscal {
  final int id;
  final int empresaId;
  final String periodo;
  final double montoSaldoIgv;
  final double montoSaldoRenta;
  final String origen;

  SaldoFiscal({
    required this.id,
    required this.empresaId,
    required this.periodo,
    required this.montoSaldoIgv,
    required this.montoSaldoRenta,
    required this.origen,
  });

  factory SaldoFiscal.fromJson(Map<String, dynamic> json) {
    return SaldoFiscal(
      id: json['id'],
      empresaId: json['empresa_id'],
      periodo: json['periodo'],
      montoSaldoIgv: (json['monto_saldo_igv'] as num).toDouble(),
      montoSaldoRenta: (json['monto_saldo_renta'] as num).toDouble(),
      origen: json['origen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'periodo': periodo,
      'monto_saldo_igv': montoSaldoIgv,
      'monto_saldo_renta': montoSaldoRenta,
      'origen': origen,
    };
  }
}
