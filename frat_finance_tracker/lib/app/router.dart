import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frat_finance_tracker/features/auth/presentation/login_screen.dart';
import 'package:frat_finance_tracker/features/auth/presentation/change_password_screen.dart';
import 'package:frat_finance_tracker/features/dashboard/presentation/brother_dashboard.dart';
import 'package:frat_finance_tracker/features/dashboard/presentation/vp_dashboard.dart';
import 'package:frat_finance_tracker/features/dashboard/presentation/brother_management_screen.dart';
import 'package:frat_finance_tracker/features/notifications/presentation/notifications_screen.dart';
import 'package:frat_finance_tracker/features/profile/presentation/profile_screen.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';

/// Builds a page with a smooth fade + slight upward slide transition.
/// The sidebar is visually identical across all main routes, so this gives
/// the impression of the sidebar staying in place while content changes.
Page<void> _fadeSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: fade, child: child);
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnLoginScreen = state.matchedLocation == '/login';
      final isChangingPassword = state.matchedLocation == '/change-password';
      final isOnVPDashboard = state.matchedLocation == '/vp-dashboard';

      // If not logged in and not on login screen, redirect to login
      if (!isLoggedIn && !isOnLoginScreen) {
        return '/login';
      }

      // If logged in, check if password change is required
      if (isLoggedIn) {
        final user = authState.value;

        // If user must change password and not already on change password screen
        // IMPORTANT: Don't redirect if we're on VP dashboard (prevents flashing during user creation)
        if (user?.mustChangePassword == true && !isChangingPassword && !isOnVPDashboard) {
          return '/change-password';
        }

        // If on change password screen but doesn't need to change password, redirect to dashboard
        if (isChangingPassword && user?.mustChangePassword != true) {
          final userRole = user?.role;
          return userRole == UserRole.vpFinance ? '/vp-dashboard' : '/dashboard';
        }

        // If on login screen and doesn't need password change, redirect to dashboard
        if (isOnLoginScreen) {
          final userRole = user?.role;
          return userRole == UserRole.vpFinance ? '/vp-dashboard' : '/dashboard';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth routes (no custom transition needed)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Brother dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _fadeSlidePage(const BrotherDashboard(), state),
      ),

      // VP of Finance dashboard
      GoRoute(
        path: '/vp-dashboard',
        name: 'vp-dashboard',
        pageBuilder: (context, state) => _fadeSlidePage(const VPDashboard(), state),
      ),

      // Brother management
      GoRoute(
        path: '/brother-management',
        name: 'brother-management',
        pageBuilder: (context, state) => _fadeSlidePage(const BrotherManagementScreen(), state),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _fadeSlidePage(const ProfileScreen(), state),
      ),
    ],
  );
});
