import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewer/NavbarHome/aptitude_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/gd_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/hr_mark_page.dart';

class NavbarHome extends StatefulWidget {
  final String studentId;
  final String studentName;

  const NavbarHome({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<NavbarHome> createState() => _NavbarHomeState();
}

class _NavbarHomeState extends State<NavbarHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AptitudeMarkPage(studentId: widget.studentId),
      GdMarkPage(studentId: widget.studentId),
      HrMarkPage(studentId: widget.studentId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bentoBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeDoc = constraints.maxWidth > 900;

          if (isLargeDoc) {
            return Row(
              children: [
                // Desktop Sidebar Panel
                _buildSidebar(context),
                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(isLargeDoc),
                      Expanded(child: pages[_currentIndex]),
                    ],
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return Column(
            children: [
              _buildHeader(isLargeDoc),
              Expanded(child: pages[_currentIndex]),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 900
          ? null
          : _buildMobileNavbar(),
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
          const SizedBox(height: 40),
          const Icon(Icons.assessment_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 24),
          const Text(
            "MARKING TOOL",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, Icons.psychology, "Aptitude"),
          _buildSidebarItem(1, Icons.groups, "Group Disc."),
          _buildSidebarItem(2, Icons.person_search, "Technical / HR"),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Confidential",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavbar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.bentoDecoration(
        color: Colors.white,
        radius: 40,
        shadow: true,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.bentoJacket,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Aptitude',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'GD'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search),
              label: 'Tech/HR',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLarge) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: isLarge ? 0 : 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 40),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Assessment Mode",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.studentName,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
