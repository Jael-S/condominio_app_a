import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/reservas_service.dart';
import '../../../models/area_comun_model.dart';
import '../../../models/reserva_model.dart';
import '../../../widgets/loading_overlay.dart';
import 'nueva_reserva_page.dart';
import 'disponibilidad_page.dart';

class ReservasPage extends StatefulWidget {
  const ReservasPage({super.key});

  @override
  State<ReservasPage> createState() => _ReservasPageState();
}

class _ReservasPageState extends State<ReservasPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<AreaComun> _areasComunes = [];
  List<Reserva> _reservas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 Debug: Inicializando ReservasPage...');
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('🔍 Debug: Iniciando carga de datos...');
    debugPrint('🔍 Debug: Usuario autenticado: ${authProvider.isAuthenticated}');
    debugPrint('🔍 Debug: Token disponible: ${authProvider.user?.token != null}');
    debugPrint('🔍 Debug: Usuario actual: ${authProvider.user?.username}');
    
    if (!authProvider.isAuthenticated || authProvider.user?.token == null) {
      debugPrint('❌ Debug: No hay sesión activa');
      setState(() {
        _error = 'No hay sesión activa';
        _loading = false;
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
        // Limpiar datos anteriores para evitar datos de sesión anterior
        _areasComunes = [];
        _reservas = [];
      });

      debugPrint('🔍 Debug: Obteniendo áreas comunes...');
      final areas = await ReservasService.getAreasComunes(authProvider.user!.token);
      debugPrint('✅ Debug: Áreas obtenidas: ${areas.length}');
      
      debugPrint('🔍 Debug: Obteniendo reservas...');
      final reservas = await ReservasService.getReservas(authProvider.user!.token);
      debugPrint('✅ Debug: Reservas obtenidas: ${reservas.length}');
      
      // Debug adicional de las reservas
      for (int i = 0; i < reservas.length; i++) {
        final reserva = reservas[i];
        debugPrint('🔍 Debug: Reserva ${i+1}: ID=${reserva.id}, Fecha=${reserva.fecha}, Estado=${reserva.estado}, Área=${reserva.nombreArea}, Residente=${reserva.nombreCompletoResidente}');
      }

      setState(() {
        _areasComunes = areas;
        _reservas = reservas;
        _loading = false;
      });
      
      debugPrint('✅ Debug: Datos cargados exitosamente - Áreas: ${_areasComunes.length}, Reservas: ${_reservas.length}');
    } catch (e) {
      debugPrint('❌ Debug: Error cargando datos: $e');
      
      // Si es error de sesión expirada, limpiar datos y mostrar mensaje específico
      if (e.toString().contains('Sesión expirada')) {
        setState(() {
          _error = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
          _loading = false;
          _areasComunes = [];
          _reservas = [];
        });
        
        // Mostrar diálogo para relogin
        if (mounted) {
          _showSessionExpiredDialog();
        }
      } else {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _refrescarDatos() async {
    await _cargarDatos();
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesión Expirada'),
        content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar al login
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  void _debugInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('🔍 DEBUG INFO:');
    debugPrint('🔍 Usuario autenticado: ${authProvider.isAuthenticated}');
    debugPrint('🔍 Token disponible: ${authProvider.user?.token != null}');
    debugPrint('🔍 Usuario: ${authProvider.user?.username}');
    debugPrint('🔍 Áreas cargadas: ${_areasComunes.length}');
    debugPrint('🔍 Reservas cargadas: ${_reservas.length}');
    debugPrint('🔍 Estado de carga: $_loading');
    debugPrint('🔍 Error: $_error');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug: ${_reservas.length} reservas, ${_areasComunes.length} áreas'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _nuevaReserva() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaReservaPage(
          areasComunes: _areasComunes,
          onReservaCreada: _refrescarDatos,
        ),
      ),
    );
  }

  void _consultarDisponibilidad() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisponibilidadPage(
          areasComunes: _areasComunes,
          onReservaCreada: _refrescarDatos,
        ),
      ),
    );
  }

  Future<void> _confirmarReserva(Reserva reserva) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    try {
      await ReservasService.confirmarReserva(authProvider.user!.token, reserva.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva confirmada exitosamente')),
        );
        _refrescarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar reserva: $e')),
        );
      }
    }
  }

  Future<void> _cancelarReserva(Reserva reserva) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    try {
      await ReservasService.cancelarReserva(authProvider.user!.token, reserva.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada exitosamente')),
        );
        _refrescarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar reserva: $e')),
        );
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'completada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'cancelada':
        return 'Cancelada';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de Áreas Comunes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mis Reservas', icon: Icon(Icons.event)),
            Tab(text: 'Áreas Disponibles', icon: Icon(Icons.location_on)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugInfo,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _error != null
            ? _buildErrorWidget()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildReservasTab(),
                  _buildAreasTab(),
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _consultarDisponibilidad,
            icon: const Icon(Icons.search),
            label: const Text('Disponibilidad'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _nuevaReserva,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Reserva'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refrescarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReservasTab() {
    if (_reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes reservas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera reserva usando el botón de abajo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reservas.length,
        itemBuilder: (context, index) {
          final reserva = _reservas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reserva.nombreArea,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              reserva.tipoArea,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          _getEstadoTexto(reserva.estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: _getEstadoColor(reserva.estado),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.parse(reserva.fecha)),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reserva.horaInicio} - ${reserva.horaFin}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (reserva.motivo != null && reserva.motivo!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Motivo: ${reserva.motivo}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (reserva.costo > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Costo: \$${reserva.costo.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (reserva.pagado) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (reserva.estado == 'pendiente') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmarReserva(reserva),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelarReserva(reserva),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAreasTab() {
    if (_areasComunes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay áreas disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarDatos,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _areasComunes.length,
        itemBuilder: (context, index) {
          final area = _areasComunes[index];
          return Card(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisponibilidadPage(
                      areasComunes: _areasComunes,
                      areaSeleccionada: area,
                      onReservaCreada: _refrescarDatos,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getAreaIcon(area.tipo),
                      size: 32,
                      color: area.estado ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      area.nombre,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      area.tipo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          area.estado ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: area.estado ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          area.estado ? 'Disponible' : 'No disponible',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: area.estado ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getAreaIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'gimnasio':
        return Icons.fitness_center;
      case 'salón de eventos':
        return Icons.event;
      case 'piscina':
        return Icons.pool;
      case 'cancha':
        return Icons.sports_soccer;
      case 'parque':
        return Icons.park;
      case 'sala de juntas':
        return Icons.meeting_room;
      default:
        return Icons.location_on;
    }
  }
}
