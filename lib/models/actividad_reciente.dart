class ActividadReciente {
  final int? id;
  final String tipo; // 'calculo_renta', 'calculo_igv', 'regimen_creado', etc.
  final String descripcion;
  final Map<String, dynamic> datos; // JSON con los datos específicos
  final DateTime fechaCreacion;
  final String icono; // Nombre del icono de Material Icons
  final String color; // Color en formato hex

  ActividadReciente({
    this.id,
    required this.tipo,
    required this.descripcion,
    required this.datos,
    required this.fechaCreacion,
    required this.icono,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descripcion': descripcion,
      'datos': datos,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'icono': icono,
      'color': color,
    };
  }

  factory ActividadReciente.fromJson(Map<String, dynamic> json) {
    return ActividadReciente(
      id: json['id'] as int?,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      datos: Map<String, dynamic>.from(json['datos']),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      icono: json['icono'] as String,
      color: json['color'] as String,
    );
  }

  // Método para crear actividades específicas
  static ActividadReciente calculoRenta({
    required double ingresos,
    required double impuesto,
    required String regimenNombre,
  }) {
    return ActividadReciente(
      tipo: 'calculo_renta',
      descripcion: 'Cálculo de Renta: S/ ${impuesto.toStringAsFixed(2)}',
      datos: {
        'ingresos': ingresos,
        'impuesto': impuesto,
        'regimen': regimenNombre,
      },
      fechaCreacion: DateTime.now(),
      icono: 'calculate',
      color: '#4CAF50',
    );
  }

  static ActividadReciente calculoIGV({
    required double baseImponible,
    required double igv,
  }) {
    return ActividadReciente(
      tipo: 'calculo_igv',
      descripcion: 'Cálculo de IGV: S/ ${igv.toStringAsFixed(2)}',
      datos: {'baseImponible': baseImponible, 'igv': igv},
      fechaCreacion: DateTime.now(),
      icono: 'receipt',
      color: '#2196F3',
    );
  }

  static ActividadReciente regimenCreado({
    required String nombre,
    required double tasaRenta,
  }) {
    return ActividadReciente(
      tipo: 'regimen_creado',
      descripcion: 'Régimen creado: $nombre (${tasaRenta}%)',
      datos: {'nombre': nombre, 'tasaRenta': tasaRenta},
      fechaCreacion: DateTime.now(),
      icono: 'add_business',
      color: '#FF9800',
    );
  }

  static ActividadReciente empresaConfigurada({
    required String razonSocial,
    required String ruc,
  }) {
    return ActividadReciente(
      tipo: 'empresa_configurada',
      descripcion: 'Empresa configurada: $razonSocial',
      datos: {'razonSocial': razonSocial, 'ruc': ruc},
      fechaCreacion: DateTime.now(),
      icono: 'business',
      color: '#9C27B0',
    );
  }
}
