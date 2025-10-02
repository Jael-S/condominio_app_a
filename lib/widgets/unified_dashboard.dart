import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/notificacion_model.dart';
import '../services/notificaciones_service.dart';
import '../services/storage_service.dart';
import 'package:go_router/go_router.dart';

class UnifiedDashboard extends StatefulWidget {
  const UnifiedDashboard({super.key});

  @override
  State<UnifiedDashboard> createState() => _UnifiedDashboardState();
}

class _UnifiedDashboardState extends State<UnifiedDashboard> {
  String _activeTab = 'home';
  List<NotificacionModel> _unread = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Map<String, dynamic> _roleConfig(String role, String userName) {
    if (role.toLowerCase() == 'seguridad') {
      return {
        'name': 'Seguridad',
        'userName': userName,
        'headerColor': Colors.red[600]!,
        'accentColor': Colors.red[500]!,
        'bottomNav': const [
          {'icon': Icons.home_rounded, 'title': 'Inicio', 'key': 'home'},
          {'icon': Icons.groups_rounded, 'title': 'Visitas', 'key': 'visitas'},
          {'icon': Icons.shield_rounded, 'title': 'Accesos', 'key': 'accesos'},
          {'icon': Icons.directions_car_filled_rounded, 'title': 'Vehículos', 'key': 'vehiculos'},
          {'icon': Icons.notifications_rounded, 'title': 'Comunicados', 'key': 'comunicados'},
          {'icon': Icons.person_rounded, 'title': 'Perfil', 'key': 'perfil'},
        ],
        'extra': const [
          {'icon': Icons.report_gmailerrorred_rounded, 'title': 'Incidencias'},
          {'icon': Icons.description_rounded, 'title': 'Reportes'},
          {'icon': Icons.history_rounded, 'title': 'Historial'},
          {'icon': Icons.videocam_rounded, 'title': 'Cámaras'},
        ],
      };
    }
    if (role.toLowerCase() == 'empleado') {
      return {
        'name': 'Empleado',
        'userName': userName,
        'headerColor': Colors.cyan[600]!,
        'accentColor': Colors.cyan[500]!,
        'bottomNav': const [
          {'icon': Icons.home_rounded, 'title': 'Inicio', 'key': 'home'},
          {'icon': Icons.checklist_rounded, 'title': 'Mis Tareas', 'key': 'tareas'},
          {'icon': Icons.handyman_rounded, 'title': 'Mantenimiento', 'key': 'mantenimiento'},
          {'icon': Icons.calendar_month_rounded, 'title': 'Agenda', 'key': 'agenda'},
          {'icon': Icons.notifications_rounded, 'title': 'Comunicados', 'key': 'comunicados'},
          {'icon': Icons.person_rounded, 'title': 'Perfil', 'key': 'perfil'},
        ],
        'extra': const [
          {'icon': Icons.description_rounded, 'title': 'Reportes'},
          {'icon': Icons.history_rounded, 'title': 'Historial'},
          {'icon': Icons.settings_rounded, 'title': 'Configuración'},
        ],
      };
    }
    return {
      'name': 'Residente',
      'userName': userName,
      'headerColor': Colors.green[600]!,
      'accentColor': Colors.green[500]!,
        'bottomNav': const [
          {'icon': Icons.home_rounded, 'title': 'Inicio', 'key': 'home'},
          {'icon': Icons.event_available_rounded, 'title': 'Reservas', 'key': 'reservas'},
          {'icon': Icons.payments_rounded, 'title': 'Pagar Cuotas', 'key': 'pagos'},
          {'icon': Icons.groups_rounded, 'title': 'Visitas', 'key': 'visitas'},
          {'icon': Icons.notifications_rounded, 'title': 'Comunicados', 'key': 'comunicados'},
          {'icon': Icons.person_rounded, 'title': 'Perfil', 'key': 'perfil'},
        ],
      'extra': const [
        {'icon': Icons.history_rounded, 'title': 'Historial de Pagos'},
        {'icon': Icons.home_work_rounded, 'title': 'Mi Unidad'},
        {'icon': Icons.description_rounded, 'title': 'Documentos'},
        {'icon': Icons.report_gmailerrorred_rounded, 'title': 'Reclamos'},
        {'icon': Icons.account_balance_wallet_rounded, 'title': 'Estado de Cuenta'},
        {'icon': Icons.event_note_rounded, 'title': 'Eventos'},
      ],
    };
  }

