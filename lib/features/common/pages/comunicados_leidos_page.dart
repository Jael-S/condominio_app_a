import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/notificacion_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_service.dart';
import '../../../services/storage_service.dart';
import 'package:go_router/go_router.dart';

class ComunicadosLeidosPage extends StatefulWidget {
  const ComunicadosLeidosPage({super.key});

  @override
  State<ComunicadosLeidosPage> createState() => _ComunicadosLeidosPageState();
}

class _ComunicadosLeidosPageState extends State<ComunicadosLeidosPage> {
  List<NotificacionModel> _readComunicados = [];
  bool _loading = true;
  String? _error;
  String _role = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadReadComunicados();
  }

  Future<void> _loadReadComunicados() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _role = auth.user?.rol ?? '';
    _username = auth.user?.username ?? '';
    
    final readKey = 'read_notifs_${_role.toLowerCase()}_$_username';
    final readIds = await StorageService.getStringList(readKey);
    final readIdsSet = readIds.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();

    // Obtener comunicados eliminados
    final deletedKey = 'deleted_notifs_${_role.toLowerCase()}_$_username';
    final deletedList = await StorageService.getStringList(deletedKey);
    final deletedIds = deletedList.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();

    try {
      final allComunicados = await NotificacionesService.listar(rol: _role);
      // Filtrar solo los comunicados que están marcados como leídos y no eliminados
      final readComunicados = allComunicados.where((n) => 
        readIdsSet.contains(n.id) && !deletedIds.contains(n.id)
      ).toList();
      readComunicados.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      setState(() {
        _error = null;
        _readComunicados = readComunicados;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _readComunicados = [];
        _loading = false;
      });
    }
  }

  Future<void> _deleteComunicado(NotificacionModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comunicado'),
        content: const Text('¿Estás seguro de que quieres eliminar este comunicado de tu lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Agregar a una lista de eliminados para no volver a mostrarlo
      final deletedKey = 'deleted_notifs_${_role.toLowerCase()}_$_username';
      final deletedList = await StorageService.getStringList(deletedKey);
      if (!deletedList.contains(n.id.toString())) {
        deletedList.add(n.id.toString());
        await StorageService.saveStringList(deletedKey, deletedList);
      }
      
      // Recargar la lista
      await _loadReadComunicados();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicado eliminado')),
        );
      }
    }
  }

  Color _getRoleColor() {
    switch (_role.toLowerCase()) {
      case 'seguridad':
        return Colors.red[600]!;
      case 'empleado':
        return Colors.cyan[600]!;
      default:
        return Colors.green[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comunicados',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Historial de leídos',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadReadComunicados,
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Error al cargar comunicados',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadReadComunicados,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _readComunicados.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: roleColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay comunicados leídos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Los comunicados que marques como leídos aparecerán aquí',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReadComunicados,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _readComunicados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final comunicado = _readComunicados[index];
                          return _buildComunicadoCard(comunicado, roleColor);
                        },
                      ),
                    ),
    );
  }

  Widget _buildComunicadoCard(NotificacionModel comunicado, Color roleColor) {
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
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
                    comunicado.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteComunicado(comunicado),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Eliminar comunicado',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comunicado.contenido,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  comunicado.fecha.toLocal().toString().substring(0, 16),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: roleColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Leído',
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
