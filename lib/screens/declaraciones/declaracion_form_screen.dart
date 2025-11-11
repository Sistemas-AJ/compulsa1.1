import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DeclaracionFormScreen extends StatefulWidget {
  const DeclaracionFormScreen({super.key});

  @override
  State<DeclaracionFormScreen> createState() => _DeclaracionFormScreenState();
}

class _DeclaracionFormScreenState extends State<DeclaracionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _empresaSeleccionada = 'ABC Consultores S.A.C.';
  String _tipoDeclaracion = 'IGV';
  String _periodoSeleccionado = 'Octubre 2024';

  final List<String> _empresas = [
    'ABC Consultores S.A.C.',
    'Juan Pérez Contadores',
    'Servicios Tributarios S.R.L.',
  ];

  final List<String> _tipos = ['IGV', 'Renta'];

  final List<String> _periodos = [
    'Octubre 2024',
    'Septiembre 2024',
    'Agosto 2024',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Declaración'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos de la Declaración',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _empresaSeleccionada,
                decoration: const InputDecoration(labelText: 'Empresa'),
                items: _empresas.map((String empresa) {
                  return DropdownMenuItem<String>(
                    value: empresa,
                    child: Text(empresa),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _empresaSeleccionada = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipoDeclaracion,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Declaración',
                ),
                items: _tipos.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoDeclaracion = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _periodoSeleccionado,
                decoration: const InputDecoration(labelText: 'Período'),
                items: _periodos.map((String periodo) {
                  return DropdownMenuItem<String>(
                    value: periodo,
                    child: Text(periodo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _periodoSeleccionado = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResumenItem('Empresa:', _empresaSeleccionada),
                      _buildResumenItem('Tipo:', _tipoDeclaracion),
                      _buildResumenItem('Período:', _periodoSeleccionado),
                      _buildResumenItem('Estado:', 'Pendiente'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarDeclaracion,
                  child: const Text('Generar Declaración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _generarDeclaracion() {
    if (_formKey.currentState!.validate()) {
      // TODO: Generar declaración
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Declaración generada correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
