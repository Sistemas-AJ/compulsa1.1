import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/compulsa_appbar.dart';
import '../../models/declaracion.dart';
import '../../services/declaracion_service.dart';

class DeclaracionesScreen extends StatefulWidget {
  const DeclaracionesScreen({super.key});

  @override
  State<DeclaracionesScreen> createState() => _DeclaracionesScreenState();
}

class _DeclaracionesScreenState extends State<DeclaracionesScreen> {
  final DeclaracionService _declaracionService = DeclaracionService();
  List<Declaracion> _declaraciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDeclaraciones();
  }

  Future<void> _cargarDeclaraciones() async {
    setState(() => _cargando = true);

    try {
      final declaraciones = await _declaracionService.obtenerDeclaraciones();
      setState(() {
        _declaraciones = declaraciones;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar declaraciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CompulsaAppBar(
        title: 'Declaraciones',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDeclaraciones,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navegación a formulario de declaración
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Declaración'),
      ),
    );
  }

  Widget _buildContent() {
    if (_declaraciones.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _declaraciones.length,
      itemBuilder: (context, index) {
        final declaracion = _declaraciones[index];
        return _buildDeclaracionCard(declaracion);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay declaraciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera declaración tocando el botón +',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '🚧 Esta sección está en desarrollo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclaracionCard(Declaracion declaracion) {
    final tipoColor = declaracion.tipo == TipoDeclaracion.igv
        ? AppColors.igvColor
        : AppColors.rentaColor;

    final estadoColor = _getEstadoColor(declaracion.estado);
    final estadoText = _getEstadoText(declaracion.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tipoColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    declaracion.tipo.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: estadoColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estadoText,
                    style: TextStyle(
                      fontSize: 12,
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  declaracion.id,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('MMMM yyyy', 'es').format(declaracion.periodo),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Creado: ${DateFormat('dd/MM/yyyy').format(declaracion.fechaCreacion)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tipoColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tipoColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: tipoColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Monto a pagar:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'S/ ${declaracion.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tipoColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previsualizarPDF(declaracion),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarPDF(declaracion),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Descargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _compartirPDF(declaracion),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Compartir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previsualizarPDF(Declaracion declaracion) async {
    try {
      await _declaracionService.previsualizarPDF(declaracion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al previsualizar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _descargarPDF(Declaracion declaracion) async {
    try {
      await _declaracionService.generarPDF(declaracion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF guardado exitosamente'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => _previsualizarPDF(declaracion),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _compartirPDF(Declaracion declaracion) async {
    try {
      await _declaracionService.compartirPDF(declaracion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getEstadoColor(EstadoDeclaracion estado) {
    switch (estado) {
      case EstadoDeclaracion.borrador:
        return Colors.grey;
      case EstadoDeclaracion.pendiente:
        return Colors.orange;
      case EstadoDeclaracion.presentada:
        return Colors.green;
      case EstadoDeclaracion.observada:
        return Colors.red;
      case EstadoDeclaracion.cancelada:
        return Colors.red.shade300;
    }
  }

  String _getEstadoText(EstadoDeclaracion estado) {
    switch (estado) {
      case EstadoDeclaracion.borrador:
        return 'Borrador';
      case EstadoDeclaracion.pendiente:
        return 'Pendiente';
      case EstadoDeclaracion.presentada:
        return 'Presentada';
      case EstadoDeclaracion.observada:
        return 'Observada';
      case EstadoDeclaracion.cancelada:
        return 'Cancelada';
    }
  }
}
