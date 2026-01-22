import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewee/notification_screen.dart';
import 'package:mockathon/interviewee/student_dashboard.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StudentDashboard(),
    const NotificationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: Stack(
        children: [
          // Main Content
          _pages[_selectedIndex],

          // Floating Nav Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: AppTheme.bentoDecoration(
                color: AppTheme.cardLight,
                radius: 40,
                shadow: true,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Hug content
                children: [
                  _buildNavItem(
                    0,
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    "Home",
                  ),
                  const SizedBox(width: 16),
                  _buildNavItem(
                    1,
                    Icons.notifications_none_outlined,
                    Icons.notifications,
                    "Alerts",
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Image.asset('assets/softlogo.png', height: 60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.bentoJacket,
                borderRadius: BorderRadius.circular(30),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
