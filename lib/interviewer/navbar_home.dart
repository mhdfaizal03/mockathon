import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/interviewer/NavbarHome/aptitude_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/gd_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/hr_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/technical_mark_page.dart';
import 'package:mockathon/interviewer/NavbarHome/machine_test_mark_page.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:mockathon/models/user_models.dart';
import 'package:mockathon/services/resume_service.dart';

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
      TechnicalMarkPage(studentId: widget.studentId),
      MachineTestMarkPage(studentId: widget.studentId),
      HrMarkPage(studentId: widget.studentId),
      AptitudeMarkPage(studentId: widget.studentId),
      GdMarkPage(studentId: widget.studentId),
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
          const SizedBox(height: 24),
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
          _buildSidebarItem(0, Icons.code, "Technical Round"),
          _buildSidebarItem(1, Icons.computer, "Machine Test"),
          _buildSidebarItem(2, Icons.person_search, "HR Round"),
          _buildSidebarItem(3, Icons.psychology, "Aptitude"),
          _buildSidebarItem(4, Icons.groups, "Group Disc."),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      margin: const EdgeInsets.all(12),
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
            BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Tech'),
            BottomNavigationBarItem(
              icon: Icon(Icons.computer),
              label: 'Machine',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search),
              label: 'HR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Aptitude',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'GD'),
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
          StreamBuilder<StudentModel>(
            stream: DataService().getStudent(widget.studentId),
            builder: (context, snapshot) {
              final student = snapshot.data;
              final hasCv = student?.cvUrl != null;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!hasCv) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Candidate hasn't uploaded a resume yet",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    ResumeService().downloadResume(student!.cvUrl!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasCv
                        ? AppTheme.bentoJacket
                        : Colors.grey.withOpacity(0.2),
                    foregroundColor: hasCv ? Colors.white : Colors.grey,
                    elevation: hasCv ? 2 : 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: hasCv ? Colors.white : Colors.grey,
                  ),
                  label: const Text("Resume"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
