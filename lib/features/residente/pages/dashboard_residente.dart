import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

class DashboardResidente extends StatelessWidget {
  const DashboardResidente({super.key});

  String _getWelcomeMessage(String rol) {
    switch (rol.toLowerCase()) {
      case 'residente':
        return 'Bienvenido a tu portal de residente';
      case 'empleado':
        return 'Bienvenido al portal de empleados';
      case 'seguridad':
        return 'Bienvenido al portal de seguridad';
      default:
        return 'Bienvenido al portal del condominio';
    }
  }

  String _getPageTitle(String rol) {
    switch (rol.toLowerCase()) {
      case 'residente':
        return 'Portal Residente';
      case 'empleado':
        return 'Portal Empleado';
      case 'seguridad':
        return 'Portal Seguridad';
      default:
        return 'Condominio App';
    }
  }

  List<Widget> _getMenuOptionsForRole(BuildContext context, String rol) {
    switch (rol.toLowerCase()) {
      case 'residente':
        return _getResidenteMenuOptions(context);
      case 'empleado':
        return _getEmpleadoMenuOptions(context);
      case 'seguridad':
        return _getSeguridadMenuOptions(context);
      default:
        return _getDefaultMenuOptions(context);
    }
  }

  List<Widget> _getResidenteMenuOptions(BuildContext context) {
    return [
      _buildMenuCard(
        context,
        'Comunicados',
        Icons.announcement,
        Colors.blue,
        () => _showComingSoon(context, 'Comunicados'),
      ),
      _buildMenuCard(
        context,
        'Mis Finanzas',
        Icons.account_balance_wallet,
        Colors.green,
        () => _showComingSoon(context, 'Mis Finanzas'),
      ),
      _buildMenuCard(
        context,
        'Reservas',
        Icons.event,
        Colors.orange,
        () {
          debugPrint('🔍 Debug: Navegando a reservas...');
          context.go('/reservas');
        },
      ),
      _buildMenuCard(
        context,
        'Historial',
        Icons.history,
        Colors.purple,
        () => _showComingSoon(context, 'Historial'),
      ),
      _buildMenuCard(
        context,
        'Visitas',
        Icons.people,
        Colors.teal,
        () => _showComingSoon(context, 'Visitas'),
      ),
      _buildMenuCard(
        context,
        'Reclamos',
        Icons.report_problem,
        Colors.red,
        () => _showComingSoon(context, 'Reclamos'),
      ),
    ];
  }

  List<Widget> _getEmpleadoMenuOptions(BuildContext context) {
    return [
      _buildMenuCard(
        context,
        'Gestión',
        Icons.admin_panel_settings,
        Colors.blue,
        () => _showComingSoon(context, 'Gestión'),
      ),
      _buildMenuCard(
        context,
        'Residentes',
        Icons.people,
        Colors.green,
        () => _showComingSoon(context, 'Gestión de Residentes'),
      ),
      _buildMenuCard(
        context,
        'Finanzas',
        Icons.account_balance,
        Colors.orange,
        () => _showComingSoon(context, 'Gestión Financiera'),
      ),
      _buildMenuCard(
        context,
        'Reportes',
        Icons.assessment,
        Colors.purple,
        () => _showComingSoon(context, 'Reportes'),
      ),
      _buildMenuCard(
        context,
        'Mantenimiento',
        Icons.build,
        Colors.teal,
        () => _showComingSoon(context, 'Mantenimiento'),
      ),
      _buildMenuCard(
        context,
        'Comunicados',
        Icons.campaign,
        Colors.red,
        () => _showComingSoon(context, 'Comunicados'),
      ),
    ];
  }

  List<Widget> _getSeguridadMenuOptions(BuildContext context) {
    return [
      _buildMenuCard(
        context,
        'Accesos',
        Icons.security,
        Colors.blue,
        () => _showComingSoon(context, 'Control de Accesos'),
      ),
      _buildMenuCard(
        context,
        'Visitas',
        Icons.people_alt,
        Colors.green,
        () => _showComingSoon(context, 'Gestión de Visitas'),
      ),
      _buildMenuCard(
        context,
        'Vehículos',
        Icons.directions_car,
        Colors.orange,
        () => _showComingSoon(context, 'Control Vehicular'),
      ),
      _buildMenuCard(
        context,
        'Incidentes',
        Icons.warning,
        Colors.red,
        () => _showComingSoon(context, 'Incidentes'),
      ),
      _buildMenuCard(
        context,
        'Reportes',
        Icons.assessment,
        Colors.purple,
        () => _showComingSoon(context, 'Reportes de Seguridad'),
      ),
      _buildMenuCard(
        context,
        'Cámaras',
        Icons.videocam,
        Colors.teal,
        () => _showComingSoon(context, 'Sistema de Cámaras'),
      ),
    ];
  }

  List<Widget> _getDefaultMenuOptions(BuildContext context) {
    return [
      _buildMenuCard(
        context,
        'Información',
        Icons.info,
        Colors.blue,
        () => _showComingSoon(context, 'Información'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar autenticación
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Verificar si puede acceder desde móvil
        if (!authProvider.canAccessMobile) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authProvider.user;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle(user?.rol ?? '')),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Saludo personalizado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${user?.username ?? 'Usuario'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getWelcomeMessage(user?.rol ?? ''),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rol: ${user?.rol ?? 'No definido'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Información del usuario
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de tu cuenta',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Usuario', user?.username ?? 'N/A'),
                        _buildInfoRow('Email', user?.email ?? 'N/A'),
                        _buildInfoRow('Rol', user?.rol ?? 'N/A'),
                        if (user?.residenteId != null)
                          _buildInfoRow('ID Residente', user!.residenteId.toString()),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Menú de opciones específicas por rol
                Text(
                  'Opciones disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: _getMenuOptionsForRole(context, user?.rol ?? ''),
                ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Text('¿Qué quieres hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData(context);
            },
            child: const Text('Limpiar datos'),
          ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar datos'),
        content: const Text('Esto eliminará todos los datos guardados y te llevará al login. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Limpiar datos y forzar logout
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              // Forzar reinicio de la app
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Próximamente'),
        content: Text('La funcionalidad de $feature estará disponible pronto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
