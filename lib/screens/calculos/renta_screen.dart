import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../services/calculo_service.dart';
import '../../services/database_service.dart';
import '../../services/actividad_reciente_service.dart';
import '../../services/historial_igv_service.dart';
import '../../models/regimen_tributario.dart';
import '../../widgets/compulsa_appbar.dart';

class RentaScreen extends StatefulWidget {
  const RentaScreen({super.key});

  @override
  State<RentaScreen> createState() => _RentaScreenState();
}

class _RentaScreenState extends State<RentaScreen> {
  final _ingresosController = TextEditingController();
  final _gastosController = TextEditingController();
  final _coeficienteController = TextEditingController();
  
  // Nuevos controladores para cálculo de coeficiente
  final _impuesto2023Controller = TextEditingController();
  final _ingresos2023Controller = TextEditingController();
  double? _coeficienteCalculado;
  
  int? _regimenSeleccionado;
  Map<String, dynamic>? _resultadoCalculo;
  bool _isCalculating = false;
  
  List<RegimenTributario> _regimenes = [];
  bool _cargandoRegimenes = true;
  
  // Nuevos campos para manejo de coeficientes MYPE
  bool _mostrarOpcionesMyPE = false;
  bool _usarCoeficiente = false;
  Map<String, dynamic>? _opcionesMyPE;

  @override
  void initState() {
    super.initState();
    _cargarRegimenes();
    _cargarUltimasVentas();
  }

