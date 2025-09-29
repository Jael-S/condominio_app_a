import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/reservas_service.dart';
import '../../../models/area_comun_model.dart';
import '../../../models/horario_disponible_model.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/custom_button.dart';
import 'nueva_reserva_page.dart';

class DisponibilidadPage extends StatefulWidget {
  final List<AreaComun> areasComunes;
  final AreaComun? areaSeleccionada;
  final VoidCallback onReservaCreada;

  const DisponibilidadPage({
    super.key,
    required this.areasComunes,
    this.areaSeleccionada,
    required this.onReservaCreada,
  });

  @override
  State<DisponibilidadPage> createState() => _DisponibilidadPageState();
}

class _DisponibilidadPageState extends State<DisponibilidadPage> {
  AreaComun? _areaSeleccionada;
  DateTime? _fechaSeleccionada;
  List<HorarioDisponible> _horariosDisponibles = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _areaSeleccionada = widget.areaSeleccionada;
  }

  Future<void> _consultarDisponibilidad() async {
    if (_areaSeleccionada == null) {
      _showError('Selecciona un área común');
      return;
    }
    if (_fechaSeleccionada == null) {
      _showError('Selecciona una fecha');
      return;
    }

    // Validar que la fecha no sea en el pasado
    final now = DateTime.now();
    final fechaConsulta = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day);
    final fechaActual = DateTime(now.year, now.month, now.day);
    
    if (fechaConsulta.isBefore(fechaActual)) {
      _showError('No puedes consultar disponibilidad para fechas pasadas');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) {
      _showError('No hay sesión activa');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _horariosDisponibles = []; // Limpiar horarios anteriores
    });

    try {
      debugPrint('🔍 Debug: Consultando disponibilidad para área ${_areaSeleccionada!.id} en fecha ${DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!)}');
      
      final data = await ReservasService.getHorariosDisponibles(
        authProvider.user!.token,
        _areaSeleccionada!.id,
        DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!),
      );

      debugPrint('✅ Debug: Horarios obtenidos: ${data['horarios_disponibles'].length}');

      setState(() {
        _horariosDisponibles = data['horarios_disponibles'] as List<HorarioDisponible>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Debug: Error consultando disponibilidad: $e');
      
      String errorMessage = 'Error al consultar disponibilidad: $e';
      
      // Manejar errores específicos
      if (e.toString().contains('Sesión expirada')) {
        errorMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      } else if (e.toString().contains('Error de conexión')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      }
      
      setState(() {
        _error = errorMessage;
        _loading = false;
        _horariosDisponibles = [];
      });
    }
  }

  void _reservarHorario(HorarioDisponible horario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaReservaPage(
          areasComunes: widget.areasComunes,
          onReservaCreada: () {
            widget.onReservaCreada();
            Navigator.pop(context);
          },
          areaPreSeleccionada: _areaSeleccionada,
          fechaPreSeleccionada: _fechaSeleccionada,
          horaInicioPreSeleccionada: _parseTimeOfDay(horario.horaInicio),
          horaFinPreSeleccionada: _parseTimeOfDay(horario.horaFin),
        ),
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _horariosDisponibles = []; // Limpiar horarios al cambiar fecha
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Disponibilidad'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección de área
              Text(
                'Área Común',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AreaComun>(
                  initialValue: _areaSeleccionada,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un área',
                ),
                items: widget.areasComunes
                    .where((area) => area.estado)
                    .map((area) => DropdownMenuItem(
                          value: area,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(area.nombre),
                              Text(
                                area.tipo,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (AreaComun? value) {
                  setState(() {
                    _areaSeleccionada = value;
                    _horariosDisponibles = []; // Limpiar horarios al cambiar área
                  });
                },
              ),
              const SizedBox(height: 24),

              // Selección de fecha
              Text(
                'Fecha',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _fechaSeleccionada != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)
                            : 'Selecciona una fecha',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón consultar
              CustomButton(
                text: 'Consultar Disponibilidad',
                onPressed: _consultarDisponibilidad,
                isLoading: _loading,
              ),
              const SizedBox(height: 24),

              // Mostrar error si existe
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mostrar horarios disponibles
              if (_horariosDisponibles.isNotEmpty) ...[
                Text(
                  'Horarios Disponibles para ${_areaSeleccionada?.nombre} - ${_fechaSeleccionada != null ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!) : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _horariosDisponibles.length,
                  itemBuilder: (context, index) {
                    final horario = _horariosDisponibles[index];
                    return Card(
                      child: InkWell(
                        onTap: () => _reservarHorario(horario),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                horario.horarioTexto,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Disponible',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ] else if (_areaSeleccionada != null && _fechaSeleccionada != null && !_loading) ...[
                // Mostrar mensaje si no hay horarios disponibles
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay horarios disponibles',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay horarios libres para la fecha seleccionada',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
