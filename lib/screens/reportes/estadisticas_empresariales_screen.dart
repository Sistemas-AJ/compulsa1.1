import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/historial_igv_service.dart';
import '../../models/historial_igv.dart';

class EstadisticasEmpresarialesScreen extends StatefulWidget {
  const EstadisticasEmpresarialesScreen({super.key});

  @override
  State<EstadisticasEmpresarialesScreen> createState() =>
      _EstadisticasEmpresarialesScreenState();
}

class _EstadisticasEmpresarialesScreenState
    extends State<EstadisticasEmpresarialesScreen>
    with TickerProviderStateMixin {
  List<HistorialIGV> _historialIGV = [];
  Map<String, dynamic> _estadisticasMensuales = {};
  bool _cargandoDatos = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final historial = await HistorialIGVService.obtenerTodosLosCalculos();
      final estadisticas =
          await HistorialIGVService.obtenerEstadisticasMensuales();

      if (mounted) {
        setState(() {
          _historialIGV = historial;
          _estadisticasMensuales = estadisticas;
          _cargandoDatos = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
      }
      print('Error al cargar estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Estadísticas Empresariales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _cargarDatos(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _cargandoDatos
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando datos del negocio...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCards(),
                    const SizedBox(height: 24),
                    _buildVentasChart(),
                    const SizedBox(height: 24),
                    _buildIgvChart(),
                    const SizedBox(height: 24),
                    _buildRentabilidadSection(),
                    const SizedBox(height: 24),
                    _buildTendenciaSection(),
                    const SizedBox(height: 24),
                    _buildComparativaSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCards() {
    final totalVentas = _estadisticasMensuales['total_ventas'] ?? 0.0;
    final totalCalculos = _estadisticasMensuales['total_calculos'] ?? 0;
    final totalIgvPagado = _estadisticasMensuales['total_igv_pagado'] ?? 0.0;
    final promedioVentas = totalCalculos > 0
        ? totalVentas / totalCalculos
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Ventas Totales',
                'S/ ${_formatMonto(totalVentas)}',
                Icons.trending_up,
                Colors.green,
                'Este mes',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'IGV pagado',
                'S/ ${_formatMonto(totalIgvPagado)}',
                Icons.receipt,
                AppColors.igvColor,
                'Última operación',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Promedio por Operación',
                'S/ ${_formatMonto(promedioVentas)}',
                Icons.analytics,
                AppColors.primary,
                'Rendimiento',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Operaciones',
                totalCalculos.toString(),
                Icons.calculate,
                AppColors.secondary,
                'Total mes',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    String subtitulo,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Icon(icono, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasChart() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolución de Ventas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Últimas operaciones registradas',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildBarChart(_getVentasData(), Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildIgvChart() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.igvColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.igvColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis de IGV',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'IGV pagado vs Saldos a favor',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildBarChart(_getIgvData(), AppColors.igvColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<ChartData> data, Color color) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No hay datos suficientes',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final height = maxValue > 0 ? (item.value / maxValue) * 120 : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Valor
                if (item.value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'S/ ${_formatMonto(item.value)}',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                // Barra
                AnimatedContainer(
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  width: double.infinity,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Etiqueta
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRentabilidadSection() {
    final totalVentas = _estadisticasMensuales['total_ventas'] ?? 0.0;
    final totalCompras =
        _estadisticasMensuales['total_compras_18'] ??
        0.0 + _estadisticasMensuales['total_compras_10'] ??
        0.0;
    final margenBruto = totalVentas - totalCompras;
    final porcentajeMargen = totalVentas > 0
        ? (margenBruto / totalVentas) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Análisis de Rentabilidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRentabilidadItem(
                  'Ventas Totales',
                  totalVentas,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildRentabilidadItem(
                  'Compras Totales',
                  totalCompras,
                  Colors.orange,
                  Icons.shopping_cart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: margenBruto >= 0
                    ? [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ]
                    : [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Margen Bruto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: margenBruto >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    Text(
                      'S/ ${_formatMonto(margenBruto.abs())}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: margenBruto >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Porcentaje de Margen',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '${porcentajeMargen.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: margenBruto >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentabilidadItem(
    String titulo,
    double valor,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            'S/ ${_formatMonto(valor)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTendenciaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Estado del Negocio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildIndicadorNegocio(),
        ],
      ),
    );
  }

  Widget _buildIndicadorNegocio() {
    final totalCalculos = _estadisticasMensuales['total_calculos'] ?? 0;
    final totalVentas = _estadisticasMensuales['total_ventas'] ?? 0.0;

    String estado;
    Color colorEstado;
    IconData iconoEstado;
    String mensaje;

    if (totalCalculos == 0) {
      estado = 'Sin Actividad';
      colorEstado = Colors.grey;
      iconoEstado = Icons.pause_circle_outline;
      mensaje = 'Aún no hay cálculos registrados este mes';
    } else if (totalVentas > 50000) {
      estado = 'Excelente';
      colorEstado = Colors.green;
      iconoEstado = Icons.trending_up;
      mensaje = 'El negocio está generando muy buenas ventas';
    } else if (totalVentas > 20000) {
      estado = 'Bueno';
      colorEstado = Colors.blue;
      iconoEstado = Icons.thumb_up;
      mensaje = 'Rendimiento positivo del negocio';
    } else if (totalVentas > 5000) {
      estado = 'Regular';
      colorEstado = Colors.orange;
      iconoEstado = Icons.trending_flat;
      mensaje = 'Hay potencial de crecimiento';
    } else {
      estado = 'Inicial';
      colorEstado = Colors.red;
      iconoEstado = Icons.trending_down;
      mensaje = 'Enfócate en aumentar las ventas';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorEstado.withOpacity(0.1), colorEstado.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorEstado.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconoEstado, color: colorEstado, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado: $estado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorEstado,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensaje,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comparativa Rápida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparativaItem(
            'Operaciones realizadas',
            (_estadisticasMensuales['total_calculos'] ?? 0).toString(),
            'cálculos',
            Icons.calculate,
            AppColors.primary,
          ),
          _buildComparativaItem(
            'Promedio por operación',
            'S/ ${_formatMonto((_estadisticasMensuales['total_ventas'] ?? 0.0) / ((_estadisticasMensuales['total_calculos'] ?? 1) as num))}',
            'por cálculo',
            Icons.analytics,
            Colors.green,
          ),
          _buildComparativaItem(
            'IGV promedio',
            'S/ ${_formatMonto((_estadisticasMensuales['total_igv_pagado'] ?? 0.0) / ((_estadisticasMensuales['total_calculos'] ?? 1) as num))}',
            'por operación',
            Icons.receipt,
            AppColors.igvColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComparativaItem(
    String titulo,
    String valor,
    String subtitulo,
    IconData icono,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<ChartData> _getVentasData() {
    if (_historialIGV.isEmpty) return [];

    // Tomar los últimos 6 cálculos para el gráfico
    final ultimos = _historialIGV.take(6).toList().reversed.toList();
    return ultimos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final calculo = entry.value;
      return ChartData('Op $index', calculo.ventasGravadas);
    }).toList();
  }

  List<ChartData> _getIgvData() {
    if (_historialIGV.isEmpty) return [];

    // Tomar los últimos 6 cálculos para el gráfico
    final ultimos = _historialIGV.take(6).toList().reversed.toList();
    return ultimos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final calculo = entry.value;
      final igvValue = calculo.tieneSaldoAFavor ? 0.0 : calculo.igvPorPagar;
      return ChartData('Op $index', igvValue);
    }).toList();
  }

  String _formatMonto(double monto) {
    return monto
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}
