import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'unified_dashboard.dart';

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

        // Usar UnifiedDashboard para todos los roles
        return const UnifiedDashboard();
      },
    );
  }
}





