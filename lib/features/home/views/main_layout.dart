import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/home/views/home_screen.dart';
import 'package:expense_tracker/features/budgets/views/budgets_screen.dart';
import 'package:expense_tracker/features/settings/views/settings_screen.dart';
import 'package:expense_tracker/features/analytics/views/analytics_screen.dart';
import 'package:expense_tracker/core/widgets/offline_banner.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final activeColor = primaryColor;
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final barBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      // Prevent SnackBar from pushing the bottom bar up
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),

      // ─── Center FAB with fixed position ────────────────
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () => context.push('/add-transaction'),
          backgroundColor: primaryColor,
          shape: const CircleBorder(),
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ─── Bottom bar with notch curve ───────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: barBg,
        elevation: 12,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Left side (Home + Analytics) ──
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_filled,
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavBarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      isActive: _currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              ),

              // ── Center gap for FAB ──
              const SizedBox(width: 60),

              // ── Right side (Budget + Settings) ──
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.pie_chart_outline,
                      label: 'Budget',
                      isActive: _currentIndex == 2,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                    _NavBarItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      isActive: _currentIndex == 3,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single nav bar item with icon + label.
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}