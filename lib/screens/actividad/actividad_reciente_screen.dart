import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/actividad_reciente.dart';
import '../../services/actividad_reciente_service.dart';

class ActividadRecienteScreen extends StatefulWidget {
  const ActividadRecienteScreen({super.key});

  @override
  State<ActividadRecienteScreen> createState() =>
      _ActividadRecienteScreenState();
}

class _ActividadRecienteScreenState extends State<ActividadRecienteScreen> {
  List<ActividadReciente> _actividades = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() => _cargando = true);
    try {
      final actividades = await ActividadRecienteService.obtenerActividades(
        limite: 50,
      );
      setState(() {
        _actividades = actividades;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar actividades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad Reciente'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarActividades,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _actividades.isEmpty
          ? _buildEmptyState()
          : _buildActividadesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay actividad reciente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realiza algunos cálculos o configuraciones\npara ver tu actividad aquí',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadesList() {
    return RefreshIndicator(
      onRefresh: _cargarActividades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _actividades.length,
        itemBuilder: (context, index) {
          final actividad = _actividades[index];
          return _buildActividadCard(actividad, index);
        },
      ),
    );
  }

  Widget _buildActividadCard(ActividadReciente actividad, int index) {
    final color = _hexToColor(actividad.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetalles(actividad),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getIconData(actividad.icono),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actividad.descripcion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTipoTexto(actividad.tipo),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ActividadRecienteService.formatearFecha(
                        actividad.fechaCreacion,
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Botón de opciones
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'eliminar') {
                    _eliminarActividad(actividad, index);
                  } else if (value == 'detalles') {
                    _mostrarDetalles(actividad);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detalles',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('Ver detalles'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calculate':
        return Icons.calculate;
      case 'receipt':
        return Icons.receipt;
      case 'add_business':
        return Icons.add_business;
      case 'business':
        return Icons.business;
      default:
        return Icons.history;
    }
  }

  String _getTipoTexto(String tipo) {
    switch (tipo) {
      case 'calculo_renta':
        return 'Cálculo de Impuesto a la Renta';
      case 'calculo_igv':
        return 'Cálculo de IGV';
      case 'regimen_creado':
        return 'Régimen Tributario Creado';
      case 'empresa_configurada':
        return 'Empresa Configurada';
      default:
        return 'Actividad';
    }
  }

  void _mostrarDetalles(ActividadReciente actividad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconData(actividad.icono)),
            const SizedBox(width: 8),
            const Text('Detalles'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              actividad.descripcion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Tipo: ${_getTipoTexto(actividad.tipo)}'),
            const SizedBox(height: 4),
            Text('Fecha: ${actividad.fechaCreacion}'),
            const SizedBox(height: 12),
            const Text('Datos:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...actividad.datos.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text('• ${entry.key}: ${entry.value}'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarActividad(
    ActividadReciente actividad,
    int index,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta actividad?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && actividad.id != null) {
      try {
        await ActividadRecienteService.eliminarActividad(actividad.id!);
        setState(() {
          _actividades.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Actividad eliminada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }
}
