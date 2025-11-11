class AppConstants {
  // Configuración de la aplicación
  static const String appName = 'Compulsa';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Asistente Tributario Inteligente para Perú';

  // Tasas tributarias
  static const double tasaIGV = 0.18; // 18%
  static const double tasaRentaGeneral = 0.01; // 29.5%
  static const double tasaRentaMYPE = 0.01; // 10%
  static const double tasaRentaEspecial = 0.15; // 15%

  // Fechas límite (pueden cambiar anualmente)
  static const int diaLimitePresentacion =
      12; // Día límite para presentar declaraciones

  // Formatos de fecha
  static const String formatoFecha = 'dd/MM/yyyy';
  static const String formatoFechaHora = 'dd/MM/yyyy HH:mm';
  static const String formatoMes = 'MMMM yyyy';

  // Configuración de base de datos
  static const String nombreBaseDatos = 'compulsa.db';
  static const int versionBaseDatos = 1;

  // Límites y validaciones
  static const int minLongitudRUC = 11;
  static const int maxLongitudRUC = 11;
  static const double montoMinimoIGV = 0.01;
  static const double montoMaximoDeclaracion = 999999999.99;

  // Mensajes
  static const String mensajeCalculoExitoso = 'Cálculo realizado correctamente';
  static const String mensajeDeclaracionGuardada =
      'Declaración guardada exitosamente';
  static const String mensajeEmpresaGuardada =
      'Empresa registrada correctamente';
  static const String mensajeErrorGenerico =
      'Ha ocurrido un error. Inténtelo nuevamente.';

  // Códigos de formularios SUNAT
  static const String formularioIGV = '621';
  static const String formularioRentaMensual = '616';
  static const String formularioRentaAnual = '710';

  // Periodos de declaración
  static const List<String> mesesDelAno = [
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

  // Tipos de comprobantes
  static const List<String> tiposComprobante = [
    'Factura',
    'Boleta de Venta',
    'Nota de Crédito',
    'Nota de Débito',
    'Recibo por Honorarios',
    'Ticket',
  ];

  // Estados predefinidos
  static const List<String> estadosDeclaracion = [
    'Borrador',
    'Pendiente',
    'Presentada',
    'Observada',
    'Cancelada',
  ];

  // Colores para estados (códigos hex)
  static const String colorExitoso = '#4CAF50';
  static const String colorAdvertencia = '#FF9800';
  static const String colorError = '#F44336';
  static const String colorInformacion = '#2196F3';

  // URLs útiles (pueden cambiar)
  static const String urlSUNAT = 'https://www.sunat.gob.pe';
  static const String urlSOL =
      'https://www.sunat.gob.pe/cl-ti-itmrconsruc/frameconsruc.jsp';
  static const String urlConsultaRUC = 'https://www.sunat.gob.pe/ficha-ruc';

  // Configuración de backup
  static const int diasBackupAutomatico = 7;
  static const String carpetaBackup = 'backups';
}
