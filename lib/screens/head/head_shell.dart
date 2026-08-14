import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
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

  final _pages = const [
    HeadDashboardPage(),
    HeadWorkersPage(),
    HeadTasksPage(),
    HeadProofsPage(),
    HeadProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.cardColor,
        indicatorColor: AppColors.paleGreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Workers',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Proofs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
