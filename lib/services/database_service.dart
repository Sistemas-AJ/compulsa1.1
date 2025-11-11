import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/database_models.dart';
import '../models/regimen_tributario.dart';
import '../models/actividad_reciente.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Método para resetear la base de datos forzando una nueva creación
  Future<void> resetDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'Compulsa.db');

      // Eliminar la base de datos existente
      await deleteDatabase(path);
      print('Base de datos eliminada y será recreada');

      // Reinicializar
      _database = await _initDatabase();
    } catch (e) {
      print('Error al resetear base de datos: $e');
    }
  }

  Future<Database> _initDatabase() async {
    // No inicializar sqflite_ffi aquí, ya se hace en main.dart

    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'Compulsa.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Crear tabla Regimenes_Tributarios
    await db.execute('''
      CREATE TABLE Regimenes_Tributarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        tasa_renta REAL NOT NULL,
        tasa_igv REAL NOT NULL DEFAULT 18.0
      )
    ''');

    // Crear tabla Empresas
    await db.execute('''
      CREATE TABLE Empresas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        regimen_id INTEGER NOT NULL,
        nombre_razon_social TEXT NOT NULL,
        ruc TEXT UNIQUE,
        imagen_perfil TEXT,
        FOREIGN KEY (regimen_id) REFERENCES Regimenes_Tributarios (id)
      )
    ''');

    // Crear tabla Liquidaciones_Mensuales
    await db.execute('''
      CREATE TABLE Liquidaciones_Mensuales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empresa_id INTEGER NOT NULL,
        periodo TEXT NOT NULL,
        total_ventas_netas REAL NOT NULL,
        total_compras_netas REAL NOT NULL,
        igv_resultante REAL NOT NULL,
        renta_calculada REAL NOT NULL,
        UNIQUE(empresa_id, periodo),
        FOREIGN KEY (empresa_id) REFERENCES Empresas (id) ON DELETE CASCADE
      )
    ''');

    // Crear tabla Saldos_Fiscales
    await db.execute('''
      CREATE TABLE Saldos_Fiscales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empresa_id INTEGER NOT NULL,
        periodo TEXT NOT NULL,
        monto_saldo_igv REAL NOT NULL DEFAULT 0,
        monto_saldo_renta REAL NOT NULL DEFAULT 0,
        origen TEXT,
        UNIQUE(empresa_id, periodo),
        FOREIGN KEY (empresa_id) REFERENCES Empresas (id) ON DELETE CASCADE
      )
    ''');

    // Crear tabla Pagos_Realizados
    await db.execute('''
      CREATE TABLE Pagos_Realizados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        liquidacion_id INTEGER NOT NULL,
        tipo_impuesto TEXT NOT NULL,
        monto_pagado REAL NOT NULL,
        fecha_pago TEXT NOT NULL,
        codigo_operacion TEXT,
        FOREIGN KEY (liquidacion_id) REFERENCES Liquidaciones_Mensuales (id)
      )
    ''');

    // Crear tabla Actividades_Recientes
    await db.execute('''
      CREATE TABLE Actividades_Recientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        datos TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        icono TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    // Crear tabla Declaraciones
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

    // Inicializar con datos por defecto si es una nueva base de datos
    await _inicializarDatosDefecto(db);
  }

  Future<void> _inicializarDatosDefecto(Database db) async {
    try {
      // Verificar si ya hay regímenes
      final List<Map<String, dynamic>> regimenes = await db.query(
        'Regimenes_Tributarios',
      );
      print('Regímenes existentes: ${regimenes.length}');

      if (regimenes.isEmpty) {
        print('Insertando regímenes predefinidos...');

        // Insertar regímenes tributarios oficiales del Perú
        await db.insert('Regimenes_Tributarios', {
          'nombre': '(NRUS)',
          'tasa_renta': 0.0,
          'tasa_igv': 0.0, // NRUS no paga IGV
        });
        print('Insertado: NRUS');

        await db.insert('Regimenes_Tributarios', {
          'nombre': '(RER)',
          'tasa_renta': 1.0, // 1.0% sobre ventas netas para RER
          'tasa_igv': 18.0, // RER paga IGV normal
        });
        print('Insertado: RER');

        await db.insert('Regimenes_Tributarios', {
          'nombre': '(MYPE)',
          'tasa_renta': 1.0, // 1.0% base para MYPE (lógica especial en código)
          'tasa_igv': 18.0, // MYPE paga IGV normal
        });
        print('Insertado: MYPE');

        await db.insert('Regimenes_Tributarios', {
          'nombre': '(General)',
          'tasa_renta': 1.5, // 1.5% para Régimen General
          'tasa_igv': 18.0, // General paga IGV normal
        });
        print('Insertado: General');

        // Verificar inserción
        final List<Map<String, dynamic>> nuevosRegimenes = await db.query(
          'Regimenes_Tributarios',
        );
        print(
          'Total regímenes después de inserción: ${nuevosRegimenes.length}',
        );
      } else {
        print('Regímenes ya existen en la base de datos');
      }
    } catch (e) {
      print('Error al inicializar datos por defecto: $e');
    }
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('Actualizando base de datos de versión $oldVersion a $newVersion');

    if (oldVersion < 2) {
      // Agregar tabla Actividades_Recientes en la versión 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Actividades_Recientes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          datos TEXT NOT NULL,
          fecha_creacion TEXT NOT NULL,
          icono TEXT NOT NULL,
          color TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Reinicializar regímenes en la versión 3
      await db.delete('Regimenes_Tributarios');
      await _inicializarDatosDefecto(db);
      // Migrar empresas existentes para usar nuevos IDs
      await _migrarEmpresasExistentes();
    }

    if (oldVersion < 4) {
      // Agregar columna tasa_igv en la versión 4
      try {
        await db.execute(
          'ALTER TABLE Regimenes_Tributarios ADD COLUMN tasa_igv REAL NOT NULL DEFAULT 18.0',
        );
        print('Columna tasa_igv agregada correctamente');

        // Actualizar tasas de IGV para regímenes existentes
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_igv': 0.0},
          where: 'nombre LIKE ?',
          whereArgs: ['%NRUS%'],
        );
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_igv': 18.0},
          where: 'nombre NOT LIKE ?',
          whereArgs: ['%NRUS%'],
        );
        print('Tasas de IGV actualizadas');
      } catch (e) {
        print('Error al agregar columna tasa_igv: $e');
        // Si falla, recrear la tabla
        await db.delete('Regimenes_Tributarios');
        await _inicializarDatosDefecto(db);
        await _migrarEmpresasExistentes();
      }
    }

    if (oldVersion < 5) {
      // Agregar columna imagen_perfil en la versión 5
      try {
        await db.execute('ALTER TABLE Empresas ADD COLUMN imagen_perfil TEXT');
        print('Columna imagen_perfil agregada correctamente');
      } catch (e) {
        print('Error al agregar columna imagen_perfil: $e');
      }
    }

    if (oldVersion < 6) {
      // Corregir tasas de renta incorrectas en la versión 6
      try {
        print('Corrigiendo tasas de renta incorrectas...');

        // Corregir tasa de MYPE de 10.0% a 1.0%
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_renta': 1.0},
          where: 'nombre LIKE ?',
          whereArgs: ['%MYPE%'],
        );

        // Corregir tasa de General de 29.5% a 1.5%
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_renta': 1.5},
          where: 'nombre LIKE ?',
          whereArgs: ['%General%'],
        );

        // Verificar que RER tenga 1.0%
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_renta': 1.0},
          where: 'nombre LIKE ?',
          whereArgs: ['%RER%'],
        );

        // Verificar que NRUS tenga 0.0%
        await db.update(
          'Regimenes_Tributarios',
          {'tasa_renta': 0.0},
          where: 'nombre LIKE ?',
          whereArgs: ['%NRUS%'],
        );

        print('Tasas de renta corregidas exitosamente');

        // Mostrar tasas actualizadas para verificación
        final regimenes = await db.query('Regimenes_Tributarios');
        for (var regimen in regimenes) {
          print('Régimen ${regimen['nombre']}: ${regimen['tasa_renta']}%');
        }
      } catch (e) {
        print('Error al corregir tasas de renta: $e');
      }
    }
  }

  // ===== MÉTODOS PARA REGÍMENES TRIBUTARIOS =====
  Future<List<RegimenTributario>> obtenerRegimenes() async {
    try {
      final db = await database;
      print('Base de datos inicializada correctamente');

      final List<Map<String, dynamic>> maps = await db.query(
        'Regimenes_Tributarios',
      );
      print('Consultando regímenes: encontrados ${maps.length}');

      if (maps.isNotEmpty) {
        for (var map in maps) {
          print('Régimen: ${map['nombre']} - Tasa: ${map['tasa_renta']}%');
        }
      }

      return List.generate(maps.length, (i) {
        return RegimenTributario(
          id: maps[i]['id'],
          nombre: maps[i]['nombre'],
          tasaRenta: maps[i]['tasa_renta'],
        );
      });
    } catch (e) {
      print('Error al obtener regímenes: $e');
      return [];
    }
  }

  Future<RegimenTributario?> obtenerRegimenPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Regimenes_Tributarios',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RegimenTributario(
        id: maps.first['id'],
        nombre: maps.first['nombre'],
        tasaRenta: maps.first['tasa_renta'],
      );
    }
    return null;
  }

  // Método para reinicializar regímenes (para debugging)
  Future<void> reinicializarRegimenes() async {
    try {
      final db = await database;
      // Eliminar todos los regímenes existentes
      await db.delete('Regimenes_Tributarios');
      print('Regímenes eliminados');

      // Insertar regímenes nuevamente
      await _inicializarDatosDefecto(db);
      print('Regímenes reinicializados');
    } catch (e) {
      print('Error al reinicializar regímenes: $e');
    }
  }

  // ===== MÉTODOS PARA EMPRESAS =====
  Future<int> insertarEmpresa(Empresa empresa) async {
    final db = await database;
    return await db.insert('Empresas', empresa.toJson());
  }

  Future<List<Empresa>> obtenerEmpresas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Empresas');

    return List.generate(maps.length, (i) {
      return Empresa.fromJson(maps[i]);
    });
  }

  Future<Empresa?> obtenerEmpresaPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Empresas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Empresa.fromJson(maps.first);
    }
    return null;
  }

  Future<int> actualizarEmpresa(Empresa empresa) async {
    final db = await database;
    return await db.update(
      'Empresas',
      empresa.toJson(),
      where: 'id = ?',
      whereArgs: [empresa.id],
    );
  }

  Future<int> eliminarEmpresa(int id) async {
    final db = await database;
    return await db.delete('Empresas', where: 'id = ?', whereArgs: [id]);
  }

  // ===== MÉTODOS PARA LIQUIDACIONES =====
  Future<int> insertarLiquidacion(LiquidacionMensual liquidacion) async {
    final db = await database;
    return await db.insert('Liquidaciones_Mensuales', liquidacion.toJson());
  }

  Future<List<LiquidacionMensual>> obtenerLiquidaciones() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Liquidaciones_Mensuales',
    );

    return List.generate(maps.length, (i) {
      return LiquidacionMensual.fromJson(maps[i]);
    });
  }

  Future<List<LiquidacionMensual>> obtenerLiquidacionesPorEmpresa(
    int empresaId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Liquidaciones_Mensuales',
      where: 'empresa_id = ?',
      whereArgs: [empresaId],
      orderBy: 'periodo DESC',
    );

    return List.generate(maps.length, (i) {
      return LiquidacionMensual.fromJson(maps[i]);
    });
  }

  // ===== MÉTODOS PARA SALDOS FISCALES =====
  Future<int> insertarSaldoFiscal(SaldoFiscal saldo) async {
    final db = await database;
    return await db.insert('Saldos_Fiscales', saldo.toJson());
  }

  Future<List<SaldoFiscal>> obtenerSaldosFiscales() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Saldos_Fiscales');

    return List.generate(maps.length, (i) {
      return SaldoFiscal.fromJson(maps[i]);
    });
  }

  // ===== MÉTODOS PARA PAGOS REALIZADOS =====
  Future<int> insertarPago(PagoRealizado pago) async {
    final db = await database;
    return await db.insert('Pagos_Realizados', pago.toJson());
  }

  Future<List<PagoRealizado>> obtenerPagos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Pagos_Realizados');

    return List.generate(maps.length, (i) {
      return PagoRealizado.fromJson(maps[i]);
    });
  }

  // ===== MÉTODOS PARA ACTIVIDADES RECIENTES =====
  Future<int> insertarActividad(ActividadReciente actividad) async {
    final db = await database;
    final data = actividad.toJson();
    data['datos'] = jsonEncode(data['datos']); // Convertir Map a JSON string
    return await db.insert('Actividades_Recientes', data);
  }

  Future<List<ActividadReciente>> obtenerActividadesRecientes({
    int limite = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Actividades_Recientes',
      orderBy: 'fecha_creacion DESC',
      limit: limite,
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['datos'] = jsonDecode(map['datos']); // Convertir JSON string a Map
      return ActividadReciente.fromJson(map);
    });
  }

  Future<void> eliminarActividadReciente(int id) async {
    final db = await database;
    await db.delete('Actividades_Recientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> limpiarActividadesAntiguas({int diasMaximos = 30}) async {
    final db = await database;
    final fechaLimite = DateTime.now().subtract(Duration(days: diasMaximos));
    await db.delete(
      'Actividades_Recientes',
      where: 'fecha_creacion < ?',
      whereArgs: [fechaLimite.toIso8601String()],
    );
  }

  // ===== MÉTODOS UTILITARIOS =====
  Future<void> cerrarDatabase() async {
    final db = await database;
    db.close();
  }

  Future<void> eliminarDatabase() async {
    try {
      // Cerrar conexión actual si existe
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'Compulsa.db');

      try {
        await deleteDatabase(path);
        print('Base de datos eliminada correctamente: $path');
      } catch (e) {
        print('Error al eliminar base de datos principal: $e');
        // Intentar eliminar archivos WAL y SHM manualmente si existen
        try {
          final walPath = '$path-wal';
          final shmPath = '$path-shm';
          // Note: En Flutter no podemos usar dart:io File directamente aquí
          // Solo reportamos el error y continuamos
          print('Archivos WAL/SHM podrían existir: $walPath, $shmPath');
        } catch (e2) {
          print('Error adicional: $e2');
        }
      }
    } catch (e) {
      print('Error general al eliminar base de datos: $e');
    }
  }

  Future<void> _migrarEmpresasExistentes() async {
    print('Iniciando migración de empresas existentes');
    final db = await database;

    try {
      // Obtener todos los regímenes válidos
      final regimenesResult = await db.query('Regimenes_Tributarios');
      final List<int> regimenesValidos = regimenesResult
          .map((r) => r['id'] as int)
          .toList();
      print('Regímenes válidos disponibles: $regimenesValidos');

      // Obtener empresas existentes
      final empresasResult = await db.query('empresas');
      print('Empresas existentes encontradas: ${empresasResult.length}');

      for (final empresa in empresasResult) {
        final empresaId = empresa['id'];
        final regimenId = empresa['regimen_tributario_id'];

        print('Procesando empresa ID: $empresaId, regimen actual: $regimenId');

        // Si el régimen no existe o es null, asignar el primero disponible (NRUS)
        if (regimenId == null || !regimenesValidos.contains(regimenId)) {
          final nuevoRegimenId = regimenesValidos.first; // NRUS por defecto
          await db.update(
            'empresas',
            {'regimen_tributario_id': nuevoRegimenId},
            where: 'id = ?',
            whereArgs: [empresaId],
          );
          print(
            'Empresa $empresaId migrada de régimen $regimenId a $nuevoRegimenId',
          );
        } else {
          print('Empresa $empresaId ya tiene régimen válido: $regimenId');
        }
      }
      print('Migración de empresas completada');
    } catch (e) {
      print('Error durante migración de empresas: $e');
    }
  }
}
