import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final read = await StorageService.getStringList(_readKey);
    _readIds = read.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();

    try {
      final list = await NotificacionesService.listar(rol: _role);
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      setState(() {
        _error = null;
        _all = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _all = [];
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificacionModel n) async {
    _readIds.add(n.id);
    await StorageService.saveStringList(
      _readKey,
      _readIds.map((e) => e.toString()).toList(),
    );
    setState(() {});
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
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = items[index];
        final fechaStr = n.fecha.toLocal().toString().substring(0, 16);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.titulo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _prioridadChip(n.prioridad),
                  ],
                ),
                const SizedBox(height: 6),
                Text(fechaStr, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(n.contenido),
                if (showMarkRead) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsRead(n),
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar recibido'),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _prioridadChip(String prioridad) {
    Color color;
    switch (prioridad.toLowerCase()) {
      case 'alta':
        color = Colors.orange;
        break;
      case 'urgente':
        color = Colors.red;
        break;
      case 'media':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(prioridad.toUpperCase()),
      backgroundColor: color.withOpacity(0.15),
      //labelStyle: TextStyle(color: color.shade700),
      //side: BorderSide(color: color.shade300),
      labelStyle: TextStyle(color: color), 
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}


