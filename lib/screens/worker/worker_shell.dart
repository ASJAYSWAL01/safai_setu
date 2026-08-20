import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../services/tour_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tour.dart';
import 'worker_dashboard_page.dart';
import 'worker_live_map_page.dart';
import 'worker_profile_page.dart';
import 'worker_tasks_page.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _currentIndex = 0;

  final GlobalKey<WorkerTasksPageState> _tasksKey =
      GlobalKey<WorkerTasksPageState>();

  @override
  void initState() {
    super.initState();
    // A tapped "Tasks" push notification switches straight to the Tasks tab.
    NotificationService.instance.workerTabRequest.addListener(_onTabRequest);
    // First-login guided tour.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    final user = AuthService.instance.user;
    if (user == null || !user.isWorker || !mounted) return;
    if (await TourService.instance.hasSeen(user.id)) return;
    await AppTour.start(context, steps: _workerTourSteps());
    if (mounted) await TourService.instance.markSeen(user.id);
  }

  List<TourStep> _workerTourSteps() {
    final tabs = AppTour.navTabRects(count: 4);
    final tiles = AppTour.statTileRects();
    return [
      const TourStep(
        icon: Icons.local_shipping_outlined,
        title: 'Welcome, Worker! 👷',
        description:
            'A quick tour of the Worker Portal — let\'s go! You can skip anytime.',
      ),
      if (tabs.length == 4) ...[TourStep(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard — Your Summary',
        description:
            'Assigned, in-progress, completed tasks and submitted proofs — all in one place.',
        targetBuilder: AppTour.tabTarget(0, 4),
      ), TourStep(
        icon: Icons.assignment_outlined,
        title: 'Tasks Tab',
        description:
            'All collection tasks assigned to you. Open one, go to the location and complete it with proof.',
        targetBuilder: AppTour.tabTarget(1, 4),
      ), TourStep(
        icon: Icons.map_outlined,
        title: 'Live Map Tab',
        description:
            'Share your live location with the Head and optimize your route for nearby stops.',
        targetBuilder: AppTour.tabTarget(2, 4),
      ), TourStep(
        icon: Icons.person_outline,
        title: 'Profile Tab',
        description:
            'Your worker ID, vehicle details, notifications and the user manual.',
        targetBuilder: AppTour.tabTarget(3, 4),
      )],
      if (tiles.length == 4) ...[TourStep(
        icon: Icons.assignment_outlined,
        title: 'Assigned Tasks',
        description: 'Tasks assigned to you by the Head and still pending.',
        targetBuilder: AppTour.statTarget(0),
      ), TourStep(
        icon: Icons.local_shipping_rounded,
        title: 'In Progress',
        description: 'Tasks you have started (en route or collecting).',
        targetBuilder: AppTour.statTarget(1),
      ), TourStep(
        icon: Icons.check_circle_outline,
        title: 'Completed',
        description: 'Tasks you finished and submitted proof for.',
        targetBuilder: AppTour.statTarget(2),
      ), TourStep(
        icon: Icons.photo_camera_outlined,
        title: 'Proofs Submitted',
        description: 'Proof photos you uploaded for the Head to review.',
        targetBuilder: AppTour.statTarget(3),
      )],
      const TourStep(
        icon: Icons.celebration_outlined,
        title: 'You\'re all set! 🎉',
        description:
            'Complete your tasks, share your location and keep the city clean. Good luck!',
      ),
    ];
  }

  @override
  void dispose() {
    NotificationService.instance.workerTabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final index = NotificationService.instance.workerTabRequest.value;
    if (index == null) return;
    NotificationService.instance.workerTabRequest.value = null;
    _onDestinationSelected(index);
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    // IndexedStack keeps pages alive, so the Tasks list would otherwise stay
    // stale forever (e.g. a task the Head assigned while the app is open).
    if (index == 1) {
      _tasksKey.currentState?.reload();
    }
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
              WorkerDashboardPage(),
              WorkerTasksPage(key: _tasksKey),
              WorkerLiveMapPage(),
              WorkerProfilePage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            key: TourKeys.navBarKey,
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.cardColor,
        indicatorColor: AppColors.paleGreen,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: AppStrings.of(context).navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: AppStrings.of(context).navTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: AppStrings.of(context).navLiveMap,
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
