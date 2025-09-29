import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/residente/pages/dashboard_residente.dart';
import '../features/empleado/pages/dashboard_empleado.dart';
import '../features/seguridad/pages/dashboard_seguridad.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        if (user == null) {
          // Si no hay usuario, redirigir al login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirigir según el rol
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user.isResidente) {
            context.go('/dashboard-residente');
          } else if (user.isEmpleado) {
            context.go('/dashboard-empleado');
          } else if (user.isSeguridad) {
            context.go('/dashboard-seguridad');
          } else {
            // Rol no reconocido, mostrar mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rol no soportado: ${user.rol}'),
                backgroundColor: Colors.red,
              ),
            );
            context.go('/login');
          }
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}





