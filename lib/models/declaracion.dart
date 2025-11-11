enum TipoDeclaracion { igv, renta }

enum EstadoDeclaracion { borrador, pendiente, presentada, observada, cancelada }

class Declaracion {
  final String id;
  final String empresaId;
  final TipoDeclaracion tipo;
  final DateTime periodo;
  final double monto;
  final EstadoDeclaracion estado;
  final DateTime fechaCreacion;
  final DateTime? fechaPresentacion;
  final String? numeroFormulario;
  final String? numeroOrden;
  final Map<String, dynamic> datos;
  final String? archivoPdf;

  Declaracion({
    required this.id,
    required this.empresaId,
    required this.tipo,
    required this.periodo,
    required this.monto,
    this.estado = EstadoDeclaracion.borrador,
    required this.fechaCreacion,
    this.fechaPresentacion,
    this.numeroFormulario,
    this.numeroOrden,
    this.datos = const {},
    this.archivoPdf,
  });

  factory Declaracion.fromMap(Map<String, dynamic> map) {
    return Declaracion(
      id: map['id'],
      empresaId: map['empresaId'],
      tipo: TipoDeclaracion.values.firstWhere(
        (t) => t.toString().split('.').last == map['tipo'],
      ),
      periodo: DateTime.parse(map['periodo']),
      monto: map['monto'].toDouble(),
      estado: EstadoDeclaracion.values.firstWhere(
        (e) => e.toString().split('.').last == map['estado'],
        orElse: () => EstadoDeclaracion.borrador,
      ),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaPresentacion: map['fechaPresentacion'] != null
          ? DateTime.parse(map['fechaPresentacion'])
          : null,
      numeroFormulario: map['numeroFormulario'],
      numeroOrden: map['numeroOrden'],
      datos: Map<String, dynamic>.from(map['datos'] ?? {}),
      archivoPdf: map['archivoPdf'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresaId': empresaId,
      'tipo': tipo.toString().split('.').last,
      'periodo': periodo.toIso8601String(),
      'monto': monto,
      'estado': estado.toString().split('.').last,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaPresentacion': fechaPresentacion?.toIso8601String(),
      'numeroFormulario': numeroFormulario,
      'numeroOrden': numeroOrden,
      'datos': datos,
      'archivoPdf': archivoPdf,
    };
  }

  Declaracion copyWith({
    String? id,
    String? empresaId,
    TipoDeclaracion? tipo,
    DateTime? periodo,
    double? monto,
    EstadoDeclaracion? estado,
    DateTime? fechaCreacion,
    DateTime? fechaPresentacion,
    String? numeroFormulario,
    String? numeroOrden,
    Map<String, dynamic>? datos,
  }) {
    return Declaracion(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      tipo: tipo ?? this.tipo,
      periodo: periodo ?? this.periodo,
      monto: monto ?? this.monto,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaPresentacion: fechaPresentacion ?? this.fechaPresentacion,
      numeroFormulario: numeroFormulario ?? this.numeroFormulario,
      numeroOrden: numeroOrden ?? this.numeroOrden,
      datos: datos ?? this.datos,
    );
  }

  String get tipoNombre {
    switch (tipo) {
      case TipoDeclaracion.igv:
        return 'IGV';
      case TipoDeclaracion.renta:
        return 'Renta';
    }
  }

  String get estadoNombre {
    switch (estado) {
      case EstadoDeclaracion.borrador:
        return 'Borrador';
      case EstadoDeclaracion.pendiente:
        return 'Pendiente';
      case EstadoDeclaracion.presentada:
        return 'Presentada';
      case EstadoDeclaracion.observada:
        return 'Observada';
      case EstadoDeclaracion.cancelada:
        return 'Cancelada';
    }
  }

  String get periodoFormatted {
    final meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${meses[periodo.month]} ${periodo.year}';
  }

  bool get estaPresentada => estado == EstadoDeclaracion.presentada;
  bool get puedeEditar => estado == EstadoDeclaracion.borrador;
  bool get puedeEliminar => estado == EstadoDeclaracion.borrador;
}
