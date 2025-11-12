import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../services/calculo_service.dart';
import '../../services/historial_igv_service.dart';
import '../../services/actividad_reciente_service.dart';
import '../../widgets/compulsa_appbar.dart';

class IgvScreen extends StatefulWidget {
  const IgvScreen({super.key});

  @override
  State<IgvScreen> createState() => _IgvScreenState();
}

enum TipoNegocio { general, restauranteHotel }

class _IgvScreenState extends State<IgvScreen> with TickerProviderStateMixin {
  final TextEditingController _ventasGravadasController =
      TextEditingController();
  final TextEditingController _compras18Controller = TextEditingController();
  final TextEditingController _compras10Controller = TextEditingController();
  final TextEditingController _saldoAnteriorController =
      TextEditingController();

  TipoNegocio? _tipoNegocioSeleccionado; // Cambiado a nullable
  Map<String, dynamic>? _resultadoCalculo;
  bool _calculando = false;
  late AnimationController _formAnimationController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    );
    _cargarSaldoAnterior();
  }

  // Cargar el saldo anterior del último cálculo
  Future<void> _cargarSaldoAnterior() async {
    try {
      final saldoAnterior = await CalculoService.obtenerSaldoAnterior();
      if (mounted) {
        setState(() {
          _saldoAnteriorController.text = saldoAnterior > 0
              ? saldoAnterior.toStringAsFixed(2)
              : '';
        });
      }
    } catch (e) {
      // En caso de error, mantener el campo vacío
      print('Error al cargar saldo anterior: $e');
    }
  }

  @override
  void dispose() {
    _ventasGravadasController.dispose();
    _compras18Controller.dispose();
    _compras10Controller.dispose();
    _saldoAnteriorController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  Future<void> _calcularIgv() async {
    if (_tipoNegocioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione el tipo de negocio'),
        ),
      );
      return;
    }

    if (_ventasGravadasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese las ventas gravadas')),
      );
      return;
    }

    // Validar que se ingrese al menos un tipo de compra
    if (_compras18Controller.text.isEmpty &&
        _compras10Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingrese al menos un tipo de compras (18% o 10%)',
          ),
        ),
      );
      return;
    }

    // Verificar si ya existe un cálculo en el mes actual
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    try {
      final existentes = await HistorialIGVService.obtenerCalculosPorPeriodo(
        desde: inicioMes,
        hasta: finMes,
      );
      if (existentes.isNotEmpty) {
        final deseaActualizar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cálculo existente este mes'),
            content: const Text(
              'Ya existe un cálculo de IGV registrado para este mes. ¿Deseas actualizar los datos reemplazando el cálculo existente?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        );

        if (deseaActualizar != true) {
          return; // Usuario canceló
        }
      }
    } catch (_) {
      // Si hay error en la verificación, permitimos continuar
    }

    setState(() {
      _calculando = true;
    });

    try {
      final ventasGravadas = double.parse(_ventasGravadasController.text);
      final compras18 = _compras18Controller.text.isNotEmpty
          ? double.parse(_compras18Controller.text)
          : 0.0;
      final compras10 = _compras10Controller.text.isNotEmpty
          ? double.parse(_compras10Controller.text)
          : 0.0;
      final saldoAnterior = _saldoAnteriorController.text.isEmpty
          ? 0.0
          : double.parse(_saldoAnteriorController.text);

      final resultado = await CalculoService.calcularIgvPorTipo(
        ventasGravadas: ventasGravadas,
        compras18: compras18,
        compras10: compras10,
        saldoAnterior: saldoAnterior,
        tipoNegocio: _tipoNegocioSeleccionado,
      );

      if (!mounted) return;

      // Registrar actividad reciente
      await ActividadRecienteService.registrarCalculoIGV(
        baseImponible: ventasGravadas,
        igv: resultado['igv_por_pagar'] ?? resultado['saldo_a_favor'] ?? 0.0,
      );

      setState(() {
        _resultadoCalculo = resultado;
        _calculando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _calculando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en el cálculo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CompulsaAppBar(title: 'Cálculo de IGV'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.calculate_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Calculadora IGV',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ingrese los datos para calcular el IGV de manera precisa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Business Type Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildBusinessTypeSelector(),
            ),

            const SizedBox(height: 24),

            // Form Section - Solo se muestra si hay tipo seleccionado
            if (_tipoNegocioSeleccionado != null)
              AnimatedBuilder(
                animation: _formAnimation,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transform: Matrix4.identity()
                      ..translate(0.0, 20 * (1 - _formAnimation.value))
                      ..scale(_formAnimation.value),
                    child: Opacity(
                      opacity: _formAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildModernFormField(
                              controller: _ventasGravadasController,
                              label: 'Ventas Gravadas',
                              subtitle:
                                  _tipoNegocioSeleccionado ==
                                      TipoNegocio.general
                                  ? 'Monto base de ventas gravadas (IGV 18%)'
                                  : 'Monto base de ventas gravadas (IGV 10%)',
                              icon: Icons.trending_up,
                              color: Colors.green,
                              isRequired: true,
                            ),
                            const SizedBox(height: 20),

                            // Siempre mostrar ambos campos de compras para cualquier tipo de negocio
                            _buildModernFormField(
                              controller: _compras18Controller,
                              label: 'Compras 18%',
                              subtitle:
                                  'Monto base de compras con IGV 18% - Opcional',
                              icon: Icons.shopping_cart,
                              color: Colors.blue,
                              isRequired: false,
                            ),
                            const SizedBox(height: 20),

                            _buildModernFormField(
                              controller: _compras10Controller,
                              label: 'Compras 10%',
                              subtitle:
                                  'Monto base de compras con IGV 10% - Opcional',
                              icon: Icons.shopping_bag,
                              color: Colors.orange,
                              isRequired: false,
                            ),
                            const SizedBox(height: 20),

                            _buildSaldoAnteriorField(),
                            const SizedBox(height: 32),

                            // Calculate Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    offset: const Offset(0, 8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _calculando ? null : _calcularIgv,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _calculando
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.calculate,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Calcular IGV',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Mensaje de instrucciones cuando no hay tipo seleccionado
            if (_tipoNegocioSeleccionado == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecciona tu tipo de negocio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Elige el tipo de negocio para aplicar la tasa correcta en ventas. Puedes registrar compras con ambas tasas (18% y 10%) independientemente del tipo.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (_resultadoCalculo != null) _buildProfessionalResultCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFormField({
    required TextEditingController controller,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
                prefixText: 'S/. ',
                prefixStyle: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalResultCard() {
    final resultado = _resultadoCalculo!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 8),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resultado del Cálculo IGV',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          resultado['tipo_negocio'] ?? 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'IGV Ventas',
                          resultado['igv_ventas'],
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'IGV Compras',
                          resultado['total_igv_compras'],
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Detailed Table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: IntrinsicWidth(
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'CONCEPTO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'BASE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'IGV',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Rows
                              _buildProfessionalTableRow(
                                'VENTAS',
                                resultado['ventas_gravadas'],
                                resultado['igv_ventas'],
                                Colors.green,
                              ),
                              _buildProfessionalTableRow(
                                'COMPRAS 18%',
                                resultado['compras_18'],
                                resultado['igv_compras_18'],
                                Colors.blue,
                              ),
                              if ((resultado['compras_10'] as double) > 0)
                                _buildProfessionalTableRow(
                                  'COMPRAS 10%',
                                  resultado['compras_10'],
                                  resultado['igv_compras_10'],
                                  Colors.orange,
                                ),

                              // Calculation Result
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'CÁLCULO DEL IGV',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 100),
                                    SizedBox(
                                      width: 100,
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: _buildAmountChip(
                                          _formatMonto(
                                            resultado['calculo_igv'],
                                          ),
                                          Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Previous Balance
                              if ((resultado['saldo_anterior'] as double) > 0)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey[200]!),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'SALDO ANTERIOR',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      SizedBox(width: 100),
                                      SizedBox(
                                        width: 100,
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: _buildAmountChip(
                                            _formatMonto(
                                              resultado['saldo_anterior'],
                                            ),
                                            Colors.purple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Final Result
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: resultado['tiene_saldo_a_favor']
                                        ? [Colors.red[50]!, Colors.red[100]!]
                                        : [
                                            Colors.green[50]!,
                                            Colors.green[100]!,
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: resultado['tiene_saldo_a_favor']
                                            ? Colors.red[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        resultado['tiene_saldo_a_favor']
                                            ? Icons.trending_down
                                            : Icons.trending_up,
                                        color: resultado['tiene_saldo_a_favor']
                                            ? Colors.red[700]
                                            : Colors.green[700],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            resultado['tiene_saldo_a_favor']
                                                ? 'SALDO A FAVOR'
                                                : 'IGV POR PAGAR',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color:
                                                  resultado['tiene_saldo_a_favor']
                                                  ? Colors.red[700]
                                                  : Colors.green[700],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            resultado['tiene_saldo_a_favor']
                                                ? 'Tienes un saldo a favor'
                                                : 'Monto a pagar este período',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'S/. ${resultado['tiene_saldo_a_favor'] ? _formatMonto(resultado['saldo_a_favor']) : _formatMonto(resultado['igv_por_pagar'])}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              resultado['tiene_saldo_a_favor']
                                              ? Colors.red[700]
                                              : Colors.green[700],
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'S/. ${_formatMonto(amount)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTableRow(
    String concepto,
    double base,
    double igv,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    concepto,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  base > 0 ? _formatMonto(base) : '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              alignment: Alignment.center,
              child: _buildAmountChip(_formatMonto(igv), color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(String amount, Color color) {
    return Container(
      width: 90,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Negocio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seleccione el tipo de negocio para aplicar la tasa de IGV correcta en ventas',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBusinessTypeOption(
                    TipoNegocio.general,
                    'General',
                    'Ventas IGV 18%',
                    Icons.store,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBusinessTypeOption(
                    TipoNegocio.restauranteHotel,
                    'Restaurante/Hotel',
                    'Ventas IGV 10%',
                    Icons.restaurant,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTypeOption(
    TipoNegocio tipo,
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
  ) {
    final isSelected = _tipoNegocioSeleccionado == tipo;

    return GestureDetector(
      onTap: () {
        setState(() {
          final bool esPrimerSeleccion = _tipoNegocioSeleccionado == null;
          _tipoNegocioSeleccionado = tipo;

          // Solo limpiar ventas y resultado al cambiar tipo de negocio
          // Las compras y saldo anterior se mantienen
          _ventasGravadasController.clear();
          _resultadoCalculo = null;

          // Activar animación si es la primera selección
          if (esPrimerSeleccion) {
            _formAnimationController.forward();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icono, color: isSelected ? color : Colors.grey[600], size: 24),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonto(double monto) {
    // Validar que el número sea válido
    if (monto.isNaN || monto.isInfinite) {
      return '0';
    }

    // Para números muy grandes (más de 100 millones), usar formato compacto
    if (monto.abs() >= 100000000) {
      double millones = monto / 1000000;
      String formatted = millones.toStringAsFixed(millones % 1 == 0 ? 0 : 1);
      return '${formatted}M';
    }
    // Para números grandes (más de 10 millones), usar formato compacto
    else if (monto.abs() >= 10000000) {
      double millones = monto / 1000000;
      String formatted = millones.toStringAsFixed(1);
      return '${formatted}M';
    }
    // Para números medianos (más de 100,000), usar formato compacto
    else if (monto.abs() >= 100000) {
      double miles = monto / 1000;
      String formatted = miles.toStringAsFixed(miles % 1 == 0 ? 0 : 1);
      return '${formatted}K';
    }
    // Para números normales, mostrar con separadores de miles
    else {
      return FormatUtils.formatearNumeroConSeparadores(monto, decimales: 0);
    }
  }

  // Crear campo especial para saldo anterior con información adicional
  Widget _buildSaldoAnteriorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Anterior',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _saldoAnteriorController.text.isNotEmpty &&
                                  double.parse(_saldoAnteriorController.text) >
                                      0
                              ? 'Saldo a favor del último cálculo: S/ ${FormatUtils.formatearNumeroConSeparadores(_saldoAnteriorController.text, decimales: 2)}'
                              : 'No hay saldo anterior disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_saldoAnteriorController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _saldoAnteriorController.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saldo anterior eliminado'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Limpiar saldo anterior',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _saldoAnteriorController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // Actualizar la UI cuando cambie el valor
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Se carga automáticamente del último cálculo. Puede modificarlo si es necesario.',
                      style: TextStyle(
                        fontSize: 11,
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
      ],
    );
  }
}
