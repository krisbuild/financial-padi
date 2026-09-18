import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/bills/screens/bills_screen.dart';
import '../../features/budgets/screens/budgets_goals_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading && !authState.hasValue;
      final isSignedIn = authState.value != null;
      final goingToAuth = _authRoutes.contains(state.matchedLocation);
      final atSplash = state.matchedLocation == '/splash';

      if (isLoading) return atSplash ? null : '/splash';
      if (!isSignedIn && !goingToAuth) return '/login';
      if (isSignedIn && (goingToAuth || atSplash)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/budgets',
              builder: (context, state) => const BudgetsGoalsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

const _authRoutes = {'/login', '/signup', '/forgot-password'};

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}
