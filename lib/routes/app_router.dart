import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/residente/pages/dashboard_residente.dart';
import '../features/empleado/pages/dashboard_empleado.dart';
import '../features/seguridad/pages/dashboard_seguridad.dart';
import '../features/residente/pages/reservas_page.dart';
import '../features/common/splash_page.dart';
import '../widgets/role_router.dart';
import '../features/residente/pages/comunicados_page.dart';
import '../features/common/pages/comunicados_leidos_page.dart';
import '../features/residente/pages/invitados_page.dart';
import '../features/seguridad/pages/invitados_seguridad_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.uri.path == '/dashboard') {
        return null;
      }
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
      GoRoute(
        path: '/comunicados-leidos',
        builder: (context, state) => const ComunicadosLeidosPage(),
      ),
      GoRoute(
        path: '/invitados',
        builder: (context, state) => const InvitadosPage(),
      ),
      GoRoute(
        path: '/invitados-seguridad',
        builder: (context, state) => const InvitadosSeguridadPage(),
      ),
    ],
  );

  static GoRouter get router => _router;
}
