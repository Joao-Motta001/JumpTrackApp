import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_screen.dart';
import '../hydration/hydration_screen.dart';
import '../jump/jump_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../profile/profile_screen.dart';
import '../routine/routine_screen.dart';
import '../workout/workout_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 0;

  static const _items = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Nutrition', icon: Icons.restaurant_menu_rounded),
    _NavItem(label: 'Hydration', icon: Icons.water_drop_rounded),
    _NavItem(label: 'Workout', icon: Icons.fitness_center_rounded),
    _NavItem(label: 'Jump', icon: Icons.trending_up_rounded),
    _NavItem(label: 'Routine', icon: Icons.checklist_rounded),
    _NavItem(label: 'Calendar', icon: Icons.calendar_month_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  final _pages = const [
    HomeScreen(),
    NutritionScreen(),
    HydrationScreen(),
    WorkoutScreen(),
    JumpScreen(),
    RoutineScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: AppTheme.glowCard(),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == _index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _index = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withOpacity(0.16) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? AppTheme.primary : AppTheme.subtleText,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? AppTheme.text : AppTheme.subtleText,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
