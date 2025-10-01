import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/notificacion_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notificaciones_service.dart';
import '../../../services/storage_service.dart';

class ComunicadosPage extends StatefulWidget {
  const ComunicadosPage({super.key});

  @override
  State<ComunicadosPage> createState() => _ComunicadosPageState();
}

class _ComunicadosPageState extends State<ComunicadosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificacionModel> _all = [];
  Set<int> _readIds = <int>{};
  bool _loading = true;
  String? _error;
  String _role = '';
  String _username = '';

  String get _readKey => 'read_notifs_${_role.toLowerCase()}_$_username';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _role = auth.user?.rol ?? '';
    _username = auth.user?.username ?? '';
    
    print('🔍 DEBUG ComunicadosPage:');
    print('   Usuario: $_username');
    print('   Rol: $_role');
    print('   Rol en minúsculas: ${_role.toLowerCase()}');
    
    final read = await StorageService.getStringList(_readKey);
    _readIds = read.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();
    
    // Obtener comunicados eliminados
    final deletedKey = 'deleted_notifs_${_role.toLowerCase()}_$_username';
    final deletedList = await StorageService.getStringList(deletedKey);
    final deletedIds = deletedList.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();
    
    print('🔍 DEBUG ComunicadosPage - IDs leídos:');
    print('   Clave de almacenamiento: $_readKey');
    print('   IDs leídos: $_readIds');

    try {
      // Usar método principal mejorado
      final list = await NotificacionesService.listar(rol: _role);
      // Filtrar comunicados eliminados
      final filteredList = list.where((n) => !deletedIds.contains(n.id)).toList();
      filteredList.sort((a, b) => b.fecha.compareTo(a.fecha));
      setState(() {
        _error = null;
        _all = filteredList;
        _loading = false;
      });
      
      print('🔍 DEBUG ComunicadosPage - Después de cargar:');
      print('   Total comunicados: ${_all.length}');
      print('   IDs de comunicados: ${_all.map((n) => n.id).toList()}');
      print('   IDs leídos: $_readIds');
      final unread = _all.where((n) => !_readIds.contains(n.id)).toList();
      print('   Comunicados no leídos: ${unread.length}');
    } catch (e) {
      print('❌ Error cargando comunicados: $e');
      setState(() {
        _error = e.toString();
        _all = [];
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificacionModel n) async {
    // Confirmar lectura en el backend
    final success = await NotificacionesService.confirmarLectura(n.id);
    
    if (success) {
      // Si la confirmación fue exitosa, marcar como leído localmente
      _readIds.add(n.id);
      await StorageService.saveStringList(
        _readKey,
        _readIds.map((e) => e.toString()).toList(),
      );
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lectura confirmada en el servidor')),
        );
      }
    } else {
      // Si falló la confirmación, mostrar error pero aún marcar localmente
      _readIds.add(n.id);
      await StorageService.saveStringList(
        _readKey,
        _readIds.map((e) => e.toString()).toList(),
      );
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marcado como leído localmente (error de conexión)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
      await _load();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicado eliminado')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _all.where((n) => !_readIds.contains(n.id)).toList();
    final read = _all.where((n) => _readIds.contains(n.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicados'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/comunicados-leidos'),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Ver comunicados leídos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nuevos'),
            Tab(text: 'Archivados'),
          ],
        ),
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
                        Text('No se pudieron cargar los comunicados',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[600])),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(unread, showMarkRead: true),
                  _buildList(read, showMarkRead: false),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<NotificacionModel> items, {required bool showMarkRead}) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin comunicados'));
    }
    
    // Obtener color del rol para el botón
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.rol ?? '';
    Color accentColor;
    switch (role.toLowerCase()) {
      case 'seguridad':
        accentColor = Colors.red[500]!;
        break;
      case 'empleado':
        accentColor = Colors.cyan[500]!;
        break;
      default:
        accentColor = Colors.green[500]!;
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = items[index];
        final urgent = n.prioridad.toLowerCase() == 'alta' || n.prioridad.toLowerCase() == 'urgente';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]
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
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      )
                    ),
                    if (urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                        decoration: BoxDecoration(
                          color: Colors.red[100], 
                          borderRadius: BorderRadius.circular(8)
                        ), 
                        child: const Text(
                          'URGENTE', 
                          style: TextStyle(
                            color: Colors.red, 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold
                          )
                        )
                      ),
                  ]
                ),
                const SizedBox(height: 6),
                Text(n.contenido, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 6),
                Text(
                  n.fecha.toLocal().toString().substring(0, 16), 
                  style: const TextStyle(color: Colors.black54, fontSize: 12)
                ),
                const SizedBox(height: 8),
                if (showMarkRead) 
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => _markAsRead(n),
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar como leído'),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _deleteComunicado(n),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar comunicado',
                    ),
                  )
              ]
            ),
          ),
        );
      },
    );
  }

}