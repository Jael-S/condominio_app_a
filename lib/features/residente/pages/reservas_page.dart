import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/reservas_service.dart';
import '../../../models/area_comun_model.dart';
import '../../../models/reserva_model.dart';
import '../../../widgets/loading_overlay.dart';
import 'nueva_reserva_page.dart';

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
  AreaComun? _areaSeleccionada;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicioSel;
  TimeOfDay? _horaFinSel;
  final TextEditingController _motivoCtrl = TextEditingController();

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
    _motivoCtrl.dispose();
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

  Future<void> _abrirFormularioNuevaReserva() async {
    if (_areasComunes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay áreas disponibles')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaReservaPage(
          areasComunes: _areasComunes,
          onReservaCreada: _refrescarDatos,
          areaPreSeleccionada: _areaSeleccionada,
          fechaPreSeleccionada: _fechaSeleccionada,
          horaInicioPreSeleccionada: _horaInicioSel,
          horaFinPreSeleccionada: _horaFinSel,
        ),
      ),
    );
  }


  Future<void> _confirmarReserva(Reserva reserva) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de confirmar esta reserva?'),
            const SizedBox(height: 8),
            Text('Área: ${reserva.nombreArea}'),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(reserva.fecha))}'),
            Text('Horario: ${reserva.horaInicio} - ${reserva.horaFin}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Una vez confirmada, la reserva será visible para el administrador y se creará un evento en la agenda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReservasService.confirmarReserva(authProvider.user!.token, reserva.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Reserva confirmada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _refrescarDatos();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al confirmar reserva: $e';
        if (e.toString().contains('No se puede confirmar una reserva en estado')) {
          errorMessage = 'Esta reserva ya no puede ser confirmada.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarReserva(Reserva reserva) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de cancelar esta reserva?'),
            const SizedBox(height: 8),
            Text('Área: ${reserva.nombreArea}'),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(reserva.fecha))}'),
            Text('Horario: ${reserva.horaInicio} - ${reserva.horaFin}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción cancelará la reserva y no se creará ningún evento en la agenda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Reserva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReservasService.cancelarReserva(authProvider.user!.token, reserva.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Reserva cancelada exitosamente'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        _refrescarDatos();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al cancelar reserva: $e';
        if (e.toString().contains('No se puede cancelar una reserva en estado')) {
          errorMessage = 'Esta reserva ya no puede ser cancelada.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarReserva(Reserva reserva) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reserva'),
        content: const Text('Esta acción eliminará tu reserva de tu lista. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sí')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReservasService.eliminarReserva(authProvider.user!.token, reserva.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva eliminada')),
        );
        _refrescarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
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

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'confirmada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      case 'completada':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Reservas de Áreas Comunes'),
        backgroundColor: _headerColorForRole(Provider.of<AuthProvider>(context, listen: false).user?.rol ?? 'residente'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioNuevaReserva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Reserva'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(reserva.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getEstadoIcon(reserva.estado),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getEstadoTexto(reserva.estado),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esta reserva está pendiente de confirmación',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Botón eliminar si la reserva ya pasó en el tiempo
                  if (_reservaPasada(reserva)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _eliminarReserva(reserva),
                        icon: const Icon(Icons.delete_forever, size: 16),
                        label: const Text('Eliminar reserva'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
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
              onTap: () async {
                _areaSeleccionada = area;
                await _abrirFormularioNuevaReserva();
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

  Color _headerColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'seguridad':
        return Colors.red[600]!;
      case 'empleado':
        return Colors.cyan[600]!;
      default:
        return Colors.green[600]!;
    }
  }


  bool _reservaPasada(Reserva r) {
    try {
      final fecha = DateTime.parse(r.fecha);
      final hf = r.horaFin.split(':');
      final fin = DateTime(fecha.year, fecha.month, fecha.day, int.parse(hf[0]), int.parse(hf[1]));
      return DateTime.now().isAfter(fin);
    } catch (_) {
      return false;
    }
  }
}
