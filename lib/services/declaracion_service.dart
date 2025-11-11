import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/declaracion.dart';
import '../models/database_models.dart';
import '../models/regimen_tributario.dart';
import 'database_service.dart';

class DeclaracionService {
  final DatabaseService _databaseService = DatabaseService();

  // ===== VERIFICACIÓN Y CREACIÓN DE TABLA =====

  /// Verificar si la tabla Declaraciones existe y crearla si no existe
  Future<void> _verificarTablaDeclaraciones() async {
    final db = await _databaseService.database;

    try {
      // Intentar consultar la tabla
      await db.rawQuery('SELECT COUNT(*) FROM Declaraciones LIMIT 1');
      print('Tabla Declaraciones existe');
    } catch (e) {
      print('Tabla Declaraciones no existe, creándola...');
      try {
        await db.execute('''
          CREATE TABLE Declaraciones (
            id TEXT PRIMARY KEY,
            empresa_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            periodo TEXT NOT NULL,
            monto REAL NOT NULL,
            estado TEXT NOT NULL,
            fecha_creacion TEXT NOT NULL,
            fecha_presentacion TEXT,
            numero_formulario TEXT,
            numero_orden TEXT,
            datos_json TEXT,
            archivo_pdf TEXT,
            FOREIGN KEY (empresa_id) REFERENCES Empresas (id)
          )
        ''');
        print('Tabla Declaraciones creada exitosamente');
      } catch (createError) {
        print('Error al crear tabla Declaraciones: $createError');
        // Si falla, intentar resetear la base de datos
        await _databaseService.resetDatabase();
      }
    }
  }

  // ===== CRUD DECLARACIONES =====

