import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/invitado_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/invitados_service.dart';

class InvitadosPage extends StatefulWidget {
  const InvitadosPage({super.key});

  @override
  State<InvitadosPage> createState() => _InvitadosPageState();
}

class _InvitadosPageState extends State<InvitadosPage> {
  bool _loading = true;
  String? _error;
  List<Invitado> _invitados = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.token == null) {
      setState(() { _error = 'Sesión no válida'; _loading = false; });
      return;
    }
    try {
      setState(() { _loading = true; _error = null; });
      final items = await InvitadosService.listarDelResidente(auth.user!.token);
      // Robustez extra por si en algún entorno regresan enteros u objetos atípicos
      // ignore: unnecessary_cast
      final safe = (items as List).map((e){
        if (e is Invitado) return e;
        return Invitado.fromAny(e);
      }).toList();
      // Orden estable por nombre para mejor lectura
      safe.sort((a,b)=> (a.nombre).toLowerCase().compareTo((b.nombre).toLowerCase()));
      setState(() { _invitados = safe; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _healthCheck() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.user?.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión no válida')),
        );
      }
      return;
    }
    try {
      final list = await InvitadosService.listarDelResidente(token);
      debugPrint('🔎 HealthCheck Invitados: count=${list.length}');
      for (var i = 0; i < (list.length < 3 ? list.length : 3); i++) {
        final inv = list[i];
        debugPrint('  • [${inv.id}] ${inv.nombre} | CI=${inv.ci} | tipo=${inv.tipo} | placa=${inv.placa ?? '-'}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitados: ${list.length} (ver consola)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HealthCheck error: $e')),
        );
      }
    }
  }

  void _abrirFormulario() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx){
        return _InvitadoBottomSheet(onSaved: (Invitado inv){ Navigator.pop(ctx, inv); });
      }
    );
    if (result is Invitado) {
      // Optimista: insertar al inicio y luego refrescar silencioso
      setState((){ _invitados = [result, ..._invitados]; _error = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitado registrado correctamente')),
        );
      }
      // Refresh para sincronizar
      _load();
    }
  }

  String _fmtDt(DateTime? dt){ if (dt==null) return '-'; return DateFormat('dd/MM/yyyy HH:mm').format(dt); }

  Color _estadoColor(String s){
    switch(s){
      case 'en_casa': return Colors.green;
      case 'finalizado': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitados'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> context.go('/dashboard')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refrescar'),
          IconButton(icon: const Icon(Icons.health_and_safety), onPressed: _healthCheck, tooltip: 'Health check'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.person_add),
        label: const Text('Registrar Invitado'),
        backgroundColor: theme.primaryColor, foregroundColor: Colors.white,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error!=null
          ? Center(child: Text(_error!, style: theme.textTheme.bodyMedium))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _invitados.length,
                itemBuilder: (ctx, i){
                  final inv = _invitados[i];
                  final displayNombre = (inv.nombre).isEmpty ? '(sin nombre)' : inv.nombre;
                  final displayCi = (inv.ci).isEmpty ? '—' : inv.ci;
                  final displayPlaca = (inv.placa==null || inv.placa!.isEmpty) ? '-' : inv.placa!;
                  final displayTipo = (inv.tipo).isEmpty ? 'casual' : inv.tipo;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        child: Icon(displayTipo.toLowerCase()=='evento'? Icons.event: Icons.badge),
                      ),
                      title: Text(displayNombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('CI: $displayCi • Placa: $displayPlaca • Tipo: $displayTipo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
                        const SizedBox(height:4),
                        Row(children:[
                          Icon(Icons.login, size:14, color: Colors.grey[700]), const SizedBox(width:4), Text(_fmtDt(inv.horaEntrada), style: theme.textTheme.bodySmall),
                          const SizedBox(width:12),
                          Icon(Icons.logout, size:14, color: Colors.grey[700]), const SizedBox(width:4), Text(_fmtDt(inv.horaSalida), style: theme.textTheme.bodySmall),
                        ]),
                      ]),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
                        decoration: BoxDecoration(color: _estadoColor(inv.estado).withOpacity(.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _estadoColor(inv.estado)) ),
                        child: Text(inv.estado.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _FormularioInvitado extends StatefulWidget {
  const _FormularioInvitado();
  @override
  State<_FormularioInvitado> createState() => _FormularioInvitadoState();
}

class _FormularioInvitadoState extends State<_FormularioInvitado>{
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  String _tipo = 'casual';
  final _placaCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose(){
    _nombreCtrl.dispose(); _ciCtrl.dispose(); _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if(!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen:false);
    if (auth.user?.token == null) return;
    try{
      setState(()=> _saving = true);
      final inv = Invitado(id:0, nombre:_nombreCtrl.text.trim(), ci:_ciCtrl.text.trim(), tipo:_tipo, placa: _placaCtrl.text.trim().isEmpty? null : _placaCtrl.text.trim(), estado: 'pendiente');
      await InvitadosService.crearInvitado(auth.user!.token, inv);
      if(mounted){ Navigator.pop(context, true); }
    }catch(e){
      if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }finally{ if(mounted) setState(()=> _saving=false); }
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Invitado'),
        backgroundColor: theme.primaryColor, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> Navigator.of(context).pop(false)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(children: [
            TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v)=> v==null||v.trim().isEmpty? 'Requerido' : null),
            TextFormField(controller: _ciCtrl, decoration: const InputDecoration(labelText: 'CI'), validator: (v)=> v==null||v.trim().isEmpty? 'Requerido' : null),
            DropdownButtonFormField<String>(
              value: _tipo,
              items: const [ DropdownMenuItem(value:'evento', child: Text('Evento')), DropdownMenuItem(value:'casual', child: Text('Casual')) ],
              onChanged: (v){ if(v!=null) setState(()=> _tipo=v); },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            TextFormField(controller: _placaCtrl, decoration: const InputDecoration(labelText: 'Placa (opcional)')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('Guardar'),
              ),
            )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitadoBottomSheet extends StatefulWidget{
  final void Function(Invitado inv) onSaved;
  const _InvitadoBottomSheet({required this.onSaved});
  @override
  State<_InvitadoBottomSheet> createState() => _InvitadoBottomSheetState();
}

class _InvitadoBottomSheetState extends State<_InvitadoBottomSheet>{
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  String _tipo = 'casual';
  bool _saving = false;

  @override
  void dispose(){
    _nombreCtrl.dispose(); _ciCtrl.dispose(); _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if(!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen:false);
    if (auth.user?.token == null) return;
    try{
      setState(()=> _saving = true);
      final inv = Invitado(
        id:0,
        nombre:_nombreCtrl.text.trim(),
        ci:_ciCtrl.text.trim(),
        tipo:_tipo,
        placa:_placaCtrl.text.trim().isEmpty? null : _placaCtrl.text.trim(),
        evento: null,
        estado:'pendiente'
      );
      final creado = await InvitadosService.crearInvitado(auth.user!.token, inv);
      if(mounted){ widget.onSaved(creado); }
    }catch(e){
      if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    }finally{ if(mounted) setState(()=> _saving=false); }
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,-4))]
      ),
      child: Padding(
        padding: EdgeInsets.only(left:16, right:16, top:12, bottom: 16 + viewInsets),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Registrar Invitado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  IconButton(onPressed: ()=> Navigator.pop(context, false), icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v)=> v==null||v.trim().isEmpty? 'Requerido' : null,
              ),
              TextFormField(
                controller: _ciCtrl,
                decoration: const InputDecoration(labelText: 'CI'),
                validator: (v)=> v==null||v.trim().isEmpty? 'Requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                items: const [ DropdownMenuItem(value:'evento', child: Text('Evento')), DropdownMenuItem(value:'casual', child: Text('Casual')) ],
                onChanged: (v){ if(v!=null) setState(()=> _tipo=v); },
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                controller: _placaCtrl,
                decoration: const InputDecoration(labelText: 'Placa (opcional)'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving? null : _guardar,
                  icon: _saving? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.save),
                  label: Text(_saving? 'Guardando...' : 'Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
