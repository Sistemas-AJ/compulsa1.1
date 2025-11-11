import 'package:flutter/services.dart';

/// Formateador básico que solo valida formato de número pero no interfiere
class NumberInputFormatter extends TextInputFormatter {
  final int decimales;

  NumberInputFormatter({
    this.decimales = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permitir texto vacío
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Solo validaciones muy básicas
    String texto = newValue.text;
    
    // Permitir números, comas y un punto decimal
    if (!RegExp(r'^[\d,]*\.?\d*$').hasMatch(texto)) {
      return oldValue;
    }

    // Validar máximo un punto decimal
    int puntos = texto.split('.').length - 1;
    if (puntos > 1) {
      return oldValue;
    }

    // Si hay punto decimal, validar decimales
    if (texto.contains('.')) {
      String parteDecimal = texto.split('.')[1];
      if (parteDecimal.length > decimales) {
        return oldValue;
      }
    }

    // Devolver el texto tal como está, sin modificaciones
    return newValue;
  }
}

/// Formateador específico para montos en soles peruanos
class MoneyInputFormatter extends NumberInputFormatter {
  MoneyInputFormatter({int decimales = 2})
      : super(
          decimales: decimales,
        );
}

/// Formateador para coeficientes (porcentajes)
class CoefficientInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Validar formato de porcentaje
    String textoLimpio = newValue.text.replaceAll('%', '');
    
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(textoLimpio)) {
      return oldValue;
    }

    double? valor = double.tryParse(textoLimpio);
    if (valor != null && valor > 100) {
      return oldValue; // No permitir más de 100%
    }

    return newValue;
  }
}