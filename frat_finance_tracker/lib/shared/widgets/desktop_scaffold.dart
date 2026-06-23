import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  } catch (_) {
    return false;
  }
}

/// Mobile scaffold with a Material 3 [NavigationBar] at the bottom.
class MobileScaffold extends ConsumerWidget {
  final Widget body;
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const MobileScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isVP = currentUser?.role == UserRole.vpFinance;

    int currentIndex = 0;
    if (isVP) {
      if (currentRoute == '/brother-management') currentIndex = 1;
      else if (currentRoute == '/dashboard') currentIndex = 2;
      else if (currentRoute == '/profile') currentIndex = 3;
    } else {
      if (currentRoute == '/profile') currentIndex = 1;
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline),
          NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (isVP) {
              switch (index) {
                case 0: { context.go('/vp-dashboard'); }
                case 1: { context.go('/brother-management'); }
                case 2: { context.go('/dashboard'); }
                case 3: { context.go('/profile'); }
              }
            } else {
              switch (index) {
                case 0: { context.go('/dashboard'); }
                case 1: { context.go('/profile'); }
              }
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: isVP ? 'Overview' : 'My Dues',
            ),
            if (isVP) ...[
              const NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Brothers',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'My Dues',
              ),
            ],
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
        ],
      ),
    );
  }
}

class DesktopScaffold extends ConsumerWidget {
  final Widget body;
  final String currentRoute;
  final VoidCallback? onCreateDues;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.onCreateDues,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktopPlatform) {
      return Scaffold(body: body);
    }

    final currentUser = ref.watch(currentUserProvider);
    final isVP = currentUser?.role == UserRole.vpFinance;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: _DesktopSidebar(
              isVP: isVP,
              currentUser: currentUser,
              currentRoute: currentRoute,
              onCreateDues: onCreateDues,
            ),
          ),
          Expanded(
            child: ClipRect(child: body),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final bool isVP;
  final AppUser? currentUser;
  final String currentRoute;
  final VoidCallback? onCreateDues;

  const _DesktopSidebar({
    required this.isVP,
    required this.currentUser,
    required this.currentRoute,
    this.onCreateDues,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF162050),
        border: Border(
          right: BorderSide(color: Color(0xFF243060), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App branding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEAA00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance,
                        color: Color(0xFF1E3A8A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frat Finance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Tracker',
                      style: TextStyle(
                        color: Color(0xFFEEAA00),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Create Dues button (VP only)
          if (isVP && onCreateDues != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onCreateDues,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Create Dues'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEEAA00),
                    foregroundColor: const Color(0xFF1A1100),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Section label
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Text(
              'NAVIGATION',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.28),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),

          // Nav items
          _NavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Dashboard',
            route: isVP ? '/vp-dashboard' : '/dashboard',
            currentRoute: currentRoute,
          ),
          if (isVP) ...[
            _NavItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Brothers',
              route: '/brother-management',
              currentRoute: currentRoute,
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'My Dues',
              route: '/dashboard',
              currentRoute: currentRoute,
              isVPViewingDashboard: currentRoute == '/vp-dashboard',
            ),
          ],
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            route: '/profile',
            currentRoute: currentRoute,
          ),

          const Spacer(),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),

          // User footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Row(
              children: [
                _UserAvatar(name: currentUser?.fullName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        isVP ? 'VP of Finance' : 'Brother',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                _SidebarIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Sign out',
                  onTap: () async => await authRepo.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? name;
  const _UserAvatar({this.name});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A9A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 15,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isVPViewingDashboard;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.isVPViewingDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route && !isVPViewingDashboard;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(9),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 18,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                    letterSpacing: -0.1,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEAA00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