  Future<void> _cargarRegimenes() async {
    try {
      final regimenes = await DatabaseService().obtenerRegimenes();
      setState(() {
        _regimenes = regimenes;
        _cargandoRegimenes = false;
        // Seleccionar el primer régimen por defecto
        if (_regimenes.isNotEmpty) {
          _regimenSeleccionado = _regimenes.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _cargandoRegimenes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar regímenes: $e')),
        );
      }
    }
  }

  // Función para calcular coeficiente automáticamente
  void _calcularCoeficienteAutomatico() {
    final impuesto2023 = double.tryParse(_impuesto2023Controller.text) ?? 0.0;
    final ingresos2023 = double.tryParse(_ingresos2023Controller.text) ?? 0.0;
    
    if (impuesto2023 > 0 && ingresos2023 > 0) {
      final coeficiente = impuesto2023 / ingresos2023;
      setState(() {
        _coeficienteCalculado = coeficiente;
        // Actualizar el campo de coeficiente con el resultado
        _coeficienteController.text = (coeficiente * 100).toStringAsFixed(4);
      });
      
      // Recalcular las opciones MYPE con el nuevo coeficiente
      if (_opcionesMyPE != null) {
        final nuevasOpciones = RegimenTributario.calcularTasaMyPE(
          ingresos: double.tryParse(_ingresosController.text) ?? 0.0,
          gastosDeducibles: double.tryParse(_gastosController.text) ?? 0.0,
          coeficientePersonalizado: coeficiente,
        );
        setState(() {
          _opcionesMyPE = nuevasOpciones;
          _usarCoeficiente = true; // Activar automáticamente el uso del coeficiente
        });
      }
    } else {
      setState(() {
        _coeficienteCalculado = null;
        _coeficienteController.clear();
      });
    }
  }

  // Cargar las ventas del último cálculo de IGV
  Future<void> _cargarUltimasVentas() async {
    try {
      final ultimasVentas = await HistorialIGVService.obtenerUltimasVentas();
      if (mounted && ultimasVentas > 0) {
        setState(() {
          _ingresosController.text = ultimasVentas.toStringAsFixed(2);
        });
        
        // Mostrar un mensaje informativo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se cargaron automáticamente las ventas del último cálculo de IGV: S/ ${ultimasVentas.toStringAsFixed(2)}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Limpiar',
              textColor: Colors.white,
              onPressed: () {
                _ingresosController.clear();
              },
            ),
          ),
        );
      }
    } catch (e) {
      // En caso de error, no hacer nada - el campo queda vacío
      print('Error al cargar últimas ventas: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompulsaAppBar(
        title: 'Impuesto a la Renta',
      ),
      body: _cargandoRegimenes 
        ? const Center(child: CircularProgressIndicator())
        : _regimenes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Cargando regímenes tributarios',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por favor espere mientras se cargan los regímenes disponibles',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text(
              'Cálculo del Impuesto a la Renta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _cargandoRegimenes 
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<int>(
                  initialValue: _regimenSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Régimen Tributario',
                  ),
                  items: _regimenes.map((regimen) {
                    return DropdownMenuItem<int>(
                      value: regimen.id,
                      child: Text(_obtenerTextoRegimen(regimen)),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _regimenSeleccionado = newValue!;
                      _resultadoCalculo = null; // Limpiar resultado anterior
                    });
                    _verificarOpcionesMYPE(); // Verificar opciones MYPE al cambiar régimen
                  },
                ),
            const SizedBox(height: 16),
            
            // Indicador de tasa MYPE cuando aplique
            if (_mostrarOpcionesMyPE && _opcionesMyPE != null)
              _buildIndicadorTasaMYPE(),
            
            if (_mostrarOpcionesMyPE && _opcionesMyPE != null)
              const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _ingresosController.text.isNotEmpty 
                      ? AppColors.success.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_ingresosController.text.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Datos cargados del último cálculo de IGV',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _ingresosController.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Limpiar',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      top: _ingresosController.text.isNotEmpty ? 8 : 12,
                    ),
                    child: TextFormField(
                      controller: _ingresosController,
                      decoration: InputDecoration(
                        labelText: 'Ingresos del Período',
                        hintText: _ingresosController.text.isEmpty 
                            ? 'Ingrese los ingresos totales o calculará con ventas de IGV'
                            : 'Ingrese los ingresos totales',
                        prefixText: 'S/ ',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        labelStyle: TextStyle(
                          color: _ingresosController.text.isNotEmpty 
                              ? AppColors.success
                              : Colors.grey[600],
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          // Actualizar la UI cuando cambie el valor
                        });
                        _verificarOpcionesMYPE();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de coeficiente personalizado (solo para MYPE con ingresos altos)
            if (_mostrarOpcionesMyPE && _regimenSeleccionado != null)
              _buildCampoCoeficiente(),
            
            if (_mostrarOpcionesMyPE && _regimenSeleccionado != null)
              const SizedBox(height: 16),
            
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calcularRenta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rentaColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCalculating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Calcular Impuesto a la Renta'),
              ),
            ),
            const SizedBox(height: 24),
            if (_resultadoCalculo != null) _buildResultadoCard(),
          ],
        ),
      ),
    );
  }
  
  // Método para obtener el texto dinámico del régimen en el dropdown
  String _obtenerTextoRegimen(RegimenTributario regimen) {
    // Si es MYPE y hay opciones calculadas, mostrar la tasa dinámica
    if (regimen.nombre.toUpperCase().contains('MYPE') && _opcionesMyPE != null) {
      final tasaActual = (_opcionesMyPE!['tasa'] * 100).toStringAsFixed(1);
      final tipoCalculo = _opcionesMyPE!['tipo'];
      
      String descripcionTasa;
      switch (tipoCalculo) {
        case 'basica':
          descripcionTasa = '1.0% - Básica';
          break;
        case 'automatico':
          descripcionTasa = '1.5% - Automático';
          break;
        case 'coeficiente_menor':
          descripcionTasa = '${tasaActual}% - Coeficiente';
          break;
        case 'limitado_maximo':
          descripcionTasa = '1.5% - Limitado';
          break;
        default:
          descripcionTasa = '${tasaActual}%';
      }
      
      return '${regimen.nombre} (${descripcionTasa})';
    }
    
    // Para otros regímenes o cuando no hay opciones MYPE, mostrar tasa fija
    return '${regimen.nombre} (${regimen.tasaRentaFormateada})';
  }
  
  // Método para verificar automáticamente si se deben mostrar opciones MYPE
  void _verificarOpcionesMYPE() {
    if (_regimenSeleccionado == null) return;
    
    final ingresos = double.tryParse(_ingresosController.text) ?? 0.0;
    final gastos = double.tryParse(_gastosController.text) ?? 0.0;
    
    // Obtener el régimen seleccionado
    final regimenSeleccionado = _regimenes.firstWhere((r) => r.id == _regimenSeleccionado);
    
    // Solo procesar si es MYPE y los ingresos superan el límite
    if (regimenSeleccionado.nombre.toUpperCase().contains('MYPE') && ingresos > RegimenTributario.limiteMyeBasico) {
      // Calcular opciones de MYPE automáticamente
      final opciones = RegimenTributario.calcularTasaMyPE(
        ingresos: ingresos,
        gastosDeducibles: gastos,
        coeficientePersonalizado: double.tryParse(_coeficienteController.text),
      );
      
      setState(() {
        _opcionesMyPE = opciones;
        _mostrarOpcionesMyPE = true;
        // ✨ Aplicar automáticamente la lógica: si hay coeficiente personalizado, usarlo
        _usarCoeficiente = opciones['coeficientePersonalizado'] == true;
        // El dropdown se actualizará automáticamente gracias a _obtenerTextoRegimen
      });
    } else {
      // Si no es MYPE o no supera el límite, ocultar opciones
      setState(() {
        _mostrarOpcionesMyPE = false;
        _opcionesMyPE = null;
        _usarCoeficiente = false;
        // El dropdown volverá a mostrar la tasa fija del régimen
      });
    }
  }
  
  Future<void> _calcularRenta() async {
    final ingresos = double.tryParse(_ingresosController.text) ?? 0.0;
    final gastos = double.tryParse(_gastosController.text) ?? 0.0;
    
    if (ingresos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un monto de ingresos válido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Las opciones MYPE ya se calculan automáticamente en _verificarOpcionesMYPE()
    final regimenSeleccionado = _regimenes.firstWhere((r) => r.id == _regimenSeleccionado);

    setState(() {
      _isCalculating = true;
    });

    try {
      final resultado = await CalculoService.calcularRenta(
        ingresos: ingresos,
        gastos: gastos,
        regimenId: _regimenSeleccionado!,
        coeficientePersonalizado: double.tryParse(_coeficienteController.text),
        usarCoeficiente: _usarCoeficiente,
      );

      if (!mounted) return;
      
      // Registrar actividad reciente
      await ActividadRecienteService.registrarCalculoRenta(
        ingresos: ingresos,
        impuesto: resultado['impuesto_renta'] ?? 0.0,
        regimenNombre: regimenSeleccionado.nombre,
      );
      
      setState(() {
        _resultadoCalculo = resultado;
        _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  Widget _buildResultadoCard() {
    if (_resultadoCalculo == null) return const SizedBox();
    
    final resultado = _resultadoCalculo!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado del Cálculo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildResultadoItem('Ingresos (Ventas)', resultado['ingresos']),
            _buildResultadoItem('Gastos Deducibles', resultado['gastos']),
            _buildResultadoItem('Renta Neta', resultado['renta_neta']),
            if (resultado['base_imponible'] != null && resultado['base_imponible'] != resultado['renta_neta'])
              _buildResultadoItem('Base Imponible', resultado['base_imponible']),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resultado['tipo_calculo'] ?? 'Cálculo estándar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            _buildResultadoItem(
              'Impuesto a la Renta (${(resultado['tasa_renta']).toStringAsFixed(1)}%)', 
              resultado['impuesto_renta'], 
              isTotal: true,
            ),
            if (resultado['perdida'] > 0)
              _buildResultadoItem('Pérdida', resultado['perdida'], isError: true),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: resultado['debe_pagar'] 
                    ? AppColors.rentaColor.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    resultado['debe_pagar'] ? 'Total a Pagar' : 'Sin Impuesto por Pagar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: resultado['debe_pagar'] ? AppColors.rentaColor : AppColors.success,
                    ),
                  ),
                  if (resultado['debe_pagar'])
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        FormatUtils.formatearMoneda(resultado['renta_por_pagar']),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.rentaColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultadoItem(String label, double valor, {bool isTotal = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isError ? AppColors.error : (isTotal ? AppColors.textPrimary : AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FormatUtils.formatearMoneda(valor),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: isError ? AppColors.error : (isTotal ? AppColors.rentaColor : AppColors.textPrimary),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicadorTasaMYPE() {
    if (_opcionesMyPE == null) return const SizedBox();
    
    final tasa = (_opcionesMyPE!['tasa'] * 100).toStringAsFixed(1);
    final tipo = _opcionesMyPE!['tipo'];
    final descripcion = _opcionesMyPE!['descripcion'];
    
    Color colorFondo;
    Color colorTexto;
    IconData icono;
    String titulo;
    
    switch (tipo) {
      case 'basica':
        colorFondo = Colors.blue;
        colorTexto = Colors.blue;
        icono = Icons.trending_down;
        titulo = 'Tasa Básica MYPE';
        break;
      case 'automatico':
        colorFondo = Colors.orange;
        colorTexto = Colors.orange;
        icono = Icons.auto_mode;
        titulo = 'Tasa Automática MYPE';
        break;
      case 'coeficiente_menor':
        colorFondo = Colors.green;
        colorTexto = Colors.green;
        icono = Icons.calculate;
        titulo = 'Coeficiente Aplicado';
        break;
      case 'limitado_maximo':
        colorFondo = AppColors.warning;
        colorTexto = AppColors.warning;
        icono = Icons.shield;
        titulo = 'Tasa Limitada';
        break;
      default:
        colorFondo = Colors.grey;
        colorTexto = Colors.grey;
        icono = Icons.info;
        titulo = 'Tasa MYPE';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorFondo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorFondo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorFondo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icono,
                  size: 18,
                  color: colorTexto,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorTexto,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasa}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCampoCoeficiente() {
    if (_opcionesMyPE == null) return const SizedBox();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
        color: AppColors.warning.withOpacity(0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coeficiente MYPE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _opcionesMyPE!['descripcion'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (_opcionesMyPE!['tipo'] == 'opcional') ...[
              Text(
                'Coeficiente calculado: ${(_opcionesMyPE!['coeficiente'] * 100).toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text(
                        '1.5% fijo',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: false,
                      groupValue: _usarCoeficiente,
                      onChanged: (bool? value) {
                        setState(() {
                          _usarCoeficiente = value ?? false;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(
                        'Coeficiente ${(_opcionesMyPE!['coeficiente'] * 100).toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: true,
                      groupValue: _usarCoeficiente,
                      onChanged: (bool? value) {
                        setState(() {
                          _usarCoeficiente = value ?? false;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            if (_opcionesMyPE!['tipo'] != 'basica') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _coeficienteController,
                decoration: const InputDecoration(
                  labelText: 'Coeficiente Personalizado (opcional)',
                  hintText: 'Ingrese coeficiente decimal (ej: 0.12 para 12%)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  helperText: 'Deje vacío para usar el coeficiente calculado',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final coef = double.tryParse(value);
                  if (coef != null && coef > 0) {
                    final nuevasOpciones = RegimenTributario.calcularTasaMyPE(
                      ingresos: double.tryParse(_ingresosController.text) ?? 0.0,
                      gastosDeducibles: double.tryParse(_gastosController.text) ?? 0.0,
                      coeficientePersonalizado: coef / 100,
                    );
                    setState(() {
                      _opcionesMyPE = nuevasOpciones;
                      _usarCoeficiente = true; // Activar automáticamente el uso del coeficiente
                    });
                  } else {
                    // Si no hay coeficiente válido, recalcular opciones
                    _verificarOpcionesMYPE();
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildCalculadorCoeficiente(),
            ],
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _mostrarDialogoOpcionesMYPE(Map<String, dynamic> opciones) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('Opciones de Cálculo MYPE'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sus ingresos superan S/ ${RegimenTributario.limiteMyeBasico.toStringAsFixed(0)}. '
                'Puede elegir entre:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Tasa fija: 1.5%',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Cálculo sencillo sobre la renta neta',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2. Coeficiente: ${(opciones['coeficiente'] * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Basado en sus gastos deducibles',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Recomendación: Use el coeficiente ya que es menor (${(opciones['coeficiente'] * 100).toStringAsFixed(2)}% < 1.5%)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _usarCoeficiente = false;
                });
                Navigator.of(context).pop();
                _continuarCalculo();
              },
              child: const Text('Usar 1.5%'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _usarCoeficiente = true;
                });
                Navigator.of(context).pop();
                _continuarCalculo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: Text('Usar Coeficiente ${(opciones['coeficiente'] * 100).toStringAsFixed(2)}%'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _continuarCalculo() async {
    final ingresos = double.tryParse(_ingresosController.text) ?? 0.0;
    final gastos = double.tryParse(_gastosController.text) ?? 0.0;

    setState(() {
      _isCalculating = true;
    });

    try {
      final resultado = await CalculoService.calcularRenta(
        ingresos: ingresos,
        gastos: gastos,
        regimenId: _regimenSeleccionado!,
        coeficientePersonalizado: double.tryParse(_coeficienteController.text),
        usarCoeficiente: _usarCoeficiente,
      );

      if (!mounted) return;
      
      // Registrar actividad reciente
      final regimenSeleccionado = _regimenes.firstWhere((r) => r.id == _regimenSeleccionado);
      await ActividadRecienteService.registrarCalculoRenta(
        ingresos: ingresos,
        impuesto: resultado['impuesto_renta'] ?? 0.0,
        regimenNombre: regimenSeleccionado.nombre,
      );
      
      setState(() {
        _resultadoCalculo = resultado;
        _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ingresosController.dispose();
    _gastosController.dispose();
    _coeficienteController.dispose();
    _impuesto2023Controller.dispose();
    _ingresos2023Controller.dispose();
    super.dispose();
  }

  // Widget para calcular coeficiente basado en datos del año anterior
  Widget _buildCalculadorCoeficiente() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        color: AppColors.secondary.withOpacity(0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Calculadora de Coeficiente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Calcula automáticamente tu coeficiente usando los datos del año 2023',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impuesto Calculado del año pasado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _impuesto2023Controller,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixText: 'S/ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (value) => _calcularCoeficienteAutomatico(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingresos Netos del año pasado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _ingresos2023Controller,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixText: 'S/ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (value) => _calcularCoeficienteAutomatico(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_coeficienteCalculado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coeficiente Calculado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${(_coeficienteCalculado! * 100).toStringAsFixed(4)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Fórmula: ${_impuesto2023Controller.text} ÷ ${_ingresos2023Controller.text}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'El coeficiente se aplicará automáticamente al campo de coeficiente personalizado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}