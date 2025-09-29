import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/residente/pages/dashboard_residente.dart';
import '../features/empleado/pages/dashboard_empleado.dart';
import '../features/seguridad/pages/dashboard_seguridad.dart';
import '../features/residente/pages/reservas_page.dart';
import '../features/common/splash_page.dart';
import '../widgets/role_router.dart';
import '../features/residente/pages/comunicados_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Solo redirigir si estamos en una ruta protegida sin autenticación
      if (state.uri.path == '/dashboard') {
        // Permitir acceso al dashboard - la lógica de autenticación se maneja en las páginas
        return null;
      }
      
      // No redirigir automáticamente
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const RoleRouter(),
      ),
      GoRoute(
        path: '/dashboard-residente',
        builder: (context, state) => const DashboardResidente(),
      ),
      GoRoute(
        path: '/dashboard-empleado',
        builder: (context, state) => const DashboardEmpleado(),
      ),
      GoRoute(
        path: '/dashboard-seguridad',
        builder: (context, state) => const DashboardSeguridad(),
      ),
      GoRoute(
        path: '/reservas',
        builder: (context, state) => const ReservasPage(),
      ),
      GoRoute(
        path: '/comunicados',
        builder: (context, state) => const ComunicadosPage(),
      ),
    ],
  );

  static GoRouter get router => _router;
}
