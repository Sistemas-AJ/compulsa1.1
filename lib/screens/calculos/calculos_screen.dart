import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/cards/dashboard_card.dart';
import '../../widgets/compulsa_appbar.dart';

class CalculosScreen extends StatelessWidget {
  const CalculosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CompulsaAppBar(title: 'Cálculos Tributarios'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de cálculo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DashboardCard(
              icon: Icons.receipt,
              title: 'Cálculo de IGV',
              subtitle: 'Impuesto General a las Ventas',
              color: AppColors.igvColor,
              onTap: () => AppRoutes.navigateTo(context, AppRoutes.igv),
            ),
            const SizedBox(height: 16),
            DashboardCard(
              icon: Icons.account_balance_wallet,
              title: 'Impuesto a la Renta',
              subtitle: 'Cálculo mensual de renta',
              color: AppColors.rentaColor,
              onTap: () => AppRoutes.navigateTo(context, AppRoutes.renta),
            ),
            const SizedBox(height: 24),
            const Text(
              'Resumen del Período Actual',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildResumenCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResumenItem(
              'IGV por Pagar',
              'S/ 2,456.80',
              AppColors.igvColor,
            ),
            const Divider(),
            _buildResumenItem(
              'Renta por Pagar',
              'S/ 1,234.50',
              AppColors.rentaColor,
            ),
            const Divider(),
            _buildResumenItem(
              'Saldo a Favor',
              'S/ 345.20',
              AppColors.saldoFavorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(String label, String valor, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    );
  }
}