  /// Crear una nueva declaración
  Future<String> crearDeclaracion(Declaracion declaracion) async {
    final db = await _databaseService.database;

    final id = 'DCL${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('Declaraciones', {
      'id': id,
      'empresa_id': declaracion.empresaId,
      'tipo': declaracion.tipo.name,
      'periodo': declaracion.periodo.toIso8601String(),
      'monto': declaracion.monto,
      'estado': declaracion.estado.name,
      'fecha_creacion': declaracion.fechaCreacion.toIso8601String(),
      'fecha_presentacion': declaracion.fechaPresentacion?.toIso8601String(),
      'numero_formulario': declaracion.numeroFormulario,
      'numero_orden': declaracion.numeroOrden,
      'datos_json': jsonEncode(declaracion.datos),
      'archivo_pdf': null,
    });

    return id;
  }

  /// Obtener todas las declaraciones
  Future<List<Declaracion>> obtenerDeclaraciones() async {
    await _verificarTablaDeclaraciones();

    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Declaraciones',
      orderBy: 'fecha_creacion DESC',
    );

    return List.generate(maps.length, (i) => _mapToDeclaracion(maps[i]));
  }

  /// Obtener declaraciones por empresa
  Future<List<Declaracion>> obtenerDeclaracionesPorEmpresa(
    int empresaId,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Declaraciones',
      where: 'empresa_id = ?',
      whereArgs: [empresaId],
      orderBy: 'periodo DESC',
    );

    return List.generate(maps.length, (i) => _mapToDeclaracion(maps[i]));
  }

  /// Obtener declaraciones por período
  Future<List<Declaracion>> obtenerDeclaracionesPorPeriodo(
    DateTime periodo,
  ) async {
    final db = await _databaseService.database;
    final String periodoStr = DateFormat('yyyy-MM').format(periodo);

    final List<Map<String, dynamic>> maps = await db.query(
      'Declaraciones',
      where: 'periodo LIKE ?',
      whereArgs: ['$periodoStr%'],
      orderBy: 'fecha_creacion DESC',
    );

    return List.generate(maps.length, (i) => _mapToDeclaracion(maps[i]));
  }

  /// Actualizar declaración
  Future<void> actualizarDeclaracion(Declaracion declaracion) async {
    final db = await _databaseService.database;

    await db.update(
      'Declaraciones',
      {
        'monto': declaracion.monto,
        'estado': declaracion.estado.name,
        'fecha_presentacion': declaracion.fechaPresentacion?.toIso8601String(),
        'numero_formulario': declaracion.numeroFormulario,
        'numero_orden': declaracion.numeroOrden,
        'datos_json': jsonEncode(declaracion.datos),
      },
      where: 'id = ?',
      whereArgs: [declaracion.id],
    );
  }

  /// Eliminar declaración
  Future<void> eliminarDeclaracion(String id) async {
    final db = await _databaseService.database;
    await db.delete('Declaraciones', where: 'id = ?', whereArgs: [id]);
  }

  // ===== GENERACIÓN DE PDF =====

  /// Generar PDF de una declaración
  Future<String> generarPDF(Declaracion declaracion) async {
    final empresa = await _obtenerEmpresa(int.parse(declaracion.empresaId));
    final regimen = await _obtenerRegimen(empresa?.regimenId ?? 1);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPDFHeader(declaracion, empresa, regimen),
          pw.SizedBox(height: 20),
          _buildPDFContent(declaracion, empresa, regimen),
          pw.SizedBox(height: 30),
          _buildPDFFooter(declaracion),
        ],
      ),
    );

    // Guardar PDF
    final directory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${directory.path}/declaraciones_pdf');
    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }

    final fileName =
        'declaracion_${declaracion.tipo.name}_${DateFormat('yyyy_MM').format(declaracion.periodo)}_${declaracion.id}.pdf';
    final file = File('${pdfDirectory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    // Actualizar ruta del PDF en la base de datos
    final db = await _databaseService.database;
    await db.update(
      'Declaraciones',
      {'archivo_pdf': file.path},
      where: 'id = ?',
      whereArgs: [declaracion.id],
    );

    return file.path;
  }

  /// Vista previa del PDF
  Future<void> previsualizarPDF(Declaracion declaracion) async {
    final empresa = await _obtenerEmpresa(int.parse(declaracion.empresaId));
    final regimen = await _obtenerRegimen(empresa?.regimenId ?? 1);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPDFHeader(declaracion, empresa, regimen),
          pw.SizedBox(height: 20),
          _buildPDFContent(declaracion, empresa, regimen),
          pw.SizedBox(height: 30),
          _buildPDFFooter(declaracion),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Declaración ${declaracion.tipo.name.toUpperCase()} - ${DateFormat('MMMM yyyy', 'es').format(declaracion.periodo)}',
    );
  }

  /// Compartir PDF
  Future<void> compartirPDF(Declaracion declaracion) async {
    String pdfPath;

    // Verificar si ya existe el PDF
    if (declaracion.archivoPdf != null &&
        File(declaracion.archivoPdf!).existsSync()) {
      pdfPath = declaracion.archivoPdf!;
    } else {
      pdfPath = await generarPDF(declaracion);
    }

    final fileName =
        'declaracion_${declaracion.tipo.name}_${DateFormat('yyyy_MM').format(declaracion.periodo)}.pdf';

    await Share.shareXFiles(
      [XFile(pdfPath)],
      text:
          'Declaración ${declaracion.tipo.name.toUpperCase()} - ${DateFormat('MMMM yyyy', 'es').format(declaracion.periodo)}',
      subject: fileName,
    );
  }

  // ===== MÉTODOS PRIVADOS =====

  Declaracion _mapToDeclaracion(Map<String, dynamic> map) {
    return Declaracion(
      id: map['id'],
      empresaId: map['empresa_id'].toString(),
      tipo: TipoDeclaracion.values.firstWhere((t) => t.name == map['tipo']),
      periodo: DateTime.parse(map['periodo']),
      monto: map['monto'].toDouble(),
      estado: EstadoDeclaracion.values.firstWhere(
        (e) => e.name == map['estado'],
      ),
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      fechaPresentacion: map['fecha_presentacion'] != null
          ? DateTime.parse(map['fecha_presentacion'])
          : null,
      numeroFormulario: map['numero_formulario'],
      numeroOrden: map['numero_orden'],
      datos: map['datos_json'] != null ? jsonDecode(map['datos_json']) : {},
      archivoPdf: map['archivo_pdf'],
    );
  }

  Future<Empresa?> _obtenerEmpresa(int empresaId) async {
    final empresas = await _databaseService.obtenerEmpresas();
    return empresas.isNotEmpty ? empresas.first : null;
  }

  Future<RegimenTributario?> _obtenerRegimen(int regimenId) async {
    final regimenes = await _databaseService.obtenerRegimenes();
    return regimenes.firstWhere(
      (r) => r.id == regimenId,
      orElse: () => regimenes.first,
    );
  }

  // ===== CONSTRUCCIÓN DE PDF =====

  pw.Widget _buildPDFHeader(
    Declaracion declaracion,
    Empresa? empresa,
    RegimenTributario? regimen,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'COMPULSA',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Asistente Tributario Inteligente',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.blue600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DECLARACIÓN ${declaracion.tipo.name.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'ID: ${declaracion.id}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EMPRESA:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      empresa?.nombreRazonSocial ?? 'No especificada',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'RUC: ${empresa?.ruc ?? 'No especificado'}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PERÍODO:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMMM yyyy', 'es').format(declaracion.periodo),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Régimen: ${regimen?.nombre ?? 'No especificado'}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFContent(
    Declaracion declaracion,
    Empresa? empresa,
    RegimenTributario? regimen,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE LA DECLARACIÓN',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 15),

        // Información general
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              _buildPDFInfoRow(
                'Tipo de Declaración:',
                declaracion.tipo.name.toUpperCase(),
              ),
              _buildPDFInfoRow(
                'Estado:',
                _getEstadoDescripcion(declaracion.estado),
              ),
              _buildPDFInfoRow(
                'Monto a Pagar:',
                'S/ ${declaracion.monto.toStringAsFixed(2)}',
              ),
              _buildPDFInfoRow(
                'Fecha de Creación:',
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(declaracion.fechaCreacion),
              ),
              if (declaracion.fechaPresentacion != null)
                _buildPDFInfoRow(
                  'Fecha de Presentación:',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(declaracion.fechaPresentacion!),
                ),
              if (declaracion.numeroFormulario != null)
                _buildPDFInfoRow(
                  'Número de Formulario:',
                  declaracion.numeroFormulario!,
                ),
              if (declaracion.numeroOrden != null)
                _buildPDFInfoRow('Número de Orden:', declaracion.numeroOrden!),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Información del régimen tributario
        if (regimen != null) ...[
          pw.Text(
            'INFORMACIÓN TRIBUTARIA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              children: [
                _buildPDFInfoRow('Régimen Tributario:', regimen.nombre),
                _buildPDFInfoRow('Tasa Renta:', regimen.tasaRentaFormateada),
                _buildPDFInfoRow('Tasa IGV:', regimen.tasaIGVFormateada),
                _buildPDFInfoRow('Paga IGV:', regimen.pagaIGV ? 'Sí' : 'No'),
              ],
            ),
          ),
        ],

        // Datos adicionales si existen
        if (declaracion.datos.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'DATOS ADICIONALES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              children: declaracion.datos.entries.map((entry) {
                return _buildPDFInfoRow(
                  '${entry.key}:',
                  entry.value.toString(),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFFooter(Declaracion declaracion) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'COMPULSA - Asistente Tributario Inteligente',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Documento generado automáticamente el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Este documento es una representación digital de su declaración tributaria',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  String _getEstadoDescripcion(EstadoDeclaracion estado) {
    switch (estado) {
      case EstadoDeclaracion.borrador:
        return 'Borrador';
      case EstadoDeclaracion.pendiente:
        return 'Pendiente de Presentación';
      case EstadoDeclaracion.presentada:
        return 'Presentada';
      case EstadoDeclaracion.observada:
        return 'Observada';
      case EstadoDeclaracion.cancelada:
        return 'Cancelada';
    }
  }

  // ===== MÉTODOS DE RESUMEN Y ESTADÍSTICAS =====

  /// Obtener resumen mensual de declaraciones
  Future<Map<String, dynamic>> obtenerResumenMensual(DateTime mes) async {
    final declaraciones = await obtenerDeclaracionesPorPeriodo(mes);

    double totalIGV = 0;
    double totalRenta = 0;
    int presentadas = 0;
    int pendientes = 0;

    for (final declaracion in declaraciones) {
      if (declaracion.tipo == TipoDeclaracion.igv) {
        totalIGV += declaracion.monto;
      } else if (declaracion.tipo == TipoDeclaracion.renta) {
        totalRenta += declaracion.monto;
      }

      if (declaracion.estado == EstadoDeclaracion.presentada) {
        presentadas++;
      } else if (declaracion.estado == EstadoDeclaracion.pendiente) {
        pendientes++;
      }
    }

    return {
      'totalDeclaraciones': declaraciones.length,
      'totalIGV': totalIGV,
      'totalRenta': totalRenta,
      'totalMonto': totalIGV + totalRenta,
      'presentadas': presentadas,
      'pendientes': pendientes,
      'declaraciones': declaraciones,
    };
  }

  /// Obtener resumen anual
  Future<Map<String, dynamic>> obtenerResumenAnual(int anio) async {
    final db = await _databaseService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'Declaraciones',
      where: 'periodo >= ? AND periodo < ?',
      whereArgs: [
        DateTime(anio, 1, 1).toIso8601String(),
        DateTime(anio + 1, 1, 1).toIso8601String(),
      ],
      orderBy: 'periodo ASC',
    );

    final declaraciones = List.generate(
      maps.length,
      (i) => _mapToDeclaracion(maps[i]),
    );

    double totalAnual = 0;
    Map<int, double> montosPorMes = {};
    Map<String, int> declaracionesPorTipo = {};

    for (final declaracion in declaraciones) {
      totalAnual += declaracion.monto;

      final mes = declaracion.periodo.month;
      montosPorMes[mes] = (montosPorMes[mes] ?? 0) + declaracion.monto;

      final tipo = declaracion.tipo.name;
      declaracionesPorTipo[tipo] = (declaracionesPorTipo[tipo] ?? 0) + 1;
    }

    return {
      'anio': anio,
      'totalDeclaraciones': declaraciones.length,
      'totalAnual': totalAnual,
      'montosPorMes': montosPorMes,
      'declaracionesPorTipo': declaracionesPorTipo,
      'declaraciones': declaraciones,
    };
  }
}
