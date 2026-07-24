import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewer/home_page.dart';
import 'package:mockathon/interviewee/notification_screen.dart';
import 'package:mockathon/services/auth_service.dart';
import 'package:mockathon/authentication/login_page.dart';
import 'package:mockathon/core/app_config.dart';

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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.warmBackgroundGradient,
        ),
        child: LayoutBuilder(
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
      ),
    );
  }
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.bentoDecoration(
        color: const Color(0xFFEFEBE4),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Image.asset('assets/Mockuplogo.png', height: 45),
              const SizedBox(width: 10),
              Text(
                AppConfigScope.of(context)?.appName.toUpperCase() ?? 'MOCKATHON',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, letterSpacing: 1.5)
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search here',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 24),
          // Main Nav Grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _buildSidebarItem(0, Icons.dashboard, "Students"),
                      _buildSidebarItem(1, Icons.notifications, "Alerts"),
                      _buildSidebarItem(-1, Icons.logout, "Logout"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Profile Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF232323), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.amber, radius: 18),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Interviewer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('User', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (index == -1) {
          _confirmLogout(context);
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF232323) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNav() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: AppTheme.bentoDecoration(
        color: AppTheme.cardLight,
        radius: 16,
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
