import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/home/views/home_screen.dart';
import 'package:expense_tracker/features/budgets/views/budgets_screen.dart';
import 'package:expense_tracker/features/settings/views/settings_screen.dart';
import 'package:expense_tracker/features/analytics/views/analytics_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // List of screens for the bottom nav
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const SizedBox(), // Placeholder for the center Add button
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Center Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: Theme.of(context).primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Prevent tapping the center placeholder
          if (index != 2) {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.add, color: Colors.transparent), label: ''), // Invisible center item
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}