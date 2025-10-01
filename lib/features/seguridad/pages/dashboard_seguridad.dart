import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../services/dataset_service.dart';
import '../../../services/ia_service.dart';
import '../../../services/acceso_service.dart';
import '../../../services/notificaciones_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/notificacion_model.dart';

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
  List<NotificacionModel> _comunicados = [];
  bool _loadingDataset = false;
  bool _loadingIA = false;
  bool _loadingAcceso = false;
  bool _loadingComunicados = false;

  @override
  void initState() {
    super.initState();
    _loadComunicados();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final username = auth.user?.username ?? '';
        final Color header = Colors.red[600]!;
        final Color accent = Colors.red[500]!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: header,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_filled, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Condominium',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sistema de Gestión',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Seguridad',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: header,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                    if (mounted) context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                color: Colors.black54,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comunicados sin leer
                if (_loadingComunicados)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_comunicados.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comunicados sin leer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._comunicados.map((n) => _buildComunicadoCard(n, accent)),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, color: accent, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '¡Todo al día!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No tienes comunicados pendientes por leer',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Botón de más opciones
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: header,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showAccesosModal(),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Ver más opciones'),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Inicio', 'home', true),
                  _buildNavItem(Icons.groups_rounded, 'Visitas', 'visitas', false),
                  _buildNavItem(Icons.shield_rounded, 'Accesos', 'accesos', false),
                  _buildNavItem(Icons.directions_car_filled_rounded, 'Vehículos', 'vehiculos', false),
                  _buildNavItem(Icons.notifications_rounded, 'Comunicados', 'comunicados', false),
                  _buildNavItem(Icons.person_rounded, 'Perfil', 'perfil', false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComunicadoCard(NotificacionModel n, Color accent) {
    final urgent = n.prioridad.toLowerCase() == 'alta' || n.prioridad.toLowerCase() == 'urgente';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    n.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (urgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URGENTE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(n.contenido, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 6),
            Text(
              n.fecha.toLocal().toString().substring(0, 16),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _marcarComoLeido(n),
                icon: const Icon(Icons.check),
                label: const Text('Marcar como leído'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String key, bool isActive) {
    return InkWell(
      onTap: () {
        if (key == 'accesos') {
          _showAccesosModal();
        } else if (key == 'visitas') {
          _showVisitasModal();
        } else if (key == 'vehiculos') {
          _showVehiculosModal();
        } else if (key == 'comunicados') {
          context.go('/comunicados');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.red[600] : Colors.grey[600],
              ),
              if (key == 'home' && _comunicados.isNotEmpty)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_comunicados.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.red[600] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadComunicados() async {
    setState(() => _loadingComunicados = true);
    try {
      final comunicados = await NotificacionesService.listar(rol: 'seguridad');
      setState(() {
        _comunicados = comunicados;
        _loadingComunicados = false;
      });
    } catch (e) {
      setState(() => _loadingComunicados = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando comunicados: $e')),
        );
      }
    }
  }

  Future<void> _marcarComoLeido(NotificacionModel comunicado) async {
    // Confirmar lectura en el backend
    final success = await NotificacionesService.confirmarLectura(comunicado.id);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.rol ?? '';
    final username = auth.user?.username ?? '';
    final key = 'read_notifs_${role.toLowerCase()}_$username';
    final list = await StorageService.getStringList(key);
    if (!list.contains(comunicado.id.toString())) {
      list.add(comunicado.id.toString());
      await StorageService.saveStringList(key, list);
    }
    await _loadComunicados();
    
    // Mostrar mensaje de confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Lectura confirmada en el servidor' : 'Marcado como leído localmente'),
          backgroundColor: success ? Colors.green : Colors.orange,
          action: SnackBarAction(
            label: 'Ver leídos',
            onPressed: () => context.go('/comunicados-leidos'),
          ),
        ),
      );
    }
  }

  void _showAccesosModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Gestión de Accesos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildAccesosContent(),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitasModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Gestión de Visitas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Funcionalidad de visitas próximamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehiculosModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Control Vehicular',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Funcionalidad de vehículos próximamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccesosContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Dataset Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dataset de Ejemplo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingDataset ? null : _loadDataset,
                      icon: _loadingDataset 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download),
                      label: Text(_loadingDataset ? 'Cargando...' : 'Cargar Dataset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
                          const Text(
                            'Datos cargados:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Nombre: ${_datasetData!['name'] ?? 'N/A'}'),
                          Text('Formato: ${_datasetData!['format'] ?? 'N/A'}'),
                          if (_datasetData!['data'] != null)
                            Text('Items: ${(_datasetData!['data'] as List).length}'),
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análisis con IA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingIA ? null : _pickAndAnalyzeImage,
                      icon: _loadingIA 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt),
                      label: Text(_loadingIA ? 'Analizando...' : 'Seleccionar Imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
                          const Text(
                            'Resultado del análisis:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Modelo: ${_iaResult!['model'] ?? 'N/A'}'),
                          Text('Resumen: ${_iaResult!['summary'] ?? 'N/A'}'),
                          if (_iaResult!['labels'] != null) ...[
                            const SizedBox(height: 8),
                            const Text('Etiquetas:'),
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registros de Acceso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingAcceso ? null : _loadRegistrosAcceso,
                      icon: _loadingAcceso 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.security),
                      label: Text(_loadingAcceso ? 'Cargando...' : 'Ver Registros de Acceso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_registrosAcceso != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Últimos Registros:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
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