  Future<void> _loadUnread() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.rol ?? '';
    final username = auth.user?.username ?? '';
    
    print('🔍 DEBUG UnifiedDashboard:');
    print('   Usuario: $username');
    print('   Rol: $role');
    print('   Rol en minúsculas: ${role.toLowerCase()}');
    
    final key = 'read_notifs_${role.toLowerCase()}_$username';
    final readIds = await StorageService.getStringList(key);
    final setRead = readIds.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();
    
    print('   Comunicados leídos: ${setRead.length}');
    
    try {
      final list = await NotificacionesService.listar(rol: role);
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      print('   Comunicados recibidos del servicio: ${list.length}');
      
      final unreadList = list.where((n) => !setRead.contains(n.id)).toList();
      print('   Comunicados no leídos: ${unreadList.length}');
      
      if (!mounted) return;
      setState(() {
        _unread = unreadList;
        _loading = false;
      });
    } catch (e) {
      print('   ❌ Error cargando comunicados: $e');
      if (!mounted) return;
      setState(() {
        _unread = [];
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificacionModel n) async {
    // Confirmar lectura en el backend
    final success = await NotificacionesService.confirmarLectura(n.id);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.rol ?? '';
    final username = auth.user?.username ?? '';
    final key = 'read_notifs_${role.toLowerCase()}_$username';
    final list = await StorageService.getStringList(key);
    if (!list.contains(n.id.toString())) {
      list.add(n.id.toString());
      await StorageService.saveStringList(key, list);
    }
    await _loadUnread();
    
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final role = auth.user?.rol ?? 'Residente';
        final username = auth.user?.username ?? '';
        final cfg = _roleConfig(role, username);
        final Color header = cfg['headerColor'];
        final Color accent = cfg['accentColor'];

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
                  decoration: BoxDecoration(color: header, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]),
                  child: const Icon(Icons.home_filled, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Smart',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        )),
                    Text('Condominium',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    SizedBox(height: 2),
                    Text('Sistema de Gestión',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        )),
                  ],
                ),
              ],
            ),
            actions: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cfg['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(username, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: header, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]),
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
                icon: const Icon(Icons.logout), color: Colors.black54,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread comunicaciones
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_unread.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comunicados sin leer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._unread.map((n) => _unreadCard(n, accent)).toList(),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child: Column(
                      children: [
                        Container(width: 64, height: 64, decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.check, color: accent, size: 32)),
                        const SizedBox(height: 12),
                        const Text('¡Todo al día!', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('No tienes comunicados pendientes por leer', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if ((_roleConfig(role, username)['extra'] as List).isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: header, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      // TODO: Implementar modal de opciones adicionales
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidad próximamente disponible')),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Ver más opciones'),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List<Widget>.from((cfg['bottomNav'] as List).map((item) {
                  final bool isActive = _activeTab == item['key'];
                  final Color activeColor = header;
                  return InkWell(
                    onTap: () {
                      final String key = item['key'] as String;
                      setState(() => _activeTab = key);
                      if (key == 'reservas') {
                        context.go('/reservas');
                      } else if (key == 'comunicados') {
                        context.go('/comunicados');
                      } else if (key == 'visitas') {
                        final r = (Provider.of<AuthProvider>(context, listen:false).user?.rol ?? '').toLowerCase();
                        if (r == 'seguridad') {
                          context.go('/invitados-seguridad');
                        } else {
                          context.go('/invitados');
                        }
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(item['icon'] as IconData, color: isActive ? activeColor : Colors.grey[600]),
                            if (item['key'] == 'home' && _unread.isNotEmpty)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                                  child: Text('${_unread.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['title'] as String,
                          style: TextStyle(color: isActive ? activeColor : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                })),
              ),
            ),
          ),
          // Full options modal
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _unreadCard(NotificacionModel n, Color accent) {
    final urgent = n.prioridad.toLowerCase() == 'alta' || n.prioridad.toLowerCase() == 'urgente';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (urgent)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)), child: const Text('URGENTE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          Text(n.contenido, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(n.fecha.toLocal().toString().substring(0, 16), style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => _markAsRead(n),
              icon: const Icon(Icons.check),
              label: const Text('Marcar como leído'),
            ),
          ),
        ]),
      ),
    );
  }
}


