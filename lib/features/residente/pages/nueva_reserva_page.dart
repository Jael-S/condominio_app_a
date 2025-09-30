import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/reservas_service.dart';
import '../../../models/area_comun_model.dart';
import '../../../widgets/loading_overlay.dart';

class NuevaReservaPage extends StatefulWidget {
  final List<AreaComun> areasComunes;
  final VoidCallback onReservaCreada;
  final AreaComun? areaPreSeleccionada;
  final DateTime? fechaPreSeleccionada;
  final TimeOfDay? horaInicioPreSeleccionada;
  final TimeOfDay? horaFinPreSeleccionada;

  const NuevaReservaPage({
    super.key,
    required this.areasComunes,
    required this.onReservaCreada,
    this.areaPreSeleccionada,
    this.fechaPreSeleccionada,
    this.horaInicioPreSeleccionada,
    this.horaFinPreSeleccionada,
  });

  @override
  State<NuevaReservaPage> createState() => _NuevaReservaPageState();
}

class _NuevaReservaPageState extends State<NuevaReservaPage> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();

  List<AreaComun> _areasSeleccionadas = [];
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar locale para fechas en español
    initializeDateFormatting('es', null);
    
    // Inicializar con valores pre-seleccionados si existen
    if (widget.areaPreSeleccionada != null) {
      _areasSeleccionadas = [widget.areaPreSeleccionada!];
    }
    _fechaSeleccionada = widget.fechaPreSeleccionada;
    _horaInicio = widget.horaInicioPreSeleccionada;
    _horaFin = widget.horaFinPreSeleccionada;
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _crearReserva() async {
    if (!_formKey.currentState!.validate()) return;
    if (_areasSeleccionadas.isEmpty) {
      _showError('Selecciona al menos un área común');
      return;
    }
    if (_fechaSeleccionada == null) {
      _showError('Selecciona una fecha');
      return;
    }
    if (_horaInicio == null || _horaFin == null) {
      _showError('Selecciona hora de inicio y fin');
      return;
    }
    if (_horaInicio!.hour >= _horaFin!.hour) {
      _showError('La hora de fin debe ser posterior a la hora de inicio');
      return;
    }

    // Validar que la fecha no sea en el pasado
    final now = DateTime.now();
    final fechaReserva = DateTime(_fechaSeleccionada!.year, _fechaSeleccionada!.month, _fechaSeleccionada!.day);
    final fechaActual = DateTime(now.year, now.month, now.day);
    
    if (fechaReserva.isBefore(fechaActual)) {
      _showError('No puedes hacer reservas para fechas pasadas');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) {
      _showError('No hay sesión activa');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Crear una reserva por cada área seleccionada
      int reservasCreadas = 0;
      for (final area in _areasSeleccionadas) {
        final reservaData = {
          'area': area.id,
          'fecha': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!),
          'hora_inicio': '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}',
          'hora_fin': '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}',
          'motivo': _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
          'costo': 0.0,
        };

        debugPrint('🔍 Debug: Creando reserva para ${area.nombre} con datos: $reservaData');
        final reservaCreada = await ReservasService.crearReserva(authProvider.user!.token, reservaData);
        debugPrint('✅ Debug: Reserva creada exitosamente: ${reservaCreada.id}');
        reservasCreadas++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reservasCreadas reserva(s) creada(s) exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onReservaCreada();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Debug: Error creando reserva: $e');
      if (mounted) {
        String errorMessage = 'Error al crear reserva: $e';
        
        // Manejar errores específicos del backend
        if (e.toString().contains('El horario seleccionado no está disponible')) {
          errorMessage = 'El horario seleccionado no está disponible. Por favor, elige otro horario.';
        } else if (e.toString().contains('Ya existe una reserva para este horario')) {
          errorMessage = 'Ya existe una reserva para este horario. Por favor, elige otro horario.';
        } else if (e.toString().contains('Usuario no es un residente válido')) {
          errorMessage = 'Error de permisos. Por favor, inicia sesión nuevamente.';
        } else if (e.toString().contains('Sesión expirada')) {
          errorMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
        }
        
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _calcularDuracion() {
    if (_horaInicio == null || _horaFin == null) return '';
    
    final inicio = _horaInicio!.hour * 60 + _horaInicio!.minute;
    final fin = _horaFin!.hour * 60 + _horaFin!.minute;
    final duracion = fin - inicio;
    
    if (duracion <= 0) return '0 minutos';
    
    final horas = duracion ~/ 60;
    final minutos = duracion % 60;
    
    if (horas > 0 && minutos > 0) {
      return '${horas}h ${minutos}m';
    } else if (horas > 0) {
      return '${horas}h';
    } else {
      return '${minutos}m';
    }
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
      });
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (hora != null) {
      setState(() {
        _horaInicio = hora;
        // Si la hora de fin es anterior o igual, ajustarla
        if (_horaFin != null && hora.hour >= _horaFin!.hour) {
          _horaFin = TimeOfDay(hour: hora.hour + 1, minute: hora.minute);
        }
      });
    }
  }

  Future<void> _seleccionarHoraFin() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaFin ?? TimeOfDay(
        hour: _horaInicio?.hour != null ? _horaInicio!.hour + 1 : 9,
        minute: _horaInicio?.minute ?? 0,
      ),
    );
    if (hora != null) {
      setState(() {
        _horaFin = hora;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Reserva'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selección de áreas
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Áreas Comunes',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Múltiple',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona una o más áreas comunes:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Column(
                            children: widget.areasComunes
                                .where((area) => area.estado)
                                .map((area) => CheckboxListTile(
                                      title: Text(
                                        area.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        area.tipo,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      value: _areasSeleccionadas.contains(area),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _areasSeleccionadas.add(area);
                                          } else {
                                            _areasSeleccionadas.remove(area);
                                          }
                                        });
                                      },
                                      activeColor: Theme.of(context).primaryColor,
                                    ))
                                .toList(),
                          ),
                        ),
                        if (_areasSeleccionadas.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_areasSeleccionadas.length} área(s) seleccionada(s)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                const SizedBox(height: 24),

                // Selección de fecha
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Fecha de Reserva',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _seleccionarFecha,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fechaSeleccionada != null
                                        ? DateFormat('EEEE, dd/MM/yyyy', 'es').format(_fechaSeleccionada!)
                                        : 'Selecciona una fecha',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: _fechaSeleccionada != null ? FontWeight.w600 : FontWeight.normal,
                                      color: _fechaSeleccionada != null ? Colors.black87 : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selección de horarios
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Horario de Reserva',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _seleccionarHoraInicio,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _horaInicio != null
                                              ? _horaInicio!.format(context)
                                              : 'Hora inicio',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: _horaInicio != null ? FontWeight.w600 : FontWeight.normal,
                                            color: _horaInicio != null ? Colors.black87 : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: _seleccionarHoraFin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.stop, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _horaFin != null
                                              ? _horaFin!.format(context)
                                              : 'Hora fin',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: _horaFin != null ? FontWeight.w600 : FontWeight.normal,
                                            color: _horaFin != null ? Colors.black87 : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_horaInicio != null && _horaFin != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Duración: ${_calcularDuracion()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                const SizedBox(height: 24),

                // Motivo de la reserva
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de la Reserva',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Opcional',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _motivoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe el motivo de tu reserva...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.edit_note),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón crear reserva
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _crearReserva,
                    icon: _loading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      _loading ? 'Creando Reserva...' : 'Crear Reserva',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
