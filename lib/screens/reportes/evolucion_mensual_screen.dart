import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/compulsa_appbar.dart';
import '../../services/historial_igv_service.dart';
import '../../services/historial_renta_service.dart';
import '../../models/historial_igv.dart';
import '../../models/historial_renta.dart';

class EvolucionMensualScreen extends StatefulWidget {
  const EvolucionMensualScreen({super.key});

  @override
  State<EvolucionMensualScreen> createState() => _EvolucionMensualScreenState();
}

class _EvolucionMensualScreenState extends State<EvolucionMensualScreen> {
  Map<String, dynamic> _datosEvolucion = {};
  bool _cargandoDatos = true;
  String _periodoSeleccionado = 'por_mes';
  String? _mesSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargandoDatos = true;
    });

    try {
      // Cargar historial completo
      final historialIGV = await HistorialIGVService.obtenerTodosLosCalculos();
      final historialRenta = await HistorialRentaService.obtenerHistorial();

      // Procesar datos para evolución
      final datosEvolucion = _procesarDatosEvolucion(
        historialIGV,
        historialRenta,
      );

      if (mounted) {
        setState(() {
          _datosEvolucion = datosEvolucion;
          _cargandoDatos = false;
          // Seleccionar mes actual por defecto para "por mes"
          try {
            final disponibles = _obtenerMesesDisponibles();
            final mesActual = _obtenerMesAno(DateTime.now());
            if (disponibles.contains(mesActual)) {
              _mesSeleccionado = mesActual;
            } else if (disponibles.isNotEmpty) {
              // Tomar el más reciente
              _mesSeleccionado = disponibles.last;
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
      }
      print('Error al cargar datos de evolución: $e');
    }
  }

  Map<String, dynamic> _procesarDatosEvolucion(
    List<HistorialIGV> igv,
    List<HistorialRenta> renta,
  ) {
    final Map<String, Map<String, double>> evolucionIGV = {};
    final Map<String, Map<String, double>> evolucionRenta = {};
    final Map<String, int> conteoCalculos = {};

    // Procesar datos de IGV
    for (final calculo in igv) {
      final mes = _obtenerMesAno(calculo.fechaCalculo);
      if (!evolucionIGV.containsKey(mes)) {
        evolucionIGV[mes] = {
          'igvPagado': 0.0,
          'saldoFavor': 0.0,
          'ventas': 0.0,
          'compras': 0.0,
        };
        conteoCalculos[mes] = 0;
      }

      evolucionIGV[mes]!['ventas'] =
          (evolucionIGV[mes]!['ventas'] ?? 0) + calculo.ventasGravadas;
      evolucionIGV[mes]!['compras'] =
          (evolucionIGV[mes]!['compras'] ?? 0) +
          calculo.compras18 +
          calculo.compras10;

      if (calculo.tieneSaldoAFavor) {
        evolucionIGV[mes]!['saldoFavor'] =
            (evolucionIGV[mes]!['saldoFavor'] ?? 0) + calculo.saldoAFavor;
      } else {
        evolucionIGV[mes]!['igvPagado'] =
            (evolucionIGV[mes]!['igvPagado'] ?? 0) + calculo.igvPorPagar;
      }

      conteoCalculos[mes] = (conteoCalculos[mes] ?? 0) + 1;
    }

    // Procesar datos de Renta
    for (final calculo in renta) {
      final mes = _obtenerMesAno(calculo.fechaCalculo);
      if (!evolucionRenta.containsKey(mes)) {
        evolucionRenta[mes] = {
          'rentaPagada': 0.0,
          'ingresos': 0.0,
          'gastos': 0.0,
          'perdidas': 0.0,
        };
      }

      evolucionRenta[mes]!['ingresos'] =
          (evolucionRenta[mes]!['ingresos'] ?? 0) + calculo.ingresos;
      evolucionRenta[mes]!['gastos'] =
          (evolucionRenta[mes]!['gastos'] ?? 0) + calculo.gastos;

      if (calculo.debePagar) {
        evolucionRenta[mes]!['rentaPagada'] =
            (evolucionRenta[mes]!['rentaPagada'] ?? 0) + calculo.rentaPorPagar;
      } else if (calculo.tienePerdida) {
        evolucionRenta[mes]!['perdidas'] =
            (evolucionRenta[mes]!['perdidas'] ?? 0) + calculo.perdida;
      }
    }

    return {
      'igv': evolucionIGV,
      'renta': evolucionRenta,
      'conteos': conteoCalculos,
    };
  }

  String _obtenerMesAno(DateTime fecha) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  List<String> _obtenerMesesFiltrados() {
    final mesesOrdenados = _obtenerMesesDisponibles();

    switch (_periodoSeleccionado) {
      case 'por_mes':
        if (_mesSeleccionado != null && mesesOrdenados.contains(_mesSeleccionado)) {
          return [_mesSeleccionado!];
        }
        return mesesOrdenados.isNotEmpty ? [mesesOrdenados.last] : [];
      case 'ultimos3meses':
        return mesesOrdenados
            .take(mesesOrdenados.length)
            .toList()
            .reversed
            .take(3)
            .toList()
            .reversed
            .toList();
      case 'ultimos6meses':
        return mesesOrdenados
            .take(mesesOrdenados.length)
            .toList()
            .reversed
            .take(6)
            .toList()
            .reversed
            .toList();
      case 'ultimo_ano':
        return mesesOrdenados
            .take(mesesOrdenados.length)
            .toList()
            .reversed
            .take(12)
            .toList()
            .reversed
            .toList();
      default:
        return mesesOrdenados;
    }
  }

  List<String> _obtenerMesesDisponibles() {
    final meses = <String>{};
    final igv = _datosEvolucion['igv'] as Map<String, dynamic>?;
    final renta = _datosEvolucion['renta'] as Map<String, dynamic>?;
    if (igv != null) meses.addAll(igv.keys);
    if (renta != null) meses.addAll(renta.keys);
    final lista = meses.toList();
    lista.sort((a, b) => _parsearMesAno(a).compareTo(_parsearMesAno(b)));
    return lista;
  }

  DateTime _parsearMesAno(String mesAno) {
    const meses = {
      'Ene': 1,
      'Feb': 2,
      'Mar': 3,
      'Abr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Ago': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dic': 12,
    };
    final partes = mesAno.split(' ');
    final mes = meses[partes[0]] ?? 1;
    final ano = int.tryParse(partes[1]) ?? DateTime.now().year;
    return DateTime(ano, mes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompulsaAppBar(title: 'Evolución Mensual'),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSelectorPeriodo(),
                  const SizedBox(height: 24),
                  _buildResumenGeneral(),
                  const SizedBox(height: 24),
                  _buildEvolucionIGV(),
                  const SizedBox(height: 24),
                  _buildEvolucionRenta(),
                  const SizedBox(height: 24),
                  _buildComparativaMensual(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis de Evolución',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Visualiza la tendencia de tus impuestos a lo largo del tiempo',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSelectorPeriodo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Período de análisis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChipPeriodo('por_mes', 'Por mes'),
                _buildChipPeriodo('ultimos3meses', 'Últimos 3 meses'),
                _buildChipPeriodo('ultimos6meses', 'Últimos 6 meses'),
                _buildChipPeriodo('ultimo_ano', 'Último año'),
                _buildChipPeriodo('todos', 'Todo el período'),
              ],
            ),
            if (_periodoSeleccionado == 'por_mes') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mesSeleccionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mes',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _obtenerMesesDisponibles()
                    .map((m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(m, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (valor) {
                  setState(() {
                    _mesSeleccionado = valor;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipPeriodo(String valor, String etiqueta) {
    final seleccionado = _periodoSeleccionado == valor;
    return FilterChip(
      label: Text(
        etiqueta,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
          color: seleccionado ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      selected: seleccionado,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _periodoSeleccionado = valor;
          });
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.15),
      backgroundColor: Colors.grey[100],
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: seleccionado ? AppColors.primary : Colors.grey[300]!,
        width: seleccionado ? 2 : 1,
      ),
      elevation: seleccionado ? 2 : 0,
    );
  }

  Widget _buildResumenGeneral() {
    final mesesFiltrados = _obtenerMesesFiltrados();
    if (mesesFiltrados.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No hay datos disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay cálculos registrados para el período seleccionado',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    double totalIGVPagado = 0;
    double totalSaldoFavor = 0;
    double totalRentaPagada = 0;
    int totalCalculos = 0;

    for (final mes in mesesFiltrados) {
      final datosIGV = _datosEvolucion['igv'][mes];
      final datosRenta = _datosEvolucion['renta'][mes];
      final conteos = _datosEvolucion['conteos'][mes] ?? 0;

      if (datosIGV != null) {
        totalIGVPagado += datosIGV['igvPagado'] ?? 0;
        totalSaldoFavor += datosIGV['saldoFavor'] ?? 0;
      }
      if (datosRenta != null) {
        totalRentaPagada += datosRenta['rentaPagada'] ?? 0;
      }
      totalCalculos += (conteos as int);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del período',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${mesesFiltrados.length} ${mesesFiltrados.length == 1 ? 'mes' : 'meses'} analizados',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'IGV Acumulado',
                    'S/ ${totalIGVPagado.toStringAsFixed(2)}',
                    AppColors.igvColor,
                    Icons.payment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Saldo a Favor acumulado',
                    'S/ ${totalSaldoFavor.toStringAsFixed(2)}',
                    AppColors.saldoFavorColor,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Renta Pagada',
                    'S/ ${totalRentaPagada.toStringAsFixed(2)}',
                    AppColors.secondary,
                    Icons.account_balance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Cálculos',
                    totalCalculos.toString(),
                    AppColors.primary,
                    Icons.calculate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolucionIGV() {
    final mesesFiltrados = _obtenerMesesFiltrados();
    if (mesesFiltrados.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
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
                    color: AppColors.igvColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppColors.igvColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evolución IGV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'IGV pagado y saldo a favor por mes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildGraficoLineas(mesesFiltrados, 'igv'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolucionRenta() {
    final mesesFiltrados = _obtenerMesesFiltrados();
    if (mesesFiltrados.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
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
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evolución Renta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Impuesto a la renta pagado por mes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildGraficoLineas(mesesFiltrados, 'renta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoLineas(List<String> meses, String tipo) {
    if (meses.isEmpty) {
      return const Center(
        child: Text('No hay datos suficientes para mostrar el gráfico'),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: meses.length,
      itemBuilder: (context, index) {
        final mes = meses[index];
        final datos = _datosEvolucion[tipo][mes];

        if (datos == null) {
          return Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mes,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        double valor;
        Color color;

        if (tipo == 'igv') {
          valor = (datos['igvPagado'] ?? 0.0) + (datos['saldoFavor'] ?? 0.0);
          color = AppColors.igvColor;
        } else {
          valor = datos['rentaPagada'] ?? 0.0;
          color = AppColors.secondary;
        }

        // Normalizar altura (máximo 100px para evitar overflow)
        final maxValor = _obtenerMaxValor(meses, tipo);
        final altura = maxValor > 0
            ? (valor / maxValor * 100).clamp(5.0, 100.0)
            : 5.0;

        return Container(
          width: 70,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'S/ ${valor.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                height: altura,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mes,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  double _obtenerMaxValor(List<String> meses, String tipo) {
    double max = 0;
    for (final mes in meses) {
      final datos = _datosEvolucion[tipo][mes];
      if (datos != null) {
        double valor;
        if (tipo == 'igv') {
          valor = (datos['igvPagado'] ?? 0.0) + (datos['saldoFavor'] ?? 0.0);
        } else {
          valor = datos['rentaPagada'] ?? 0.0;
        }
        if (valor > max) max = valor;
      }
    }
    return max;
  }

  Widget _buildComparativaMensual() {
    final mesesFiltrados = _obtenerMesesFiltrados();
    if (mesesFiltrados.length < 2) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Comparativa Mensual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Detalle mes a mes de los impuestos calculados',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ...mesesFiltrados.map((mes) => _buildFilaMes(mes)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaMes(String mes) {
    final datosIGV = _datosEvolucion['igv'][mes];
    final datosRenta = _datosEvolucion['renta'][mes];
    final conteos = _datosEvolucion['conteos'][mes] ?? 0;

    final igvTotal =
        (datosIGV?['igvPagado'] ?? 0.0) + (datosIGV?['saldoFavor'] ?? 0.0);
    final rentaTotal = datosRenta?['rentaPagada'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mes,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$conteos cálculos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.igvColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IGV',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${igvTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.igvColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Renta',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${rentaTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String titulo,
    String valor,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
