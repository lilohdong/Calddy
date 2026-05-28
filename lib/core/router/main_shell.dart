import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// 하단 탭 네비게이션을 포함하는 ShellRoute 래퍼 위젯
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  // 피드 → 캘린더 → 친구 → 내정보
  static const _tabs = [
    (icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,         label: '홈',    route: AppRoutes.feed),
    (icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,   label: '캘린더', route: AppRoutes.home),
    (icon: Icons.people_outline,      activeIcon: Icons.people_rounded,       label: '친구',   route: AppRoutes.friends),
    (icon: Icons.person_outline,      activeIcon: Icons.person_rounded,       label: '내 정보', route: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home))    return 1;
    if (location.startsWith(AppRoutes.friends)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // feed (default)
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    const purple = Color(0xFF7C6AFA);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].route),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE9FF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon, color: Colors.grey.shade500),
              selectedIcon: Icon(tab.activeIcon, color: purple),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
