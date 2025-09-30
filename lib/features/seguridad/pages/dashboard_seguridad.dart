import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../services/dataset_service.dart';
import '../../../services/ia_service.dart';
import '../../../services/acceso_service.dart';

class DashboardSeguridad extends StatefulWidget {
  const DashboardSeguridad({super.key});

  @override
  State<DashboardSeguridad> createState() => _DashboardSeguridadState();
}

class _DashboardSeguridadState extends State<DashboardSeguridad> {
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _datasetData;
  Map<String, dynamic>? _iaResult;
  List<dynamic>? _registrosAcceso;
  bool _loadingDataset = false;
  bool _loadingIA = false;
  bool _loadingAcceso = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Seguridad'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dataset Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dataset de Ejemplo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadingDataset ? null : _loadDataset,
                      icon: _loadingDataset 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                      label: Text(_loadingDataset ? 'Cargando...' : 'Cargar Dataset'),
                    ),
                    if (_datasetData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos cargados:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nombre: ${_datasetData!['name'] ?? 'N/A'}',
                            ),
                            Text(
                              'Formato: ${_datasetData!['format'] ?? 'N/A'}',
                            ),
                            if (_datasetData!['data'] != null)
                              Text(
                                'Items: ${(_datasetData!['data'] as List).length}',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // IA Analysis Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis con IA',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadingIA ? null : _pickAndAnalyzeImage,
                      icon: _loadingIA 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                      label: Text(_loadingIA ? 'Analizando...' : 'Seleccionar Imagen'),
                    ),
                    if (_iaResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resultado del análisis:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Modelo: ${_iaResult!['model'] ?? 'N/A'}'),
                            Text('Resumen: ${_iaResult!['summary'] ?? 'N/A'}'),
                            if (_iaResult!['labels'] != null) ...[
                              const SizedBox(height: 8),
                              Text('Etiquetas:'),
                              for (var label in _iaResult!['labels'] as List)
                                Text('  • ${label['name']}: ${(label['confidence'] * 100).toStringAsFixed(1)}%'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Gestión de Accesos Section
            Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    Text(
                      'Gestión de Accesos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadingAcceso ? null : _loadRegistrosAcceso,
                      icon: _loadingAcceso 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.security),
                      label: Text(_loadingAcceso ? 'Cargando...' : 'Ver Registros de Acceso'),
                    ),
                    if (_registrosAcceso != null) ...[
                      const SizedBox(height: 16),
              Text(
                        'Últimos Registros:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _registrosAcceso!.length,
                          itemBuilder: (context, index) {
                            final registro = _registrosAcceso![index];
                            return Card(
                              child: ListTile(
                                title: Text('Placa: ${registro['placa_detectada']}'),
                                subtitle: Text('Estado: ${registro['estado_acceso']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (registro['estado_acceso'] == 'pendiente' || registro['estado_acceso'] == 'denegado')
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _autorizarRegistro(registro['id']),
                                      ),
                                    if (registro['estado_acceso'] == 'pendiente' || registro['estado_acceso'] == 'autorizado')
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _denegarRegistro(registro['id']),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarRegistro(registro['id']),
              ),
            ],
          ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDataset() async {
    setState(() => _loadingDataset = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token != null) {
      final result = await DatasetService.getDataset('ejemplo', authProvider.user!.token);
      setState(() {
        _datasetData = result;
        _loadingDataset = false;
      });
    } else {
      setState(() => _loadingDataset = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay token de autenticación')),
      );
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _loadingIA = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.token != null) {
        final result = await IAService.analyzeImage(File(image.path), authProvider.user!.token);
        setState(() {
          _iaResult = result;
          _loadingIA = false;
        });
      } else {
        setState(() => _loadingIA = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay token de autenticación')),
        );
      }
    } catch (e) {
      setState(() => _loadingIA = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> _loadRegistrosAcceso() async {
    setState(() => _loadingAcceso = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token != null) {
      final result = await AccesoService.getRegistrosAcceso(authProvider.user!.token);
      setState(() {
        _registrosAcceso = result;
        _loadingAcceso = false;
      });
    } else {
      setState(() => _loadingAcceso = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay token de autenticación')),
      );
    }
  }

  Future<void> _autorizarRegistro(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token != null) {
      final success = await AccesoService.autorizarRegistro(authProvider.user!.token, id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro autorizado')),
        );
        _loadRegistrosAcceso();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al autorizar registro')),
        );
      }
    }
  }

  Future<void> _denegarRegistro(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token != null) {
      final success = await AccesoService.denegarRegistro(authProvider.user!.token, id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro denegado')),
        );
        _loadRegistrosAcceso();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al denegar registro')),
        );
      }
    }
  }

  Future<void> _eliminarRegistro(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token != null) {
      final success = await AccesoService.eliminarRegistro(authProvider.user!.token, id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado')),
        );
        _loadRegistrosAcceso();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar registro')),
        );
      }
    }
  }

}


