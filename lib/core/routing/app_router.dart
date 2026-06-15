import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainDashboardScreen(initialTab: 0),
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => const MainDashboardScreen(initialTab: 1),
    ),
    GoRoute(
      path: '/converters',
      builder: (context, state) => const MainDashboardScreen(initialTab: 2),
    ),
  ],
);
