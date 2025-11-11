import '../models/historial_renta.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class HistorialRentaService {
  // Crear tabla si no existe
  static Future<void> _crearTabla() async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial_renta (
        id TEXT PRIMARY KEY,
        fechaCalculo TEXT NOT NULL,
        regimenNombre TEXT NOT NULL,
        regimenEnum TEXT NOT NULL,
        ingresos REAL NOT NULL,
        gastos REAL NOT NULL,
        rentaNeta REAL NOT NULL,
        baseImponible REAL NOT NULL,
        impuestoRenta REAL NOT NULL,
        rentaPorPagar REAL NOT NULL,
        perdida REAL NOT NULL,
        tasaRenta REAL NOT NULL,
        tipoCalculo TEXT NOT NULL,
        debePagar INTEGER NOT NULL,
        tienePerdida INTEGER NOT NULL,
        observaciones TEXT,
        coeficientePersonalizado REAL,
        usandoCoeficiente INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Guardar un cálculo de Renta
  static Future<void> guardarCalculo(HistorialRenta historial) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    await db.insert(
      'historial_renta',
      historial.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener el último cálculo realizado
  static Future<HistorialRenta?> obtenerUltimoCalculo() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_renta',
      orderBy: 'fechaCalculo DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return HistorialRenta.fromMap(maps.first);
    }

    return null;
  }

  // Obtener todos los cálculos ordenados por fecha (más reciente primero)
  static Future<List<HistorialRenta>> obtenerHistorial({int? limite}) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_renta',
      orderBy: 'fechaCalculo DESC',
      limit: limite,
    );

    return List.generate(maps.length, (i) {
      return HistorialRenta.fromMap(maps[i]);
    });
  }

  // Obtener cálculos por régimen
  static Future<List<HistorialRenta>> obtenerPorRegimen(
    String regimenNombre,
  ) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_renta',
      where: 'regimenNombre = ?',
      whereArgs: [regimenNombre],
      orderBy: 'fechaCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return HistorialRenta.fromMap(maps[i]);
    });
  }

  // Obtener cálculos por período
  static Future<List<HistorialRenta>> obtenerPorPeriodo({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historial_renta',
      where: 'fechaCalculo BETWEEN ? AND ?',
      whereArgs: [fechaInicio.toIso8601String(), fechaFin.toIso8601String()],
      orderBy: 'fechaCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return HistorialRenta.fromMap(maps[i]);
    });
  }

  // Eliminar un cálculo por ID
  static Future<void> eliminarCalculo(String id) async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    // Verificar si el registro existe antes de eliminar
    final existingRecords = await db.query(
      'historial_renta',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingRecords.isEmpty) {
      throw Exception('No se encontró el cálculo de renta con ID: $id');
    }

    final deletedRows = await db.delete(
      'historial_renta',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedRows == 0) {
      throw Exception('No se pudo eliminar el cálculo de renta');
    }
  }

  // Eliminar todos los cálculos
  static Future<void> eliminarTodos() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    await db.delete('historial_renta');
  }

  // Obtener estadísticas básicas
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    // Contar total de registros
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM historial_renta',
    );
    final total = totalResult.first['total'] as int;

    if (total == 0) {
      return {
        'total_calculados': 0,
        'total_a_pagar': 0.0,
        'promedio_tasa': 0.0,
        'ultimo_calculo': null,
      };
    }

    // Obtener suma total a pagar
    final sumaResult = await db.rawQuery(
      'SELECT SUM(rentaPorPagar) as suma FROM historial_renta WHERE debePagar = 1',
    );
    final totalAPagar = (sumaResult.first['suma'] as double?) ?? 0.0;

    // Obtener promedio de tasa
    final promedioResult = await db.rawQuery(
      'SELECT AVG(tasaRenta) as promedio FROM historial_renta',
    );
    final promedioTasa = (promedioResult.first['promedio'] as double?) ?? 0.0;

    // Obtener último cálculo
    final ultimoCalculo = await obtenerUltimoCalculo();

    return {
      'total_calculados': total,
      'total_a_pagar': totalAPagar,
      'promedio_tasa': promedioTasa,
      'ultimo_calculo': ultimoCalculo?.fechaCalculo.toIso8601String(),
    };
  }

  // Obtener el total a pagar de todos los cálculos activos (donde debePagar = true)
  static Future<double> obtenerTotalAPagar() async {
    await _crearTabla();
    final dbService = DatabaseService();
    final db = await dbService.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(rentaPorPagar) as total FROM historial_renta WHERE debePagar = 1',
    );

    if (maps.isNotEmpty && maps.first['total'] != null) {
      return (maps.first['total'] as double);
    }

    return 0.0;
  }

  // Obtener el último impuesto calculado
  static Future<double> obtenerUltimoImpuesto() async {
    final ultimoCalculo = await obtenerUltimoCalculo();
    return ultimoCalculo?.rentaPorPagar ?? 0.0;
  }
}
