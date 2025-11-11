import 'package:flutter/material.dart';
import 'dart:io';
import '../models/database_models.dart';
import '../services/database_service.dart';
import '../screens/empresa/perfil_usuario_screen.dart';

class AppBarAvatar extends StatefulWidget {
  const AppBarAvatar({Key? key}) : super(key: key);

  @override
  State<AppBarAvatar> createState() => _AppBarAvatarState();
}

class _AppBarAvatarState extends State<AppBarAvatar> {
  final DatabaseService _databaseService = DatabaseService();
  Empresa? _empresaActual;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final empresas = await _databaseService.obtenerEmpresas();
      if (mounted) {
        setState(() {
          _empresaActual = empresas.isNotEmpty ? empresas.first : null;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _navegarAPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PerfilUsuarioScreen()),
    ).then((_) => _cargarDatos()); // Recargar datos cuando regrese
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _navegarAPerfil,
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage:
              _empresaActual?.imagenPerfil != null &&
                  File(_empresaActual!.imagenPerfil!).existsSync()
              ? FileImage(File(_empresaActual!.imagenPerfil!))
              : null,
          child:
              _empresaActual?.imagenPerfil == null ||
                  !File(_empresaActual!.imagenPerfil!).existsSync()
              ? Icon(
                  _empresaActual == null ? Icons.add : Icons.business,
                  size: 24,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
