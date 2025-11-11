import '../models/historial_igv.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class HistorialIGVService {
  // Crear tabla si no existe
  static Future<void> _crearTabla() async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial_igv (
        id TEXT PRIMARY KEY,
        fechaCalculo TEXT NOT NULL,
        tipoNegocio TEXT NOT NULL,
        ventasGravadas REAL NOT NULL,
        compras18 REAL NOT NULL,
        compras10 REAL NOT NULL,
        saldoAnterior REAL NOT NULL,
        igvVentas REAL NOT NULL,
        igvCompras18 REAL NOT NULL,
        igvCompras10 REAL NOT NULL,
        totalIgvCompras REAL NOT NULL,
        calculoIgv REAL NOT NULL,
        igvPorCancelar REAL NOT NULL,
        tieneSaldoAFavor INTEGER NOT NULL,
        saldoAFavor REAL NOT NULL,
        igvPorPagar REAL NOT NULL,
        saldoResultante REAL NOT NULL,
        tasaIgvVentas REAL NOT NULL,
        observaciones TEXT
      )
    ''');
  }

  // Guardar un cálculo de IGV
  static Future<void> guardarCalculo(HistorialIGV historial) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    await db.insert(
      'historial_igv',
      historial.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener el último saldo disponible (para usar como saldo anterior)
  static Future<double> obtenerUltimoSaldo() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      orderBy: 'fechaCalculo DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['saldoResultante']?.toDouble() ?? 0.0;
    }

    return 0.0;
  }

  // Obtener todos los cálculos ordenados por fecha (más reciente primero)
  static Future<List<HistorialIGV>> obtenerTodosLosCalculos() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      orderBy: 'fechaCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return HistorialIGV.fromMap(maps[i]);
    });
  }

  // Obtener cálculos de un período específico
  static Future<List<HistorialIGV>> obtenerCalculosPorPeriodo({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      where: 'fechaCalculo >= ? AND fechaCalculo <= ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'fechaCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return HistorialIGV.fromMap(maps[i]);
    });
  }

  // Obtener resumen de los últimos cálculos
  static Future<Map<String, dynamic>> obtenerResumenReciente() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    // Obtener los últimos 5 cálculos
    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      orderBy: 'fechaCalculo DESC',
      limit: 5,
    );

    if (maps.isEmpty) {
      return {
        'total_calculos': 0,
        'ultimo_saldo': 0.0,
        'total_igv_pagado': 0.0,
        'total_saldo_favor': 0.0,
        'ultimo_calculo': null,
      };
    }

    final historiales = List.generate(maps.length, (i) {
      return HistorialIGV.fromMap(maps[i]);
    });

    double totalIgvPagado = 0.0;
    double totalSaldoFavor = 0.0;

    for (final historial in historiales) {
      totalIgvPagado += historial.igvPorPagar;
      if (historial.tieneSaldoAFavor) {
        totalSaldoFavor += historial.saldoAFavor;
      }
    }

    return {
      'total_calculos': maps.length,
      'ultimo_saldo': historiales.first.saldoResultante,
      'total_igv_pagado': totalIgvPagado,
      'total_saldo_favor': totalSaldoFavor,
      'ultimo_calculo': historiales.first,
    };
  }

  // Eliminar un cálculo específico
  static Future<void> eliminarCalculo(String id) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    // Verificar si el registro existe antes de eliminar
    final existingRecords = await db.query(
      'historial_igv',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingRecords.isEmpty) {
      throw Exception('No se encontró el cálculo con ID: $id');
    }

    final deletedRows = await db.delete(
      'historial_igv',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedRows == 0) {
      throw Exception('No se pudo eliminar el cálculo');
    }
  }

  // Obtener estadísticas mensuales
  static Future<Map<String, dynamic>> obtenerEstadisticasMensuales() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      where: 'fechaCalculo >= ? AND fechaCalculo <= ?',
      whereArgs: [inicioMes.toIso8601String(), finMes.toIso8601String()],
    );

    if (maps.isEmpty) {
      return {
        'mes': inicioMes.month,
        'año': inicioMes.year,
        'total_calculos': 0,
        'total_ventas': 0.0,
        'total_compras_18': 0.0,
        'total_compras_10': 0.0,
        'total_igv_pagado': 0.0,
        'total_saldo_favor': 0.0,
      };
    }

    double totalVentas = 0.0;
    double totalCompras18 = 0.0;
    double totalCompras10 = 0.0;
    double totalIgvPagado = 0.0;
    double totalSaldoFavor = 0.0;

    for (final map in maps) {
      totalVentas += map['ventasGravadas'];
      totalCompras18 += map['compras18'];
      totalCompras10 += map['compras10'];
      totalIgvPagado += map['igvPorPagar'];
      if (map['tieneSaldoAFavor'] == 1) {
        totalSaldoFavor += map['saldoAFavor'];
      }
    }

    return {
      'mes': inicioMes.month,
      'año': inicioMes.year,
      'total_calculos': maps.length,
      'total_ventas': totalVentas,
      'total_compras_18': totalCompras18,
      'total_compras_10': totalCompras10,
      'total_igv_pagado': totalIgvPagado,
      'total_saldo_favor': totalSaldoFavor,
    };
  }

  // Limpiar historial (eliminar todos los registros)
  static Future<void> limpiarHistorial() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    await db.delete('historial_igv');
  }

  // Obtener el último cálculo realizado
  static Future<HistorialIGV?> obtenerUltimoCalculo() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      orderBy: 'fechaCalculo DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return HistorialIGV.fromMap(maps.first);
    }

    return null;
  }

  // Obtener las ventas del último cálculo realizado
  static Future<double> obtenerUltimasVentas() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_igv',
      columns: ['ventasGravadas'],
      orderBy: 'fechaCalculo DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['ventasGravadas']?.toDouble() ?? 0.0;
    }

    return 0.0;
  }
}
