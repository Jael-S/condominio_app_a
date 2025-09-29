import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/reservas_service.dart';
import '../../../models/area_comun_model.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

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

  AreaComun? _areaSeleccionada;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con valores pre-seleccionados si existen
    _areaSeleccionada = widget.areaPreSeleccionada;
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
    if (_areaSeleccionada == null) {
      _showError('Selecciona un área común');
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
      final reservaData = {
        'area': _areaSeleccionada!.id,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!),
        'hora_inicio': '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}',
        'hora_fin': '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}',
        'motivo': _motivoController.text.trim().isEmpty ? null : _motivoController.text.trim(),
        'costo': 0.0,
      };

      debugPrint('🔍 Debug: Creando reserva con datos: $reservaData');
      final reservaCreada = await ReservasService.crearReserva(authProvider.user!.token, reservaData);
      debugPrint('✅ Debug: Reserva creada exitosamente: ${reservaCreada.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva creada exitosamente para ${_areaSeleccionada!.nombre}'),
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
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un área común';
                    }
                    return null;
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

                // Selección de horarios
                Text(
                  'Horario',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _seleccionarHoraInicio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 12),
                              Text(
                                _horaInicio != null
                                    ? _horaInicio!.format(context)
                                    : 'Hora inicio',
                                style: Theme.of(context).textTheme.bodyLarge,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 12),
                              Text(
                                _horaFin != null
                                    ? _horaFin!.format(context)
                                    : 'Hora fin',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Motivo de la reserva
                CustomTextField(
                  controller: _motivoController,
                  labelText: 'Motivo de la reserva (opcional)',
                  hintText: 'Describe el motivo de tu reserva',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Botón crear reserva
                CustomButton(
                  text: 'Crear Reserva',
                  onPressed: _crearReserva,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
