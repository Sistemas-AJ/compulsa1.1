import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/database_models.dart';
import '../../models/regimen_tributario.dart';
import '../../services/database_service.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();

  bool _cargandoDatos = false;
  bool _modoEdicion = false;

  Empresa? _empresaActual;
  List<RegimenTributario> _regimenes = [];
  int? _regimenSeleccionado;
  RegimenTributario? _regimenActual;

  final ImagePicker _picker = ImagePicker();
  String? _imagenPerfilPath;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rucController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargandoDatos = true;
    });

    try {
      final futures = await Future.wait([
        _databaseService.obtenerRegimenes(),
        _databaseService.obtenerEmpresas(),
      ]);

      final regimenes = futures[0] as List<RegimenTributario>;
      final empresas = futures[1] as List<Empresa>;

      setState(() {
        _regimenes = regimenes;
        _empresaActual = empresas.isNotEmpty ? empresas.first : null;
        _cargandoDatos = false;

        if (_empresaActual != null) {
          _nombreController.text = _empresaActual!.nombreRazonSocial;
          _rucController.text = _empresaActual!.ruc;
          _imagenPerfilPath = _empresaActual!.imagenPerfil;

          final regimenExiste = regimenes.any(
            (r) => r.id == _empresaActual!.regimenId,
          );
          if (regimenExiste) {
            _regimenSeleccionado = _empresaActual!.regimenId;
            _regimenActual = regimenes.firstWhere(
              (r) => r.id == _empresaActual!.regimenId,
            );
          } else if (regimenes.isNotEmpty) {
            _regimenSeleccionado = regimenes.first.id;
            _regimenActual = regimenes.first;
          }
        } else {
          if (regimenes.isNotEmpty) {
            _regimenSeleccionado = regimenes.first.id;
            _regimenActual = regimenes.first;
          }
        }
      });
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      // Mostrar opciones de selección
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar imagen de perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galería',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (image != null) {
          // Crear directorio específico para imágenes de perfil
          final Directory appDir = await getApplicationDocumentsDirectory();
          final Directory profileDir = Directory(
            '${appDir.path}/profile_images',
          );

          if (!await profileDir.exists()) {
            await profileDir.create(recursive: true);
          }

          // Eliminar imagen anterior si existe
          if (_imagenPerfilPath != null &&
              File(_imagenPerfilPath!).existsSync()) {
            try {
              await File(_imagenPerfilPath!).delete();
            } catch (e) {
              print('Error eliminando imagen anterior: $e');
            }
          }

          final String fileName =
              'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String localPath = '${profileDir.path}/$fileName';

          // Copiar la imagen al directorio local
          await File(image.path).copy(localPath);

          setState(() {
            _imagenPerfilPath = localPath;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagen actualizada correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    if (_regimenSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un régimen tributario')),
      );
      return;
    }

    setState(() {
      _cargandoDatos = true;
    });

    try {
      final empresa = Empresa(
        id: _empresaActual?.id,
        regimenId: _regimenSeleccionado!,
        nombreRazonSocial: _nombreController.text.trim(),
        ruc: _rucController.text.trim(),
        imagenPerfil: _imagenPerfilPath,
      );

      if (_empresaActual == null) {
        await _databaseService.insertarEmpresa(empresa);
      } else {
        await _databaseService.actualizarEmpresa(empresa);
      }

      setState(() {
        _cargandoDatos = false;
        _modoEdicion = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos();
      }
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  String? _validarRuc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RUC es obligatorio';
    }

    final ruc = value.trim();
    if (ruc.length != 11) {
      return 'El RUC debe tener 11 dígitos';
    }

    if (!RegExp(r'^\d{11}$').hasMatch(ruc)) {
      return 'El RUC debe contener solo números';
    }

    final firstDigit = int.parse(ruc[0]);
    if (firstDigit != 1 && firstDigit != 2) {
      return 'El RUC debe comenzar con 1 o 2';
    }

    return null;
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(
              context,
            ).primaryColor.withValues(red: 0.2, green: 0.3, blue: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _modoEdicion || _empresaActual == null
                ? _seleccionarImagen
                : null,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage:
                        _imagenPerfilPath != null &&
                            File(_imagenPerfilPath!).existsSync()
                        ? FileImage(File(_imagenPerfilPath!))
                        : null,
                    child:
                        _imagenPerfilPath == null ||
                            !File(_imagenPerfilPath!).existsSync()
                        ? const Icon(
                            Icons.business_center,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                if (_modoEdicion || _empresaActual == null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _empresaActual?.nombreRazonSocial ?? 'Configurar Empresa',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_empresaActual?.ruc != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'RUC: ${_empresaActual!.ruc}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegimenInfo() {
    if (_regimenActual == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Régimen Tributario Activo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _regimenActual!.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTasaCard(
                          'Impuesto a la Renta',
                          _regimenActual!.tasaRentaFormateada,
                          Colors.orange.shade600,
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTasaCard(
                          'IGV',
                          _regimenActual!.tasaIGVFormateada,
                          _regimenActual!.pagaIGV
                              ? Colors.green.shade600
                              : Colors.grey.shade500,
                          Icons.receipt_long,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasaCard(
    String titulo,
    String tasa,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            tasa,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_document,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Información de la Empresa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_modoEdicion && _empresaActual != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _modoEdicion = true),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar información',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                enabled: _modoEdicion || _empresaActual == null,
                decoration: InputDecoration(
                  labelText: 'Nombre o Razón Social',
                  hintText: 'Ingrese el nombre de su empresa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: (_modoEdicion || _empresaActual == null)
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business_center,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rucController,
                enabled: _modoEdicion || _empresaActual == null,
                decoration: InputDecoration(
                  labelText: 'RUC',
                  hintText: 'Ej: 12345678901',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: (_modoEdicion || _empresaActual == null)
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge, color: Colors.orange),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: _validarRuc,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _regimenes.any((r) => r.id == _regimenSeleccionado)
                    ? _regimenSeleccionado
                    : null,
                decoration: InputDecoration(
                  labelText: 'Régimen Tributario',
                  hintText: 'Seleccione su régimen',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.green,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                items: _regimenes.map((regimen) {
                  return DropdownMenuItem<int>(
                    value: regimen.id,
                    child: Text(
                      regimen.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (_modoEdicion || _empresaActual == null)
                    ? (value) {
                        setState(() {
                          _regimenSeleccionado = value;
                          _regimenActual = _regimenes.firstWhere(
                            (r) => r.id == value,
                          );
                        });
                      }
                    : null,
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un régimen tributario';
                  }
                  return null;
                },
              ),
              if (_modoEdicion || _empresaActual == null) ...[
                const SizedBox(height: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _cargandoDatos
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    if (_regimenActual != null &&
                        !_modoEdicion &&
                        _empresaActual != null)
                      _buildRegimenInfo(),
                    _buildFormulario(),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    if (!_modoEdicion && _empresaActual != null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_modoEdicion) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _modoEdicion = false;
                    // Restaurar valores originales
                    if (_empresaActual != null) {
                      _nombreController.text =
                          _empresaActual!.nombreRazonSocial;
                      _rucController.text = _empresaActual!.ruc;
                      _imagenPerfilPath = _empresaActual!.imagenPerfil;
                      _regimenSeleccionado = _empresaActual!.regimenId;
                      _regimenActual = _regimenes.firstWhere(
                        (r) => r.id == _empresaActual!.regimenId,
                        orElse: () => _regimenes.first,
                      );
                    }
                  });
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _modoEdicion ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _guardarPerfil,
              icon: Icon(_empresaActual == null ? Icons.save : Icons.update),
              label: Text(
                _empresaActual == null ? 'Crear Perfil' : 'Guardar Cambios',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
