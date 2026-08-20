import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/tour_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tour.dart';
import 'head_dashboard_page.dart';
import 'head_profile_page.dart';
import 'head_proofs_page.dart';
import 'head_tasks_page.dart';
import 'head_workers_page.dart';

class HeadShell extends StatefulWidget {
  const HeadShell({super.key});

  @override
  State<HeadShell> createState() => _HeadShellState();
}

class _HeadShellState extends State<HeadShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // First-login guided tour.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    final user = AuthService.instance.user;
    if (user == null || !user.isHead || !mounted) return;
    if (await TourService.instance.hasSeen(user.id)) return;
    await AppTour.start(context, steps: _headTourSteps());
    if (mounted) await TourService.instance.markSeen(user.id);
  }

  List<TourStep> _headTourSteps() {
    final tabs = AppTour.navTabRects(count: 5);
    final tiles = AppTour.statTileRects();
    return [
      const TourStep(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Welcome, Head! 🏛️',
        description:
            'A quick tour of the Head Portal — let\'s go! You can skip anytime.',
      ),
      if (tabs.length == 5) ...[TourStep(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard — Command Center',
        description:
            'Workers, active tasks, completed tasks and pending proofs — all at a glance.',
        targetBuilder: AppTour.tabTarget(0, 5),
      ), TourStep(
        icon: Icons.groups_outlined,
        title: 'Workers Tab',
        description:
            'Manage workers, generate Worker IDs and see their live duty status.',
        targetBuilder: AppTour.tabTarget(1, 5),
      ), TourStep(
        icon: Icons.assignment_outlined,
        title: 'Tasks Tab',
        description:
            'Assign collection tasks to workers and revoke them before they start.',
        targetBuilder: AppTour.tabTarget(2, 5),
      ), TourStep(
        icon: Icons.photo_library_outlined,
        title: 'Proofs Tab',
        description:
            'Review proof photos submitted by workers — approve or send back.',
        targetBuilder: AppTour.tabTarget(3, 5),
      ), TourStep(
        icon: Icons.person_outline,
        title: 'Profile Tab',
        description:
            'Broadcast notifications to citizens, check help and the user manual.',
        targetBuilder: AppTour.tabTarget(4, 5),
      )],
      if (tiles.length == 4) ...[TourStep(
        icon: Icons.groups_outlined,
        title: 'Workers',
        description: 'Total workers currently in your team.',
        targetBuilder: AppTour.statTarget(0),
      ), TourStep(
        icon: Icons.assignment_outlined,
        title: 'Active Tasks',
        description: 'Tasks currently assigned and in progress.',
        targetBuilder: AppTour.statTarget(1),
      ), TourStep(
        icon: Icons.check_circle_outline,
        title: 'Completed',
        description: 'Tasks finished and marked resolved.',
        targetBuilder: AppTour.statTarget(2),
      ), TourStep(
        icon: Icons.photo_library_outlined,
        title: 'Pending Proofs',
        description: 'Proof photos waiting for your review.',
        targetBuilder: AppTour.statTarget(3),
      )],
      const TourStep(
        icon: Icons.celebration_outlined,
        title: 'You\'re all set! 🎉',
        description:
            'Approve complaints, manage your workers and keep the city clean. Good luck!',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild all tabs when the theme changes so every AppColors.* color
    // switches instantly without a page refresh.
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, _, __) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              // Non-const: new instances each build so the tabs re-render
              // instantly when the theme toggles (const would be skipped).
              HeadDashboardPage(),
              HeadWorkersPage(),
              HeadTasksPage(),
              HeadProofsPage(),
              HeadProfilePage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            key: TourKeys.navBarKey,
            selectedIndex: _currentIndex,
            onDestinationSelected:
                (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.cardColor,
            indicatorColor: AppColors.paleGreen,
            destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: AppStrings.of(context).navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: AppStrings.of(context).navWorkers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: AppStrings.of(context).navTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: const Icon(Icons.photo_library),
            label: AppStrings.of(context).navProofs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: AppStrings.of(context).navProfile,
          ),
            ],
          ),
        );
        },
    );
  }
}
