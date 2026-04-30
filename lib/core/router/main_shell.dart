import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// 하단 탭 네비게이션을 포함하는 ShellRoute 래퍼 위젯
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, label: '캘린더', route: AppRoutes.home),
    (icon: Icons.dynamic_feed_outlined,   label: '피드',   route: AppRoutes.feed),
    (icon: Icons.people_outline,          label: '친구',   route: AppRoutes.friends),
    (icon: Icons.person_outline,          label: '내 정보', route: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.feed))    return 1;
    if (location.startsWith(AppRoutes.friends)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].route),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
