import '../constants/app_constants.dart';

class FormatUtils {
  // Formatear moneda peruana con separadores de miles
  static String formatearMoneda(double monto) {
    return 'S/ ${formatearNumeroConSeparadores(monto, decimales: 2)}';
  }

  // Formatear moneda compacta para números muy grandes
  static String formatearMonedaCompacta(double monto) {
    if (monto >= 1000000000) {
      return 'S/ ${(monto / 1000000000).toStringAsFixed(1)}B';
    } else if (monto >= 1000000) {
      return 'S/ ${(monto / 1000000).toStringAsFixed(1)}M';
    } else if (monto >= 1000) {
      return 'S/ ${(monto / 1000).toStringAsFixed(1)}K';
    }
    return formatearMoneda(monto);
  }

  // Formatear número con separadores de miles
  static String formatearNumeroConSeparadores(dynamic numero, {int decimales = 2}) {
    double valor = 0.0;
    if (numero is String) {
      valor = double.tryParse(numero) ?? 0.0;
    } else if (numero is double) {
      valor = numero;
    } else if (numero is int) {
      valor = numero.toDouble();
    }

    // Separar parte entera y decimal
    String numeroStr = valor.toStringAsFixed(decimales);
    List<String> partes = numeroStr.split('.');
    String parteEntera = partes[0];
    String parteDecimal = partes.length > 1 ? partes[1] : '';

    // Agregar separadores de miles
    String resultado = '';
    for (int i = 0; i < parteEntera.length; i++) {
      if (i > 0 && (parteEntera.length - i) % 3 == 0) {
        resultado += ',';
      }
      resultado += parteEntera[i];
    }

    if (decimales > 0 && parteDecimal.isNotEmpty) {
      resultado += '.$parteDecimal';
    }

    return resultado;
  }

  // Limpiar formato de número (remover separadores)
  static String limpiarFormatoNumero(String numeroFormateado) {
    return numeroFormateado.replaceAll(',', '').replaceAll('S/ ', '');
  }

  // Formatear porcentaje
  static String formatearPorcentaje(double porcentaje, {int decimales = 1}) {
    return '${porcentaje.toStringAsFixed(decimales)}%';
  }

  // Formatear RUC con guiones
  static String formatearRUC(String ruc) {
    if (ruc.length != AppConstants.maxLongitudRUC) {
      return ruc;
    }
    return '${ruc.substring(0, 2)}-${ruc.substring(2, 10)}-${ruc.substring(10)}';
  }

  // Capitalizar primera letra
  static String capitalizarPrimera(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

  // Obtener nombre del mes
  static String obtenerNombreMes(int mes) {
    if (mes < 1 || mes > 12) return '';
    return AppConstants.mesesDelAno[mes - 1];
  }

  // Obtener período formateado
  static String formatearPeriodo(DateTime fecha) {
    return '${obtenerNombreMes(fecha.month)} ${fecha.year}';
  }
}

class ValidationUtils {
  // Validar RUC peruano
  static bool validarRUC(String ruc) {
    if (ruc.length != AppConstants.maxLongitudRUC) return false;
    if (!RegExp(r'^\d+$').hasMatch(ruc)) return false;

    // Validación específica de RUC peruano
    final factores = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    int suma = 0;

    for (int i = 0; i < 10; i++) {
      suma += int.parse(ruc[i]) * factores[i];
    }

    int residuo = suma % 11;
    int digitoVerificador = residuo < 2 ? residuo : 11 - residuo;

    return digitoVerificador == int.parse(ruc[10]);
  }

  // Validar email
  static bool validarEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validar campo requerido
  static String? validarCampoRequerido(String? valor, String nombreCampo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El campo $nombreCampo es requerido';
    }
    return null;
  }
}

class DateUtils {
  // Obtener primer día del mes
  static DateTime primerDiaDelMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, 1);
  }

  // Obtener último día del mes
  static DateTime ultimoDiaDelMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month + 1, 0);
  }

  // Obtener fecha límite de presentación
  static DateTime fechaLimiteDeclaracion(DateTime periodo) {
    // El día límite es el 12 del mes siguiente
    final mesSiguiente = DateTime(
      periodo.year,
      periodo.month + 1,
      AppConstants.diaLimitePresentacion,
    );
    return mesSiguiente;
  }

  // Verificar si está vencido
  static bool estaVencido(DateTime periodo) {
    final fechaLimite = fechaLimiteDeclaracion(periodo);
    return DateTime.now().isAfter(fechaLimite);
  }

  // Generar lista de períodos para dropdown
  static List<DateTime> generarPeriodos({int mesesAtras = 12}) {
    final ahora = DateTime.now();
    final periodos = <DateTime>[];

    for (int i = 0; i < mesesAtras; i++) {
      final periodo = DateTime(ahora.year, ahora.month - i, 1);
      periodos.add(periodo);
    }

    return periodos;
  }
}
