class RegimenTributario {
  final int id;
  final String nombre;
  final String? descripcion;
  final double tasaRenta;
  final double tasaIGV;
  final double? limiteIngresos;
  final bool activo;

  // Constantes para MYPE
  static const double limiteMyeBasico = 1605000.0; // S/ 1,605,000
  static const double tasaMyeBasica = 1.0; // 1%
  static const double tasaMyeElevada = 1.5; // 1.5%

  RegimenTributario({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tasaRenta,
    this.tasaIGV = 18.0, // IGV por defecto 18%
    this.limiteIngresos,
    this.activo = true,
  });

  factory RegimenTributario.fromJson(Map<String, dynamic> json) {
    return RegimenTributario(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      tasaRenta: (json['tasa_renta'] ?? 0.0).toDouble(),
      tasaIGV: (json['tasa_igv'] ?? 18.0).toDouble(),
      limiteIngresos: json['limite_ingresos']?.toDouble(),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tasa_renta': tasaRenta,
      'tasa_igv': tasaIGV,
      'limite_ingresos': limiteIngresos,
      'activo': activo,
    };
  }

  String get tasaRentaFormateada {
    return '${tasaRenta.toStringAsFixed(1)}%';
  }

  String get tasaIGVFormateada {
    return '${tasaIGV.toStringAsFixed(1)}%';
  }

  bool get pagaIGV {
    // RUS no paga IGV (tasa IGV = 0%)
    return tasaIGV > 0;
  }

  // Método para calcular coeficiente
  static double calcularCoeficiente({
    required double ingresos,
    required double gastosDeducibles,
  }) {
    if (ingresos <= 0) return 0.0;

    double utilidad = ingresos - gastosDeducibles;
    if (utilidad <= 0) return 0.0;

    return utilidad / ingresos;
  }

  // Método para determinar la tasa de renta aplicable para MYPE
  static Map<String, dynamic> calcularTasaMyPE({
    required double ingresos,
    required double gastosDeducibles,
    double? coeficientePersonalizado,
  }) {
    // Si los ingresos son menores o iguales al límite básico
    if (ingresos <= limiteMyeBasico) {
      return {
        'tasa': tasaMyeBasica / 100, // 1%
        'tipo': 'basica',
        'descripcion':
            'Tasa básica 1% (ingresos ≤ S/ ${limiteMyeBasico.toStringAsFixed(0)})',
        'base': ingresos,
      };
    }

    // Calcular coeficiente automático
    double coeficienteAuto = calcularCoeficiente(
      ingresos: ingresos,
      gastosDeducibles: gastosDeducibles,
    );

    // Usar coeficiente personalizado si se proporciona
    double coeficienteAUsar = coeficientePersonalizado ?? coeficienteAuto;

    // ✨ NUEVA LÓGICA: Siempre usar el menor entre coeficiente y 1.5%
    const double tasaMaxima = 0.015; // 1.5%

    // Si no se proporciona coeficiente, usar automáticamente 1.5%
    if (coeficientePersonalizado == null) {
      return {
        'tasa': tasaMaxima, // 1.5% por defecto
        'tipo': 'automatico',
        'descripcion': 'Tasa automática 1.5% (sin coeficiente personalizado)',
        'base': ingresos,
        'coeficiente': coeficienteAuto,
        'coeficientePersonalizado': false,
      };
    }

    // Con coeficiente personalizado: aplicar lógica de comparación
    if (coeficienteAUsar < tasaMaxima) {
      return {
        'tasa': coeficienteAUsar, // Usar coeficiente (es menor)
        'tipo': 'coeficiente_menor',
        'descripcion':
            'Coeficiente ${(coeficienteAUsar * 100).toStringAsFixed(2)}% aplicado (menor a 1.5%)',
        'base': ingresos,
        'coeficiente': coeficienteAUsar,
        'coeficientePersonalizado': true,
      };
    } else {
      return {
        'tasa': tasaMaxima, // Usar 1.5% (coeficiente es mayor o igual)
        'tipo': 'limitado_maximo',
        'descripcion':
            'Tasa limitada a 1.5% (coeficiente ${(coeficienteAUsar * 100).toStringAsFixed(2)}% >= 1.5%)',
        'base': ingresos,
        'coeficiente': coeficienteAUsar,
        'coeficientePersonalizado': true,
      };
    }
  }

