import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/cards/dashboard_card.dart';
import '../../widgets/compulsa_appbar.dart';
import '../../services/historial_igv_service.dart';
import '../../services/historial_renta_service.dart';
import '../../models/historial_igv.dart';
import '../../models/historial_renta.dart';
import 'estadisticas_empresariales_screen.dart';
import 'evolucion_mensual_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  // ===========================================================================
  // State Variables & Lifecycle
  // ===========================================================================
  List<HistorialIGV> _historialIGV = [];
  List<HistorialRenta> _historialRenta = [];
  Map<String, dynamic>? _resumenIGV;
  Map<String, dynamic>? _resumenRenta;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ===========================================================================
  // Main Build Method
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompulsaAppBar(title: 'Reportes'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis Tributario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildAnalysisSection(),
            const SizedBox(height: 24),
            const Text(
              'Reportes Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportsSection(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // UI Section Builders
  // ===========================================================================

  /// Builds the summary card for IGV analysis or a loading indicator.
  Widget _buildAnalysisSection() {
    if (_cargandoDatos) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando datos...'),
              ],
            ),
          ),
        ),
      );
    }

    final resumen = _resumenIGV;
    final ultimoSaldo = resumen?['ultimo_saldo'] ?? 0.0;
    final totalCalculos = resumen?['total_calculos'] ?? 0;
    final totalIgvPagado = resumen?['total_igv_pagado'] ?? 0.0;
    final totalSaldoFavor = resumen?['total_saldo_favor'] ?? 0.0;
    // Total de Renta pagada en todos los periodos
    final totalRentaPagada = (_resumenRenta != null)
        ? ((_resumenRenta!['total_a_pagar'] ?? 0.0) as num).toDouble()
        : 0.0;

    // Cálculos derivados para resumen general adicional
    final totalVentasAll = _historialIGV.fold<double>(
      0.0,
      (sum, h) => sum + (h.ventasGravadas),
    );
    final totalComprasAll = _historialIGV.fold<double>(
      0.0,
      (sum, h) => sum + (h.compras18 + h.compras10),
    );
    final cantIgv = _historialIGV.length;
    final promedioCompras = cantIgv > 0 ? (totalComprasAll / cantIgv) : 0.0;
    final cantRenta = _historialRenta.length;
    final promedioRenta = cantRenta > 0
        ? (_historialRenta.fold<double>(0.0, (s, r) => s + r.rentaPorPagar) /
              cantRenta)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Saldo a Favor Actual',
                    'S/ ${ultimoSaldo.toStringAsFixed(2)}',
                    ultimoSaldo > 0
                        ? AppColors.saldoFavorColor
                        : AppColors.igvColor,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'IGV acumulado Pagado',
                    'S/ ${totalIgvPagado.toStringAsFixed(2)}',
                    AppColors.igvColor,
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Meses Calculados',
                    totalCalculos.toString(),
                    AppColors.primary,
                    Icons.calculate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Renta acumulada Pagada',
                    'S/ ${totalRentaPagada.toStringAsFixed(2)}',
                    AppColors.secondary,
                    Icons.account_balance,
                  ),
                ),
              ],
            ),

            // Resumen ampliado: totales/medias a través de todos los periodos
          ],
        ),
      ),
    );
  }

  /// Builds the list of available report cards.
  Widget _buildReportsSection() {
    return Column(
      children: [
        DashboardCard(
          icon: Icons.pie_chart,
          title: 'Resumen General',
          subtitle: 'IGV y Renta de tu empresa',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EstadisticasEmpresarialesScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DashboardCard(
          icon: Icons.trending_up,
          title: 'Evolución Mensual',
          subtitle: 'Tendencia de impuestos',
          color: AppColors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EvolucionMensualScreen()),
          ),
        ),
        const SizedBox(height: 12),
        DashboardCard(
          icon: Icons.account_balance,
          title: 'Historial de Cálculos IGV',
          subtitle: 'Registro de todos los cálculos de IGV realizados',
          color: AppColors.saldoFavorColor,
          onTap: () => _handleShowHistoryIGV(),
        ),
        const SizedBox(height: 12),
        DashboardCard(
          icon: Icons.assignment,
          title: 'Historial de Cálculos Renta',
          subtitle: 'Registro de todos los cálculos de Renta realizados',
          color: AppColors.igvColor,
          onTap: () => _handleShowHistoryRenta(),
        ),
      ],
    );
  }

  // ===========================================================================
  // UI Component Builders
  // ===========================================================================

  Widget _buildMetricCard(
    String titulo,
    String valor,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialIgvCard(HistorialIGV calculo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calculo.fechaFormateada,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: calculo.tieneSaldoAFavor
                              ? AppColors.saldoFavorColor.withOpacity(0.1)
                              : AppColors.igvColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          calculo.tipoNegocioFormatted,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: calculo.tieneSaldoAFavor
                                ? AppColors.saldoFavorColor
                                : AppColors.igvColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handleDeleteIgvItem(calculo),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  tooltip: 'Eliminar cálculo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Ventas',
                    'S/ ${calculo.ventasGravadas.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Compras',
                    'S/ ${(calculo.compras18 + calculo.compras10).toStringAsFixed(2)}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: calculo.tieneSaldoAFavor
                    ? AppColors.saldoFavorColor.withOpacity(0.1)
                    : AppColors.igvColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    calculo.resumenCalculo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: calculo.tieneSaldoAFavor
                          ? AppColors.saldoFavorColor
                          : AppColors.igvColor,
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

  Widget _buildHistorialRentaCard(HistorialRenta calculo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calculo.fechaFormateada,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: calculo.debePagar
                              ? AppColors.igvColor.withOpacity(0.1)
                              : AppColors.saldoFavorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          calculo.regimenFormatted,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: calculo.debePagar
                                ? AppColors.igvColor
                                : AppColors.saldoFavorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handleDeleteRentaItem(calculo),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  tooltip: 'Eliminar cálculo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Ingresos',
                    'S/ ${calculo.ingresos.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Gastos',
                    'S/ ${calculo.gastos.toStringAsFixed(2)}',
                    Icons.trending_down,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: calculo.debePagar
                    ? AppColors.igvColor.withOpacity(0.1)
                    : calculo.tienePerdida
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.saldoFavorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    calculo.resumenCalculo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: calculo.debePagar
                          ? AppColors.igvColor
                          : calculo.tienePerdida
                          ? Colors.orange[700]
                          : AppColors.saldoFavorColor,
                    ),
                  ),
                  if (calculo.usandoCoeficiente)
                    Text(
                      'Con coeficiente',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A reusable widget for displaying a small detail item with a label, value, and icon.
  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Core Logic & Data Handlers
  // ===========================================================================

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargandoDatos = true);
    try {
      final igvData = await Future.wait([
        HistorialIGVService.obtenerTodosLosCalculos(),
        HistorialIGVService.obtenerResumenReciente(),
      ]);
      final rentaData = await Future.wait([
        HistorialRentaService.obtenerHistorial(),
        HistorialRentaService.obtenerEstadisticas(),
      ]);

      if (mounted) {
        setState(() {
          _historialIGV = igvData[0] as List<HistorialIGV>;
          _resumenIGV = igvData[1] as Map<String, dynamic>;
          _historialRenta = rentaData[0] as List<HistorialRenta>;
          _resumenRenta = rentaData[1] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargandoDatos = false);
      }
    }
  }

  /// Generic handler to execute a task with loading/success/error feedback.
  Future<void> _executeTaskWithFeedback({
    required Future<void> Function() task,
    required String loadingMessage,
    required String successMessage,
    Function? optimisticUpdate,
  }) async {
    if (!mounted) return;

    // Perform optimistic update if provided
    if (optimisticUpdate != null) {
      setState(() => optimisticUpdate());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(loadingMessage),
          ],
        ),
        duration: const Duration(seconds: 5), // Keep it visible during the task
      ),
    );

    try {
      await task();
      await _cargarDatos(); // Refresh all data to ensure consistency

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await _cargarDatos(); // Revert state by reloading from source on error
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // Deletion Handlers
  // ===========================================================================

  Future<void> _handleDeleteIgvItem(HistorialIGV calculo) async {
    final bool? confirmed = await _showConfirmationDialog(
      title: 'Eliminar Cálculo IGV',
      content:
          '¿Estás seguro de que deseas eliminar el cálculo del ${calculo.fechaFormateada}?',
    );

    if (confirmed == true) {
      _executeTaskWithFeedback(
        task: () => HistorialIGVService.eliminarCalculo(calculo.id),
        loadingMessage: 'Eliminando cálculo...',
        successMessage: 'Cálculo eliminado correctamente.',
        optimisticUpdate: () =>
            _historialIGV.removeWhere((item) => item.id == calculo.id),
      );
    }
  }

  Future<void> _handleDeleteRentaItem(HistorialRenta calculo) async {
    final bool? confirmed = await _showConfirmationDialog(
      title: 'Eliminar Cálculo Renta',
      content:
          '¿Estás seguro de que deseas eliminar el cálculo del ${calculo.fechaFormateada}?',
    );
    if (confirmed == true) {
      _executeTaskWithFeedback(
        task: () => HistorialRentaService.eliminarCalculo(calculo.id),
        loadingMessage: 'Eliminando cálculo...',
        successMessage: 'Cálculo eliminado correctamente.',
        optimisticUpdate: () =>
            _historialRenta.removeWhere((item) => item.id == calculo.id),
      );
    }
  }

  Future<void> _handleClearIgvHistory() async {
    final bool? confirmed = await _showConfirmationDialog(
      title: 'Limpiar Historial IGV',
      content:
          '¿Estás seguro de que deseas eliminar TODOS los ${_historialIGV.length} cálculos de IGV? Esta acción no se puede deshacer.',
    );
    if (confirmed == true) {
      Navigator.pop(context); // Close options modal before showing snackbar
      _executeTaskWithFeedback(
        task: HistorialIGVService.limpiarHistorial,
        loadingMessage: 'Limpiando historial de IGV...',
        successMessage: 'Historial de IGV eliminado.',
        optimisticUpdate: () => _historialIGV.clear(),
      );
    }
  }

  Future<void> _handleClearRentaHistory() async {
    final bool? confirmed = await _showConfirmationDialog(
      title: 'Limpiar Historial Renta',
      content:
          '¿Estás seguro de que deseas eliminar TODOS los ${_historialRenta.length} cálculos de Renta? Esta acción no se puede deshacer.',
    );
    if (confirmed == true) {
      Navigator.pop(context); // Close options modal
      _executeTaskWithFeedback(
        task: HistorialRentaService.eliminarTodos,
        loadingMessage: 'Limpiando historial de Renta...',
        successMessage: 'Historial de Renta eliminado.',
        optimisticUpdate: () => _historialRenta.clear(),
      );
    }
  }

  // ===========================================================================
  // Modal & Dialog Handlers
  // ===========================================================================

  void _handleShowHistoryIGV() {
    _showHistoryModal(
      title: 'Historial de Cálculos IGV',
      icon: Icons.account_balance,
      iconColor: AppColors.saldoFavorColor,
      historyList: _historialIGV,
      itemBuilder: (context, index) =>
          _buildHistorialIgvCard(_historialIGV[index]),
      onClearAll: _handleClearIgvHistory,
      emptyState: _buildEmptyState(
        icon: Icons.history_toggle_off,
        message: 'No hay cálculos de IGV registrados.',
      ),
    );
  }

  void _handleShowHistoryRenta() {
    _showHistoryModal(
      title: 'Historial de Cálculos Renta',
      icon: Icons.assignment,
      iconColor: AppColors.igvColor,
      historyList: _historialRenta,
      itemBuilder: (context, index) =>
          _buildHistorialRentaCard(_historialRenta[index]),
      onClearAll: _handleClearRentaHistory,
      emptyState: _buildEmptyState(
        icon: Icons.assignment_outlined,
        message: 'No hay cálculos de Renta registrados.',
      ),
    );
  }

  /// Generic function to show a draggable modal bottom sheet for a history list.
  void _showHistoryModal({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<dynamic> historyList,
    required Widget Function(BuildContext, int) itemBuilder,
    required VoidCallback onClearAll,
    required Widget emptyState,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (historyList.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearHistoryOptions(onClearAll),
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Opciones',
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: historyList.isEmpty
                    ? emptyState
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: historyList.length,
                        itemBuilder: itemBuilder,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryOptions(VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Limpiar todo el historial'),
            onTap: onConfirm,
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancelar'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
