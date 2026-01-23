import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewer/home_page.dart';
import 'package:mockathon/interviewee/notification_screen.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/authentication/login_page.dart';

class InterviewerNavScreen extends StatefulWidget {
  const InterviewerNavScreen({super.key});

  @override
  State<InterviewerNavScreen> createState() => _InterviewerNavScreenState();
}

class _InterviewerNavScreenState extends State<InterviewerNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NotificationScreen(userRole: 'interviewer'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLarge = MediaQuery.of(context).size.width > 800;

          if (isLarge) {
            return Row(
              children: [
                _buildSidebar(context),
                Expanded(child: _pages[_selectedIndex]),
              ],
            );
          }

          // Mobile Layout
          return Stack(
            children: [
              _pages[_selectedIndex],
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildMobileNav(),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: Image.asset('assets/softlogowhite.png', height: 120),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.bentoJacket,
        radius: 32,
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.psychology, color: Colors.white, size: 48),
          const SizedBox(height: 24),
          const Text(
            "INTERVIEWER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, Icons.dashboard, "Students"),
          _buildSidebarItem(1, Icons.notifications, "Alerts"),
          const Spacer(),
          _buildSidebarItem(-1, Icons.logout, "Logout"),

          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Image.asset('assets/softlogowhite.png', height: 120),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (index == -1) {
            _confirmLogout(context);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 40,
        shadow: true,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "Home"),
          const SizedBox(width: 16),
          _buildNavItem(
            1,
            Icons.notifications_none_outlined,
            Icons.notifications,
            "Alerts",
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = AuthService();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(userType: "Interviewer"),
        ),
        (route) => false,
      );
    }
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
