import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'clients/clients_screen.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'timer/timer_screen.dart';
import 'invoices/invoices_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToTimer: () => _navigateTo(2), onNavigateToTasks: () => _navigateTo(1)),
    const TasksScreen(),
    const TimerScreen(),
    const InvoicesScreen(),
    const ClientsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: _TimerDestIcon(isSelected: _currentIndex == 2),
            selectedIcon: _TimerDestIcon(isSelected: true),
            label: 'Timer',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Invoices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clients',
          ),
        ],
      ),
    );
  }
}

class _TimerDestIcon extends StatelessWidget {
  final bool isSelected;
  const _TimerDestIcon({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : AppTheme.onSurfaceMutedDark;
    return Icon(
      isSelected ? Icons.timer_rounded : Icons.timer_outlined,
      color: color,
    );
  }
}
