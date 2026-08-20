import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tour.dart';
import '../widgets/complete_profile_dialog.dart';
import 'complaints/my_complaints_page.dart';
import 'home/home_page.dart';
import 'map/map_dashboard_page.dart';
import 'profile/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // First screen after signing in as a citizen: if the profile isn't
    // complete (phone + app login password), show the 'Complete Your Profile'
    // dialog. Runs on every mount (fresh start or logout → login), and the
    // dialog reappears on the next launch until the profile is completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Complete-profile dialog first, then the first-login tour so the two
      // never overlap.
      _maybeShowCompleteProfile().then((_) => _maybeShowTour());
    });
  }

  Future<void> _maybeShowTour() async {
    final user = AuthService.instance.user;
    if (user == null || !user.isCitizen || !mounted) return;
    if (await TourService.instance.hasSeen(user.id)) return;
    if (!mounted) return;
    await AppTour.start(context, steps: _citizenTourSteps());
    if (mounted) await TourService.instance.markSeen(user.id);
  }

  List<TourStep> _citizenTourSteps() {
    final tabs = AppTour.navTabRects(count: 4);
    final tiles = AppTour.statTileRects();
    return [
      const TourStep(
        icon: Icons.eco_outlined,
        title: 'Welcome to Safai Setu 👋',
        description:
            'A quick 2-minute tour of the Citizen app — let\'s go! You can skip anytime.',
      ),
      if (tabs.length == 4) ...[TourStep(
        icon: Icons.home_outlined,
        title: 'Home — Your Dashboard',
        description:
            'Report waste, track your complaints and see nearby hotspots right from here.',
        targetBuilder: AppTour.tabTarget(0, 4),
      ), TourStep(
        icon: Icons.assignment_outlined,
        title: 'Complaints Tab',
        description:
            'All complaints you have filed, with their live status at a glance.',
        targetBuilder: AppTour.tabTarget(1, 4),
      ), TourStep(
        icon: Icons.map_outlined,
        title: 'Map Tab',
        description:
            'See all complaints on the map, track collection vehicles and explore waste hotspots.',
        targetBuilder: AppTour.tabTarget(2, 4),
      ), TourStep(
        icon: Icons.person_outline,
        title: 'Profile Tab',
        description:
            'Edit your details, check notifications, read the user manual and more.',
        targetBuilder: AppTour.tabTarget(3, 4),
      )],
      if (tiles.length == 4) ...[TourStep(
        icon: Icons.report_outlined,
        title: 'My Complaints',
        description: 'Total number of complaints you have reported.',
        targetBuilder: AppTour.statTarget(0),
      ), TourStep(
        icon: Icons.check_circle_outline,
        title: 'Resolved',
        description: 'Complaints that have been resolved successfully.',
        targetBuilder: AppTour.statTarget(1),
      ), TourStep(
        icon: Icons.hourglass_top_rounded,
        title: 'In Progress',
        description: 'Complaints currently being worked on by our team.',
        targetBuilder: AppTour.statTarget(2),
      ), TourStep(
        icon: Icons.near_me_outlined,
        title: 'Nearby Issues',
        description:
            'Garbage hotspots near you — tap to see them on the map.',
        targetBuilder: AppTour.statTarget(3),
      )],
      const TourStep(
        icon: Icons.celebration_outlined,
        title: 'You\'re all set! 🎉',
        description:
            'Explore Safai Setu and keep your city clean. Report any waste issue today!',
      ),
    ];
  }

  Future<void> _maybeShowCompleteProfile() async {
    final user = AuthService.instance.user;
    if (user == null || !user.isCitizen || !mounted) return;

    bool complete;
    try {
      complete = await ProfileService.instance.hasCompletedProfile(user.id);
    } catch (_) {
      return; // Offline / table missing — don't block the dashboard.
    }
    if (!mounted || complete) return;

    final saved = await showCompleteProfileDialog(
      context,
      initialPhone: user.phone,
    );
    if (saved) {
      await AuthService.instance.refreshCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild all tabs when the theme changes so every AppColors.* color
    // (cards, text, icons) switches instantly without a page refresh.
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, _, __) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(),
              MyComplaintsPage(),
              MapDashboardPage(),
              ProfilePage(),
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
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: AppStrings.of(context).navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: const Icon(Icons.assignment),
                label: AppStrings.of(context).navComplaints,
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: AppStrings.of(context).navMap,
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
