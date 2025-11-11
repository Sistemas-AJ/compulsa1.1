import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/historial_igv_service.dart';
import '../../services/historial_renta_service.dart';
import '../../widgets/compulsa_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _ultimoIGV = 0.0;
  double _ultimaRenta = 0.0;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar último IGV calculado
      final ultimoCalculoIGV = await HistorialIGVService.obtenerUltimoCalculo();
      final ultimoImpuestoIGV = ultimoCalculoIGV?.igvPorPagar ?? 0.0;

      // Cargar última Renta calculada
      final ultimoImpuestoRenta =
          await HistorialRentaService.obtenerUltimoImpuesto();

      if (mounted) {
        setState(() {
          _ultimoIGV = ultimoImpuestoIGV;
          _ultimaRenta = ultimoImpuestoRenta;
          _cargandoDatos = false;
        });

        // Debug temporal
        print('HomeScreen - IGV: $ultimoImpuestoIGV');
        print('HomeScreen - Renta: $ultimoImpuestoRenta');
        print(
          'HomeScreen - IGV formateado: ${_formatearMoneda(ultimoImpuestoIGV)}',
        );
        print(
          'HomeScreen - Renta formateado: ${_formatearMoneda(ultimoImpuestoRenta)}',
        );
      }
    } catch (e) {
      print('Error al cargar datos del resumen: $e');
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
      }
    }
  }

  String _formatearMoneda(double monto) {
    // Verificar si el número es válido
    if (monto.isNaN || monto.isInfinite) {
      return 'S/ 0.00';
    }

    if (monto == 0.0) {
      return 'S/ 0.00';
    }

    // Manejar números negativos
    if (monto < 0) {
      return '-S/ ${(-monto).toStringAsFixed(2)}';
    }

    // Formato más simple y legible
    if (monto >= 1000000) {
      double millones = monto / 1000000;
      return 'S/ ${millones.toStringAsFixed(millones == millones.toInt() ? 0 : 1)}M';
    } else if (monto >= 1000) {
      double miles = monto / 1000;
      return 'S/ ${miles.toStringAsFixed(miles == miles.toInt() ? 0 : 1)}K';
    } else {
      // Para números pequeños, usar formato estándar con separador de miles si es necesario
      return 'S/ ${monto.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CompulsaAppBar(title: 'Compulsa'),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildStatsSection(context),
              const SizedBox(height: 32),
              _buildQuickAccessSection(context),
              const SizedBox(height: 32),
              _buildMainActionsSection(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(red: 0.2, green: 0.3, blue: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido a Compulsa!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu asistente tributario inteligente',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cálculo automático de IGV \ny Renta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Gestión de saldos a favor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Reportes y análisis tributario',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Mes (pagado)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'IGV Calculado',
                  value: _cargandoDatos ? '...' : _formatearMoneda(_ultimoIGV),
                  color: AppColors.igvColor,
                  isLoading: _cargandoDatos,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance,
                  title: 'Renta Calculada',
                  value: _cargandoDatos
                      ? '...'
                      : _formatearMoneda(_ultimaRenta),
                  color: AppColors.rentaColor,
                  isLoading: _cargandoDatos,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      height: 120, // Altura fija para consistencia
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(), // Empuja el valor hacia abajo
          isLoading
              ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18, // Volvemos a un tamaño más grande
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Funciones Principales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.calculate_outlined,
                title: 'Calcular IGV',
                subtitle: 'Impuesto General a las Ventas',
                color: AppColors.igvColor,
                onTap: () async {
                  await AppRoutes.navigateTo(context, AppRoutes.igv);
                  // Recargar datos cuando regrese de la pantalla de IGV
                  _cargarDatos();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Calcular Renta',
                subtitle: 'Impuesto a la Renta',
                color: AppColors.rentaColor,
                onTap: () async {
                  await AppRoutes.navigateTo(context, AppRoutes.renta);
                  // Recargar datos cuando regrese de la pantalla de Renta
                  _cargarDatos();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.dashboard_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Funciones Adicionales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildMainActionCard(
          context,
          icon: Icons.description_outlined,
          title: 'Declaraciones',
          subtitle: 'Gestionar declaraciones mensuales y anuales',
          color: AppColors.igvColor,
          onTap: () async {
            await AppRoutes.navigateTo(context, AppRoutes.declaraciones);
            // Recargar datos por si se crearon nuevas declaraciones
            _cargarDatos();
          },
        ),
        const SizedBox(height: 16),
        _buildMainActionCard(
          context,
          icon: Icons.analytics_outlined,
          title: 'Reportes',
          subtitle: 'Análisis y reportes tributarios detallados',
          color: AppColors.rentaColor,
          onTap: () async {
            await AppRoutes.navigateTo(context, AppRoutes.reportes);
            // Recargar datos por si se accedieron a reportes
            _cargarDatos();
          },
        ),
      ],
    );
  }

  Widget _buildMainActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withValues(
                          red: color.red * 0.8,
                          green: color.green * 0.8,
                          blue: color.blue * 0.8,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
