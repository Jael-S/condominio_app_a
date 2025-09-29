import 'package:flutter/material.dart';
import '../../config/network_config.dart';
import '../../config/app_config.dart';

class NetworkConfigPage extends StatefulWidget {
  const NetworkConfigPage({super.key});

  @override
  State<NetworkConfigPage> createState() => _NetworkConfigPageState();
}

class _NetworkConfigPageState extends State<NetworkConfigPage> {
  String _selectedConfig = NetworkConfig.currentConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Red'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona la configuración de red:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mostrar URL actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL Actual:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.baseUrl,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lista de configuraciones
            Expanded(
              child: ListView.builder(
                itemCount: NetworkConfig.availableConfigs.length,
                itemBuilder: (context, index) {
                  final config = NetworkConfig.availableConfigs[index];
                  final url = NetworkConfig.getUrlForConfig(config);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      title: Text(
                        config.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        url,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: config,
                      groupValue: _selectedConfig,
                      onChanged: (value) {
                        setState(() {
                          _selectedConfig = value!;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para probar conexión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.wifi),
                label: const Text('Probar Conexión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón para aplicar configuración
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyConfig,
                icon: const Icon(Icons.save),
                label: const Text('Aplicar Configuración'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection() async {
    // Aquí podrías implementar una prueba de conexión real
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prueba de Conexión'),
        content: Text('Probando conexión a:\n${NetworkConfig.getUrlForConfig(_selectedConfig)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _applyConfig() {
    // En una implementación real, aquí guardarías la configuración
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Aplicada'),
        content: Text('La configuración se ha cambiado a:\n${NetworkConfig.getUrlForConfig(_selectedConfig)}\n\nReinicia la aplicación para aplicar los cambios.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
