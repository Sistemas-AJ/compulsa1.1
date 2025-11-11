import '../models/actividad_reciente.dart';
import 'database_service.dart';

class ActividadRecienteService {
  static final _database = DatabaseService();

  /// Registra una nueva actividad
  static Future<void> registrarActividad(ActividadReciente actividad) async {
    try {
      await _database.insertarActividad(actividad);
      // Limpiar actividades antiguas cada vez que se registra una nueva
      await _database.limpiarActividadesAntiguas();
    } catch (e) {
      print('Error al registrar actividad: $e');
    }
  }

  /// Obtiene las actividades recientes
  static Future<List<ActividadReciente>> obtenerActividades({
    int limite = 10,
  }) async {
    try {
      return await _database.obtenerActividadesRecientes(limite: limite);
    } catch (e) {
      print('Error al obtener actividades: $e');
      return [];
    }
  }

  /// Elimina una actividad específica
  static Future<void> eliminarActividad(int id) async {
    try {
      await _database.eliminarActividadReciente(id);
    } catch (e) {
      print('Error al eliminar actividad: $e');
    }
  }

  /// Registra actividad de cálculo de renta
  static Future<void> registrarCalculoRenta({
    required double ingresos,
    required double impuesto,
    required String regimenNombre,
  }) async {
    final actividad = ActividadReciente.calculoRenta(
      ingresos: ingresos,
      impuesto: impuesto,
      regimenNombre: regimenNombre,
    );
    await registrarActividad(actividad);
  }

  /// Registra actividad de cálculo de IGV
  static Future<void> registrarCalculoIGV({
    required double baseImponible,
    required double igv,
  }) async {
    final actividad = ActividadReciente.calculoIGV(
      baseImponible: baseImponible,
      igv: igv,
    );
    await registrarActividad(actividad);
  }

  /// Registra actividad de creación de régimen
  static Future<void> registrarRegimenCreado({
    required String nombre,
    required double tasaRenta,
  }) async {
    final actividad = ActividadReciente.regimenCreado(
      nombre: nombre,
      tasaRenta: tasaRenta,
    );
    await registrarActividad(actividad);
  }

  /// Registra actividad de configuración de empresa
  static Future<void> registrarEmpresaConfigurada({
    required String razonSocial,
    required String ruc,
  }) async {
    final actividad = ActividadReciente.empresaConfigurada(
      razonSocial: razonSocial,
      ruc: ruc,
    );
    await registrarActividad(actividad);
  }

  /// Formatea la fecha de la actividad
  static String formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