  // Método para obtener la tasa aplicable según el régimen
  double obtenerTasaAplicable({
    double? ingresos,
    double? gastosDeducibles,
    double? coeficientePersonalizado,
    bool usarCoeficiente = false,
  }) {
    // Para MYPE con cálculo especial
    if (nombre.contains('MYPE') && ingresos != null) {
      var resultado = calcularTasaMyPE(
        ingresos: ingresos,
        gastosDeducibles: gastosDeducibles ?? 0.0,
        coeficientePersonalizado: coeficientePersonalizado,
      );

      if (resultado['tipo'] == 'opcional' && usarCoeficiente) {
        return resultado['tasaAlternativa'];
      }

      return resultado['tasa'];
    }

    // Para otros regímenes, usar la tasa base
    return tasaRenta;
  }

  RegimenTributario copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? tasaRenta,
    double? tasaIGV,
    double? limiteIngresos,
    bool? activo,
  }) {
    return RegimenTributario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tasaRenta: tasaRenta ?? this.tasaRenta,
      tasaIGV: tasaIGV ?? this.tasaIGV,
      limiteIngresos: limiteIngresos ?? this.limiteIngresos,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'RegimenTributario(id: $id, nombre: $nombre, tasaRenta: $tasaRentaFormateada, tasaIGV: $tasaIGVFormateada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegimenTributario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum para compatibilidad con código existente
enum RegimenTributarioEnum { general, mype, especial, rus }

extension RegimenTributarioEnumExtension on RegimenTributarioEnum {
  String get nombre {
    switch (this) {
      case RegimenTributarioEnum.general:
        return 'Régimen General';
      case RegimenTributarioEnum.mype:
        return 'Régimen MYPE';
      case RegimenTributarioEnum.especial:
        return 'Régimen Especial';
      case RegimenTributarioEnum.rus:
        return 'RUS';
    }
  }

  double get tasaRenta {
    switch (this) {
      case RegimenTributarioEnum.general:
        return 0.015;
      case RegimenTributarioEnum.mype:
        return 0.001;
      case RegimenTributarioEnum.especial:
        return 0.015;
      case RegimenTributarioEnum.rus:
        return 0.0;
    }
  }

  bool get pagaIGV {
    return this != RegimenTributarioEnum.rus;
  }
}

/// 🎯 **Función principal para calcular tasa de renta según régimen tributario**
///
/// Esta función implementa la lógica completa de cálculo de tasas de renta
/// según las reglas específicas de cada régimen tributario peruano.
///
/// **Parámetros:**
/// - `regimen`: El régimen tributario aplicable
/// - `monto`: Monto base para evaluar límites (ingresos anuales)
/// - `coeficiente`: Coeficiente opcional para régimen MYPE (formato decimal)
///
/// **Retorna:** Tasa de renta en formato decimal (ej: 0.015 = 1.5%)
///
/// **Excepciones:**
/// - `ArgumentError` si el coeficiente es negativo
/// - `ArgumentError` si el monto es negativo
double calcularTasaRenta(
  RegimenTributarioEnum regimen, {
  required double monto,
  double? coeficiente,
}) {
  // 🔒 Validaciones de entrada
  if (monto < 0) {
    throw ArgumentError('El monto no puede ser negativo: $monto');
  }

  if (coeficiente != null && coeficiente < 0) {
    throw ArgumentError('El coeficiente no puede ser negativo: $coeficiente');
  }

  // 🎛️ Constantes del sistema tributario peruano
  const double limiteMyPEBasico = 1605000.0; // S/ 1,605,000
  const double tasaMyPEBasica = 0.01; // 1%
  const double tasaEstandar = 0.015; // 1.5%
  const double tasaRUS = 0.0; // 0% - RUS no paga renta

  switch (regimen) {
    // 🔹 RÉGIMEN GENERAL
    case RegimenTributarioEnum.general:
      // Siempre paga 1.5% sin excepciones
      return tasaEstandar;

    // 🔹 RÉGIMEN MYPE (Micro y Pequeña Empresa)
    case RegimenTributarioEnum.mype:
      // Evaluar límite de ingresos
      if (monto <= limiteMyPEBasico) {
        // 💰 Monto ≤ S/ 1,605,000: Tasa básica del 1%
        return tasaMyPEBasica;
      } else {
        // 💸 Monto > S/ 1,605,000: Lógica de coeficiente
        if (coeficiente == null) {
          // Sin coeficiente específico: usar 1.5% estándar
          return tasaEstandar;
        } else {
          // Con coeficiente: usar el menor entre coeficiente y 1.5%
          // Esto garantiza que nunca se pague más del máximo legal
          return coeficiente < tasaEstandar ? coeficiente : tasaEstandar;
        }
      }

    // 🔹 RÉGIMEN ESPECIAL
    case RegimenTributarioEnum.especial:
      // Siempre paga 1.5% independientemente del monto
      return tasaEstandar;

    // 🔹 RUS (Régimen Único Simplificado)
    case RegimenTributarioEnum.rus:
      // RUS no paga impuesto a la renta
      return tasaRUS;
  }
}

/// 🧮 **Utilidades adicionales para cálculos tributarios**
extension CalculosTributariosUtils on RegimenTributarioEnum {
  /// 📊 Calcula el impuesto a la renta basado en la tasa calculada
  ///
  /// **Parámetros:**
  /// - `baseImponible`: Base sobre la cual se calcula el impuesto
  /// - `monto`: Monto de referencia para límites
  /// - `coeficiente`: Coeficiente opcional
  ///
  /// **Retorna:** Monto del impuesto a pagar
  double calcularImpuestoRenta({
    required double baseImponible,
    required double monto,
    double? coeficiente,
  }) {
    if (baseImponible <= 0) return 0.0;

    final tasa = calcularTasaRenta(
      this,
      monto: monto,
      coeficiente: coeficiente,
    );

    return baseImponible * tasa;
  }

  /// 📈 Obtiene información detallada del cálculo
  ///
  /// **Retorna:** Mapa con detalles del cálculo realizado
  Map<String, dynamic> obtenerDetalleCalculo({
    required double monto,
    double? coeficiente,
  }) {
    final tasa = calcularTasaRenta(
      this,
      monto: monto,
      coeficiente: coeficiente,
    );

    final tasaPorcentaje = (tasa * 100).toStringAsFixed(2);

    String explicacion;
    switch (this) {
      case RegimenTributarioEnum.general:
        explicacion = 'Régimen General: Tasa fija del 1.5%';
        break;
      case RegimenTributarioEnum.mype:
        if (monto <= 1605000.0) {
          explicacion = 'MYPE: Ingresos ≤ S/ 1,605,000 - Tasa básica del 1%';
        } else {
          if (coeficiente == null) {
            explicacion =
                'MYPE: Ingresos > S/ 1,605,000 - Tasa estándar del 1.5%';
          } else {
            final coefPorcentaje = (coeficiente * 100).toStringAsFixed(2);
            explicacion = coeficiente < 0.015
                ? 'MYPE: Usando coeficiente $coefPorcentaje% (menor a 1.5%)'
                : 'MYPE: Coeficiente $coefPorcentaje% limitado a 1.5% máximo';
          }
        }
        break;
      case RegimenTributarioEnum.especial:
        explicacion = 'Régimen Especial: Tasa fija del 1.5%';
        break;
      case RegimenTributarioEnum.rus:
        explicacion = 'RUS: Sin impuesto a la renta';
        break;
    }

    return {
      'regimen': nombre,
      'tasa_decimal': tasa,
      'tasa_porcentaje': '$tasaPorcentaje%',
      'monto_evaluado': monto,
      'coeficiente_usado': coeficiente,
      'explicacion': explicacion,
      'fecha_calculo': DateTime.now().toIso8601String(),
    };
  }

  /// 🎯 Verifica si el régimen permite uso de coeficientes
  bool get permiteCoeficiente => this == RegimenTributarioEnum.mype;

  /// 📏 Obtiene el límite de monto donde cambia la tasa (solo MYPE)
  double? get limiteMontoEspecial =>
      this == RegimenTributarioEnum.mype ? 1605000.0 : null;
}

/// 🧪 **Ejemplos de uso y casos de prueba**
///
/// ```dart
/// // Ejemplos básicos
/// final tasaMype1 = calcularTasaRenta(RegimenTributarioEnum.mype, monto: 1000000);
/// // → 0.01 (1%)
///
/// final tasaMype2 = calcularTasaRenta(RegimenTributarioEnum.mype,
///   monto: 1800000, coeficiente: 0.012);
/// // → 0.012 (1.2%)
///
/// final tasaMype3 = calcularTasaRenta(RegimenTributarioEnum.mype,
///   monto: 1800000, coeficiente: 0.018);
/// // → 0.015 (1.5% - limitado)
///
/// final tasaGeneral = calcularTasaRenta(RegimenTributarioEnum.general, monto: 5000000);
/// // → 0.015 (1.5%)
///
/// // Uso con utilidades
/// final impuesto = RegimenTributarioEnum.mype.calcularImpuestoRenta(
///   baseImponible: 800000,
///   monto: 1200000
/// ); // → 8000 (800000 * 0.01)
///
/// final detalle = RegimenTributarioEnum.mype.obtenerDetalleCalculo(
///   monto: 1800000,
///   coeficiente: 0.012
/// );
/// // → Map con información completa del cálculo
/// ```
