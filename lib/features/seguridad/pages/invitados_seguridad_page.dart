import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/invitado_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/invitados_service.dart';

class InvitadosSeguridadPage extends StatefulWidget {
  const InvitadosSeguridadPage({super.key});
  @override
  State<InvitadosSeguridadPage> createState() => _InvitadosSeguridadPageState();
}

class _InvitadosSeguridadPageState extends State<InvitadosSeguridadPage>{
  bool _loading = true;
  String? _error;
  List<Invitado> _items = [];

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen:false);
    if(auth.user?.token==null){ setState(()=>_error='Sesión inválida'); return; }
    try{
      setState((){ _loading=true; _error=null; });
      final data = await InvitadosService.listarParaSeguridad(auth.user!.token);
      data.sort((a,b)=> (a.nombre).toLowerCase().compareTo((b.nombre).toLowerCase()));
      setState(()=> _items = data);
    }catch(e){ setState(()=> _error = e.toString()); }
    finally{ setState(()=> _loading=false); }
  }

  String _fmtDt(DateTime? dt){ if (dt==null) return '-'; return DateFormat('dd/MM/yyyy HH:mm').format(dt); }

  Future<void> _checkIn(Invitado inv) async {
    final auth = Provider.of<AuthProvider>(context, listen:false);
    if(auth.user?.token==null) return;
    try{
      await InvitadosService.marcarEntrada(auth.user!.token, inv.id);
      _load();
    }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  Future<void> _checkOut(Invitado inv) async {
    final auth = Provider.of<AuthProvider>(context, listen:false);
    if(auth.user?.token==null) return;
    try{
      await InvitadosService.marcarSalida(auth.user!.token, inv.id);
      _load();
    }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitados - Seguridad'),
        backgroundColor: theme.primaryColor, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> context.go('/dashboard')),
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: _load) ],
      ),
      body: _loading
        ? const Center(child:CircularProgressIndicator())
        : _error!=null
          ? Center(child: Text(_error!, style: theme.textTheme.bodyMedium))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (ctx,i){
                  final inv = _items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom:12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, child: Icon(inv.tipo.toLowerCase()=='evento'? Icons.event: Icons.badge)),
                      title: Text(inv.nombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                        Text('CI: ${inv.ci} • Placa: ${inv.placa ?? '-'} • Tipo: ${inv.tipo}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
                        if (inv.residenteNombre != null) Text('Residente: ${inv.residenteNombre}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                        const SizedBox(height:4),
                        Row(children:[
                          Icon(Icons.login, size:14, color: Colors.grey[700]), const SizedBox(width:4), Text(_fmtDt(inv.horaEntrada), style: theme.textTheme.bodySmall),
                          const SizedBox(width:12),
                          Icon(Icons.logout, size:14, color: Colors.grey[700]), const SizedBox(width:4), Text(_fmtDt(inv.horaSalida), style: theme.textTheme.bodySmall),
                        ])
                      ]),
                      trailing: Wrap(spacing:8, children: [
                        ElevatedButton.icon(
                          onPressed: inv.horaEntrada==null? ()=>_checkIn(inv): null,
                          icon: const Icon(Icons.login, size:16), label: const Text('Entrada'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(90,36)),
                        ),
                        ElevatedButton.icon(
                          onPressed: inv.horaEntrada!=null && inv.horaSalida==null? ()=>_checkOut(inv): null,
                          icon: const Icon(Icons.logout, size:16), label: const Text('Salida'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(90,36)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

